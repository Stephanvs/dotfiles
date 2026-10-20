import type { LLMEvent } from '@opencode/ai';
import type { SessionUpdate, ToolCall, ToolCallUpdate } from '@agentclientprotocol/sdk';

interface HostedTool {
  call: ToolCallUpdate;
  name: string;
  phase: 'input' | 'called' | 'finished';
}

export class EventMapper {
  private readonly tools = new Map<string, HostedTool>();
  private block?: { type: 'text' | 'reasoning'; id: string };
  private sequence = 0;

  constructor(private readonly prefix: string, private readonly emit: (event: LLMEvent) => void) {}

  update(update: SessionUpdate) {
    if (update.sessionUpdate === 'agent_message_chunk' || update.sessionUpdate === 'agent_thought_chunk') {
      if (update.content.type !== 'text') throw new Error(`Unsupported Claude ACP output: ${update.content.type}`);
      const type = update.sessionUpdate === 'agent_message_chunk' ? 'text' : 'reasoning';
      if (this.block?.type !== type) {
        this.endBlock();
        this.block = { type, id: `${this.prefix}:${++this.sequence}` };
        this.emit({ type: `${type}-start`, id: this.block.id });
      }
      this.emit({ type: `${type}-delta`, id: this.block.id, text: update.content.text });
    } else if (update.sessionUpdate === 'tool_call' || update.sessionUpdate === 'tool_call_update') {
      this.endBlock();
      this.toolUpdate(update);
    } else if (update.sessionUpdate === 'current_mode_update' && update.currentModeId !== 'default') {
      throw new Error('Claude ACP changed permission mode; invocation stopped');
    }
  }

  beforePermission(call: ToolCallUpdate) {
    this.endBlock();
    const tool = this.merge(call);
    if (tool.phase !== 'input') throw new Error('Claude ACP repeated permission for a published tool call');
    // The permission request is the authoritative complete input, before the
    // adapter can execute anything. Never publish a partial action snapshot.
    tool.call.rawInput = call.rawInput;
    this.publishCall(tool);
  }

  private merge(update: ToolCallUpdate): HostedTool {
    let tool = this.tools.get(update.toolCallId);
    const name = update.name ?? (update._meta?.claudeCode as { toolName?: string } | undefined)?.toolName ?? tool?.name;
    if (!name) throw new Error('Claude ACP tool announcement omitted its structured tool name');
    if (!tool) {
      tool = { call: update, name, phase: 'input' };
      this.tools.set(update.toolCallId, tool);
      this.emit({ type: 'tool-input-start', id: this.toolID(tool), name, providerExecuted: true });
    } else {
      if (tool.name !== name) throw new Error('Claude ACP changed a tool name within one call');
      const previous = tool.call.rawInput;
      tool.call = { ...tool.call, ...update };
      if (previous && typeof previous === 'object' && update.rawInput && typeof update.rawInput === 'object') tool.call.rawInput = { ...previous, ...update.rawInput };
    }
    return tool;
  }

  private publishCall(tool: HostedTool) {
    if (tool.phase !== 'input') return;
    const id = this.toolID(tool);
    this.emit({ type: 'tool-input-end', id, name: tool.name });
    this.emit({ type: 'tool-call', id, name: tool.name, input: tool.call.rawInput, providerExecuted: true });
    tool.phase = 'called';
  }

  private toolUpdate(update: ToolCall | ToolCallUpdate) {
    const tool = this.merge(update);
    const status = tool.call.status;
    if (status !== 'completed' && status !== 'failed') return;
    if (tool.phase === 'finished') return;
    if (tool.phase === 'input' && status === 'completed') throw new Error('Claude ACP completed a tool without a brokered permission request');
    this.publishCall(tool);
    const result = Object.hasOwn(tool.call, 'rawOutput') ? tool.call.rawOutput : tool.call.content;
    this.emit({ type: 'tool-result', id: this.toolID(tool), name: tool.name, result: { type: status === 'failed' ? 'error' : 'json', value: result }, providerExecuted: true });
    tool.phase = 'finished';
  }

  private toolID(tool: HostedTool) { return `${this.prefix}:${tool.call.toolCallId}`; }

  finish(stopReason: unknown) {
    this.endBlock();
    if (typeof stopReason !== 'string' || !['end_turn', 'max_tokens', 'max_turn_requests', 'refusal', 'cancelled'].includes(stopReason)) throw new Error(`Invalid Claude ACP stopReason: ${String(stopReason)}`);
    if ([...this.tools.values()].some((tool) => tool.phase !== 'finished')) throw new Error('Claude ACP ended with incomplete tool activity');
    if (stopReason === 'cancelled') throw new Error('Claude ACP prompt cancelled');
    const reason = { normalized: stopReason === 'max_tokens' || stopReason === 'max_turn_requests' ? 'length' as const : stopReason === 'refusal' ? 'content-filter' as const : 'stop' as const, raw: stopReason };
    this.emit({ type: 'finish', reason });
  }

  private endBlock() {
    if (!this.block) return;
    this.emit({ type: `${this.block.type}-end`, id: this.block.id });
    this.block = undefined;
  }
}
