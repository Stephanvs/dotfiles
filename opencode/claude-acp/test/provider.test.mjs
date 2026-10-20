import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Effect, Stream } from 'effect';
import { LLMRequest, Media, Message } from '@opencode/ai';
import { model } from '../dist/provider.js';
import { registerBroker } from '../dist/broker.js';
import { ACPProcess } from '../dist/acp.js';

const fixture = fileURLToPath(new URL('./fixture.mjs', import.meta.url));
const scratchRoot = resolve(process.env.USERPROFILE, 'AppData/Local/Temp/opencode/claude-acp-integration');

async function harness(decide = async () => {}, permission = {}) {
  const directories = new Map();
  for (const id of ['session-a', 'session-b']) {
    const cwd = await mkdtemp(resolve(scratchRoot, 'test-'));
    await writeFile(resolve(cwd, 'fixture.txt'), 'first = 73\nsecond = 29\n');
    directories.set(id, cwd);
  }
  const broker = registerBroker({
    session: { get: ({ sessionID }) => Effect.succeed({ location: { directory: directories.get(sessionID) }, agent: `${sessionID}-agent` }) },
    permission: { assert: (input) => Effect.tryPromise(() => decide(input)), ...permission },
  });
  const selected = model('fixture', { brokerID: broker.id, adapterCommand: [process.execPath, fixture] });
  function request(spec, id = 'session-a', history = [], kind = 'primary') {
    return new LLMRequest({ model: selected, system: [{ type: 'text', text: 'SYSTEM_NONCE' }], messages: [...history, Message.user(JSON.stringify(spec))], tools: [], http: { headers: { 'x-claude-acp-session': id, 'x-claude-acp-kind': kind } } });
  }
  const stream = (request) => selected.route.streamPrepared(null, request, {});
  const collect = (request) => Effect.runPromise(Stream.runCollect(stream(request)));
  return { broker, directories, request, stream, collect };
}

const text = (events) => events.filter((event) => event.type === 'text-delta').map((event) => event.text).join('');
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };

test('V2 shell deny rejects Bash before asking for broader directory access', async () => {
  const decisions = [];
  const h = await harness(async ({ action }) => {
    decisions.push(action);
    if (action === 'shell') throw new Error('Plan denies shell');
  });
  try {
    const events = await h.collect(h.request({ scenario: 'tool', tool: 'Bash', input: { command: 'echo harmless' } }));
    assert.equal(text(events), 'DENIED');
    assert.ok(!decisions.includes('external_directory'));
  } finally { h.broker.dispose(); }
});

test('unchanged caller instructions, role-tagged history, and current task are delegated once as user context', async () => {
  const h = await harness();
  try {
    const instructions = ['You are an AI agent running in OpenCode.\r\nKeep every byte: λ /literal', 'Second instruction\nwith trailing whitespace.  '];
    const request = LLMRequest.update(h.request({ scenario: 'history' }, 'session-a', [Message.user('PAST_NONCE'), Message.assistant('PAST_ANSWER'), Message.tool({ type: 'tool-result', id: 'past', name: 'Read', result: { type: 'text', value: 'PAST_OUTCOME' }, providerExecuted: true })]), { system: instructions.map((text) => ({ type: 'text', text })) });
    const events = await h.collect(request);
    const output = JSON.parse(text(events));
    assert.equal(output.context.caller, 'OpenCode');
    assert.deepEqual(output.context.callerInstructions, instructions);
    assert.deepEqual(output.context.history.map((message) => message.role), ['user', 'assistant', 'tool']);
    assert.equal(output.context.history[2].content[0].result.value, 'PAST_OUTCOME');
    assert.equal(output.prompt.split('PAST_NONCE').length - 1, 1);
    assert.match(output.prompt, /history is non-actionable/);
    assert.match(output.prompt, /Only currentRequest is actionable/);
    assert.deepEqual(output.context.currentRequest, { role: 'user', content: [{ type: 'text', text: '{"scenario":"history"}' }] });
    assert.equal(output.prompt.split('{\\"scenario\\":\\"history\\"}').length - 1, 1);
    assert.ok(!output.prompt.startsWith('/'));
    const slashRequest = LLMRequest.update(request, { messages: [Message.user('/clear preserve this caller text')] });
    const slash = JSON.parse(text(await h.collect(slashRequest)));
    assert.equal(slash.context.currentRequest.content[0].text, '/clear preserve this caller text');
    assert.ok(!slash.prompt.startsWith('/'));
    assert.equal(events.at(-1).type, 'finish');
    const lifecycle = (await readFile(resolve(h.directories.get('session-a'), 'lifecycle.jsonl'), 'utf8')).trim().split('\n').map(JSON.parse);
    assert.equal(alive(lifecycle.find((entry) => entry.event === 'start').pid), false);
  } finally { h.broker.dispose(); }
});

