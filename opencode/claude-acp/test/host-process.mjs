import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Effect, Stream } from 'effect';
import { LLMRequest, Message } from '@opencode/ai';
import { model } from '../dist/provider.js';
import { registerBroker } from '../dist/broker.js';

const cwd = process.argv[2];
const broker = registerBroker({
  session: { get: () => Effect.succeed({ agent: 'build', location: { directory: cwd } }) },
  permission: { assert: () => Effect.void },
});
const selected = model('fixture', { brokerID: broker.id, adapterCommand: [process.execPath, fileURLToPath(new URL('./fixture.mjs', import.meta.url))] });
const request = new LLMRequest({
  model: selected, system: [], tools: [],
  messages: [Message.user(JSON.stringify({ scenario: 'parent-crash', sentinel: resolve(cwd, 'orphan-sentinel.txt') }))],
  http: { headers: { 'x-claude-acp-session': 'ses_parent_crash', 'x-claude-acp-kind': 'primary' } },
});
await Effect.runPromise(Stream.runDrain(selected.route.streamPrepared(null, request, {}).pipe(Stream.tap((event) => Effect.sync(() => {
  if (event.type === 'text-delta' && event.text === 'PARENT_CRASH_READY') process.send({ ready: true, hostPID: process.pid });
})))));
