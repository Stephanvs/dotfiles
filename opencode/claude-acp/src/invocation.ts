import { randomUUID } from 'node:crypto';
import { AIError, InvalidProviderOutputError } from '@opencode/ai';
import { Effect } from 'effect';
import { Session } from '@opencode/schema/session';
import type { LLMEvent, LLMRequest } from '@opencode/ai';
import { ACPProcess } from './acp.js';
import type { AdapterCommand } from './acp.js';
import { getBroker, permission } from './broker.js';
import { EventMapper } from './events.js';
import { renderRequest } from './history.js';

export const failure = (error: unknown) => error instanceof AIError ? error : new AIError({ reason: new InvalidProviderOutputError({ message: `Claude ACP failed (not retried): ${String(error)}` }) });

export class Invocation {
  private readonly id = randomUUID();
  private readonly controller = new AbortController();
  private acp?: ACPProcess;
  private readonly queue: Array<LLMEvent | (() => void)> = [];
  private wake?: () => void;
  private done = false;
  private error?: unknown;

  constructor(readonly request: LLMRequest, private readonly brokerID: string, private readonly command?: AdapterCommand) {}

  events(): AsyncIterableIterator<LLMEvent> {
    const emit = (event: LLMEvent) => { this.queue.push(event); this.wake?.(); };
    const run = this.run(emit).catch((error: unknown) => { this.error = error; }).finally(() => { this.done = true; this.wake?.(); });
    return {
      [Symbol.asyncIterator]() { return this; },
      next: async () => {
        while (!this.done || this.queue.length) {
          const event = this.queue.shift();
          if (typeof event === 'function') { event(); continue; }
          if (event) return { done: false, value: event };
          await new Promise<void>((resolve) => { this.wake = resolve; });
        }
        if (this.error) throw failure(this.error);
        return { done: true, value: undefined };
      },
      // An async generator's return() queues behind a pending next(). Closing
      // ACP must happen first, including when next() is waiting on permission.
      return: async () => {
        await this.close();
        await run;
        this.queue.length = 0;
        return { done: true, value: undefined };
      },
    };
  }

  close = async () => {
    this.controller.abort();
    await this.acp?.close();
  };

  private async run(emit: (event: LLMEvent) => void) {
    const ctx = getBroker(this.request.http?.headers?.['x-claude-acp-broker'] ?? this.brokerID);
    const sessionID = this.request.http?.headers?.['x-claude-acp-session'];
    const kind = this.request.http?.headers?.['x-claude-acp-kind'];
    const signal = this.controller.signal;
    const session = sessionID ? await Effect.runPromise(ctx.session.get({ sessionID: Session.ID.make(sessionID) }), { signal }) : undefined;
    const cwd = session?.location.directory;
    if (!cwd) throw new Error('No OpenCode session identity; Claude ACP fails closed for unscoped generation');
    const prompt = renderRequest(this.request);
    signal.throwIfAborted();
    const mapper = new EventMapper(this.id, emit);
    this.acp = new ACPProcess(cwd, {
      update: (update) => {
        if (signal.aborted) return;
        try { mapper.update(update); }
        catch (error) { this.error = error; void this.close().catch(() => {}); }
      },
      permission: async (request) => {
        if (signal.aborted) return { outcome: { outcome: 'cancelled' } };
        try {
          mapper.beforePermission(request.toolCall);
          // The next pull acknowledges processing of the preceding native call,
          // including OpenCode's pre-action snapshot, before permission can pass.
          await new Promise<void>((resolve) => {
            const release = () => { signal.removeEventListener('abort', release); resolve(); };
            this.queue.push(release);
            signal.addEventListener('abort', release, { once: true });
            this.wake?.();
          });
          return await permission(ctx, kind === 'primary' ? sessionID : undefined, cwd, this.id, request, signal);
        } catch (error) {
          this.error = error;
          void this.close().catch(() => {});
          return { outcome: { outcome: 'cancelled' } };
        }
      },
    }, this.command);
    try {
      await this.acp.open(cwd, signal);
      await this.acp.model(String(this.request.model.id), signal);
      const response = await this.acp.prompt(prompt, signal);
      if (this.error) throw this.error;
      mapper.finish(response.stopReason);
    } finally { await this.close(); }
  }
}