test('media in either caller history or the current task is rejected rather than dropped', async () => {
  const h = await harness();
  try {
    const image = Message.make({ role: 'user', content: [{ type: 'media', media: new Media.Asset({ source: { type: 'base64', data: 'AA==', mediaType: 'image/png' } }) }] });
    for (const messages of [[image], [image, Message.user('{"scenario":"history"}')]]) {
      const request = LLMRequest.update(h.request({ scenario: 'history' }), { messages });
      await assert.rejects(h.collect(request), /text only; media cannot be dropped/);
    }
  } finally { h.broker.dispose(); }
});

test('overlapping sessions have isolated permission decisions, merged hosted results and scoped IDs', async () => {
  const h = await harness(async ({ sessionID, agent, action, resources, metadata }) => {
    assert.equal(agent, `${sessionID}-agent`);
    assert.equal(action, 'read');
    assert.equal(resources[0], resolve(h.directories.get(sessionID), 'fixture.txt'));
    assert.equal(metadata.input.file_path, resources[0]);
    if (sessionID === 'session-a') throw new Error('policy denial');
  });
  try {
    const [denied, allowed] = await Promise.all([h.collect(h.request({ scenario: 'tool' }, 'session-a')), h.collect(h.request({ scenario: 'tool' }, 'session-b'))]);
    assert.equal(text(denied), 'DENIED');
    assert.equal(text(allowed), 'first = 73\nsecond = 29\n');
    const result = allowed.find((event) => event.type === 'tool-result');
    assert.equal(result.result.value, 'first = 73\nsecond = 29\n');
    assert.equal(result.providerExecuted, true);
    const call = allowed.find((event) => event.type === 'tool-call');
    assert.equal(call.providerExecuted, true);
    assert.equal(call.input.file_path, resolve(h.directories.get('session-b'), 'fixture.txt'));
    assert.notEqual(call.id, denied.find((event) => event.type === 'tool-call').id);
  } finally { h.broker.dispose(); }
});

test('denied writes preserve bytes, allowed writes use structured inputs, auxiliary and unknown tools fail closed', async () => {
  let allow = false;
  const h = await harness(async ({ action }) => { assert.equal(action, 'edit'); if (!allow) throw new Error('deny'); });
  const file = resolve(h.directories.get('session-a'), 'fixture.txt');
  try {
    const spec = { scenario: 'tool', tool: 'Write', input: { file_path: file, content: 'EXACT_BYTES' } };
    assert.equal(text(await h.collect(h.request(spec))), 'DENIED');
    assert.equal(await readFile(file, 'utf8'), 'first = 73\nsecond = 29\n');
    allow = true;
    const events = await h.collect(h.request(spec));
    assert.equal(await readFile(file, 'utf8'), 'EXACT_BYTES');
    assert.equal(events.find((event) => event.type === 'tool-call').input.content, 'EXACT_BYTES');
    assert.equal(text(await h.collect(h.request(spec, 'session-a', [], 'title'))), 'DENIED');
    assert.equal(text(await h.collect(h.request({ scenario: 'tool', tool: 'Agent', input: { prompt: 'delegate' } }))), 'DENIED');
  } finally { h.broker.dispose(); }
});

test('a hosted write waits for native call processing before its side effect', async () => {
  const h = await harness();
  const file = resolve(h.directories.get('session-a'), 'fixture.txt');
  try {
    const stream = h.stream(h.request({ scenario: 'tool', tool: 'Write', input: { file_path: file, content: 'AFTER_SNAPSHOT' } })).pipe(Stream.tap((event) => Effect.promise(async () => {
      if (event.type !== 'tool-call') return;
      await new Promise((resolve) => setTimeout(resolve, 100));
      assert.equal(await readFile(file, 'utf8'), 'first = 73\nsecond = 29\n');
    })));
    await Effect.runPromise(Stream.runDrain(stream));
    assert.equal(await readFile(file, 'utf8'), 'AFTER_SNAPSHOT');
  } finally { h.broker.dispose(); }
});

