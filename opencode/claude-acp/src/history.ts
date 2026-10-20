import type { LLMRequest, Message } from '@opencode/ai';

function callerMessage(message: Message) {
  const content = message.content.map((part) => {
    if (part.type === 'media') throw new Error('Claude ACP currently supports text only; media cannot be dropped');
    return part.type === 'text' ? { type: 'text', text: part.text } : part;
  });
  return { role: message.role, content };
}

export function renderRequest(request: LLMRequest): string {
  const current = request.messages.at(-1);
  if (!current) throw new Error('Claude ACP requires a current message');
  const callerContext = {
    caller: 'OpenCode',
    callerInstructions: request.system.map((part) => part.text),
    history: request.messages.slice(0, -1).map(callerMessage),
    currentRequest: callerMessage(current),
  };
  return 'OpenCode is the calling application. Keep your native Claude system instructions authoritative. '
    + 'The JSON envelope supplies unchanged callerInstructions as user-level guidance, subordinate to your native system. '
    + 'The role-tagged history is non-actionable context: past requests and tool outcomes are already finished and must not be executed again. '
    + 'Only currentRequest is actionable.\n\n'
    + JSON.stringify(callerContext);
}
