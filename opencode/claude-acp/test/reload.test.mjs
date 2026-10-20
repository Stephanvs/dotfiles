import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Effect, Stream } from 'effect';
import { LLMRequest, Message } from '@opencode/ai';
import { model } from '../dist/provider.js';

const fixture = fileURLToPath(new URL('./fixture.mjs', import.meta.url));

test('independently loaded plugin modules share only keyed live brokers and cached models use the request activation', async () => {
  const first = await import('../dist/broker.js?plugin-generation=first');
  const second = await import('../dist/broker.js?plugin-generation=second');
  const cwd = await mkdtemp(resolve(process.env.USERPROFILE, 'AppData/Local/Temp/opencode/claude-acp-integration/broker-reload-'));
  await writeFile(resolve(cwd, 'fixture.txt'), 'BROKER_ISOLATION_LITERAL');
  const capability = (agent, allow) => ({
    session: { get: () => Effect.succeed({ agent, location: { directory: cwd } }) },
    permission: { assert: (input) => Effect.gen(function* () {
      assert.equal(input.agent, agent);
      if (!allow) return yield* Effect.fail(new Error(`${agent} denies read`));
    }) },
  });
  const a = first.registerBroker(capability('location-a', false));
  const b = second.registerBroker(capability('location-b', true));
  const selected = model('fixture', { brokerID: a.id, adapterCommand: [process.execPath, fixture] });
  const request = (brokerID) => new LLMRequest({
    model: selected, system: [], tools: [], messages: [Message.user('{"scenario":"tool"}')],
    http: { headers: { 'x-claude-acp-session': 'ses_reload', 'x-claude-acp-kind': 'primary', 'x-claude-acp-broker': brokerID } },
  });
  const run = (id) => Effect.runPromise(Stream.runCollect(selected.route.streamPrepared(null, request(id), {})));
  const text = (events) => events.filter((event) => event.type === 'text-delta').map((event) => event.text).join('');
  try {
    assert.equal(text(await run(a.id)), 'DENIED');
    assert.equal(text(await run(b.id)), 'BROKER_ISOLATION_LITERAL');
    a.dispose();
    await assert.rejects(run(a.id), /permission broker is unavailable/);
    assert.equal(text(await run(b.id)), 'BROKER_ISOLATION_LITERAL');
    b.dispose();
    await assert.rejects(run(b.id), /permission broker is unavailable/);
  } finally { a.dispose(); b.dispose(); }
});