test('external paths require external_directory policy before read', async () => {
  const h = await harness(async ({ action }) => { if (action === 'external_directory') throw new Error('outside cwd'); });
  try {
    const events = await h.collect(h.request({ scenario: 'tool', input: { file_path: resolve(h.directories.get('session-b'), 'fixture.txt') } }));
    assert.equal(text(events), 'DENIED');
  } finally { h.broker.dispose(); }
});

test('unscoped requests and background shell input cannot execute a hosted tool', async () => {
  const h = await harness();
  try {
    const request = h.request({ scenario: 'tool' });
    const unscoped = LLMRequest.update(request, { http: { headers: {} } });
    await assert.rejects(h.collect(unscoped), /No OpenCode session identity/);
    for (const input of [{ command: 'echo hello', run_in_background: true }, { command: 'echo hello & sleep 30' }]) {
      assert.equal(text(await h.collect(h.request({ scenario: 'tool', tool: 'Bash', input }))), 'DENIED');
    }
    assert.equal(text(await h.collect(h.request({ scenario: 'tool', tool: 'Agent', input: { prompt: 'delegate' } }))), 'DENIED');
  } finally { h.broker.dispose(); }
});

test('pending hosted input is visible before execution; cancellation removes delayed Effect permission admission and preserves foreign asks', async () => {
  const pending = new Set(['foreign']);
  let ready;
  const asked = new Promise((resolve) => { ready = resolve; });
  const h = await harness(undefined, {
    assert: () => Effect.scoped(Effect.gen(function* () {
      yield* Effect.acquireRelease(Effect.promise(async () => {
        ready();
        await new Promise((resolve) => setTimeout(resolve, 300));
        pending.add('owned');
      }), () => Effect.sync(() => pending.delete('owned')));
      yield* Effect.never;
    })),
  });
  const controller = new AbortController();
  const observed = [];
  try {
    const file = resolve(h.directories.get('session-a'), 'fixture.txt');
    const spec = { scenario: 'tool', tool: 'Write', input: { file_path: file, content: 'AFTER_PERMISSION' } };
    const running = Effect.runPromise(Stream.runCollect(h.stream(h.request(spec)).pipe(Stream.tap((event) => Effect.sync(() => observed.push(event))))), { signal: controller.signal });
    await asked;
    await new Promise((resolve) => setTimeout(resolve, 25));
    assert.ok(observed.some((event) => event.type === 'tool-input-start' && event.providerExecuted));
    const call = observed.find((event) => event.type === 'tool-call');
    assert.deepEqual(call.input, spec.input);
    assert.equal(call.providerExecuted, true);
    assert.equal(await readFile(file, 'utf8'), 'first = 73\nsecond = 29\n');
    controller.abort();
    await assert.rejects(running);
    assert.deepEqual([...pending], ['foreign']);
    assert.ok(observed.some((event) => event.type === 'tool-call'));
    assert.ok(!observed.some((event) => event.type === 'finish'));
  } finally { controller.abort(); h.broker.dispose(); }
});

test('cancellation while resolving the OpenCode session interrupts its Effect before ACP starts', async () => {
  let ready;
  let released = false;
  const lookupStarted = new Promise((resolve) => { ready = resolve; });
  const broker = registerBroker({
    session: { get: () => Effect.scoped(Effect.gen(function* () {
      yield* Effect.acquireRelease(Effect.sync(ready), () => Effect.sync(() => { released = true; }));
      return yield* Effect.never;
    })) },
    permission: { assert: () => Effect.void },
  });
  const selected = model('fixture', { brokerID: broker.id, adapterCommand: [process.execPath, fixture] });
  const request = new LLMRequest({ model: selected, system: [], messages: [Message.user('never dispatched')], tools: [], http: { headers: { 'x-claude-acp-session': 'ses_lookup', 'x-claude-acp-kind': 'primary' } } });
  const controller = new AbortController();
  try {
    const running = Effect.runPromise(Stream.runDrain(selected.route.streamPrepared(null, request, {})), { signal: controller.signal });
    await lookupStarted;
    controller.abort();
    await assert.rejects(running);
    assert.equal(released, true);
  } finally { controller.abort(); broker.dispose(); }
});

test('unknown and missing stop reasons cannot become a successful finish', async () => {
  const h = await harness();
  try {
    for (const stopReason of [undefined, 'garbage']) await assert.rejects(h.collect(h.request({ scenario: 'stop', stopReason })), /stopReason|Invalid params|Invalid.*response/i);
  } finally { h.broker.dispose(); }
});

test('unbrokered successful tools fail closed; pre-execution failures retain their exact raw error', async () => {
  const h = await harness();
  try {
    await assert.rejects(h.collect(h.request({ scenario: 'no-permission', status: 'completed', output: 'unexpected execution' })), /without a brokered permission/);
    for (const output of ['exact raw failure\nsecond line', null]) {
      const events = await h.collect(h.request({ scenario: 'no-permission', status: 'failed', output }));
      const result = events.find((event) => event.type === 'tool-result');
      assert.equal(result.result.type, 'error');
      assert.equal(result.result.value, output);
      assert.equal(result.providerExecuted, true);
    }
  } finally { h.broker.dispose(); }
});

test('subscription child strips API credentials and routing while preserving its OS environment and strict MCP policy', async () => {
  const keys = ['ANTHROPIC_API_KEY', 'ANTHROPIC_AUTH_TOKEN', 'ANTHROPIC_BASE_URL', 'CLAUDE_CODE_OAUTH_TOKEN', 'CLAUDE_CODE_EXECUTABLE'];
  const previous = keys.map((key) => process.env[key]);
  const previousPath = process.env.PATH;
  for (const key of keys) process.env[key] = 'TEST_SENTINEL';
  const h = await harness();
  try {
    process.env.PATH = h.directories.get('session-a');
    assert.throws(() => new ACPProcess(h.directories.get('session-a'), { update() {}, permission() {} }), /installed claude.exe executable on PATH/);
    const result = JSON.parse(text(await h.collect(h.request({ scenario: 'environment' }))));
    assert.equal(result.apiKey, false);
    assert.equal(result.authToken, false);
    assert.equal(result.baseURL, false);
    assert.equal(result.oauthToken, false);
    assert.equal(result.executableOverride, false);
    assert.equal(result.userprofile, true);
    assert.equal(result.path, true);
    assert.equal(result.options.strictMcpConfig, true);
    assert.deepEqual(result.options.settingSources, []);
    assert.equal(result.options.settings.fastMode, false);
  } finally {
    h.broker.dispose();
    if (previousPath === undefined) delete process.env.PATH; else process.env.PATH = previousPath;
    keys.forEach((key, index) => { if (previous[index] === undefined) delete process.env[key]; else process.env[key] = previous[index]; });
  }
});

test('adapter exit closes its Job Object even when a descendant outlives the adapter', async () => {
  const h = await harness();
  try {
    await assert.rejects(h.collect(h.request({ scenario: 'orphan-exit' })), /Claude ACP failed/);
    const entries = (await readFile(resolve(h.directories.get('session-a'), 'lifecycle.jsonl'), 'utf8')).trim().split('\n').map(JSON.parse);
    const descendant = entries.find((entry) => entry.event === 'descendant');
    assert.ok(descendant?.pid);
    assert.equal(alive(descendant.pid), false, 'descendant survived adapter parent exit');
  } finally { h.broker.dispose(); }
});

test('protocol errors and unexpected process exit fail the native stream without a finish or retry', async () => {
  const h = await harness();
  try {
    for (const scenario of ['protocol-error', 'exit']) await assert.rejects(h.collect(h.request({ scenario })), /Claude ACP failed/);
  } finally { h.broker.dispose(); }
});

test('interrupting a stream cancels and kills its process tree; the next inference works', async () => {
  const h = await harness();
  const controller = new AbortController();
  try {
    const request = h.request({ scenario: 'hang' });
    const stream = h.stream(request).pipe(Stream.tap((event) => Effect.sync(() => { if (event.type === 'text-delta') controller.abort(); })));
    await assert.rejects(Effect.runPromise(Stream.runCollect(stream), { signal: controller.signal }));
    const lifecycle = (await readFile(resolve(h.directories.get('session-a'), 'lifecycle.jsonl'), 'utf8')).trim().split('\n').map(JSON.parse);
    assert.ok(lifecycle.some((entry) => entry.event === 'cancel'));
    for (const entry of lifecycle.filter((entry) => 'pid' in entry)) assert.equal(alive(entry.pid), false, `owned process ${entry.pid} survived`);
    assert.deepEqual(JSON.parse(JSON.parse(text(await h.collect(h.request({ scenario: 'history' })))).context.currentRequest.content[0].text), { scenario: 'history' });
  } finally { h.broker.dispose(); }
});
