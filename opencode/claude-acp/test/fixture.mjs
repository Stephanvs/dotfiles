import { AgentApp, ndJsonStream } from '@agentclientprotocol/sdk';
import { Readable, Writable } from 'node:stream';
import { appendFile, readFile, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { resolve } from 'node:path';

const app = new AgentApp();
let options;
const sessionId = `fixture-${process.pid}`;
const log = (entry) => appendFile(resolve('lifecycle.jsonl'), JSON.stringify(entry) + '\n');
await log({ event: 'start', pid: process.pid });
app.onRequest('initialize', () => ({ protocolVersion: 1, agentCapabilities: {} }));
app.onRequest('session/new', ({ params }) => {
  if (Object.hasOwn(params, 'systemPrompt')) throw new Error('Caller context must not replace or append to the native Claude system');
  options = params._meta.claudeCode.options;
  return { sessionId, configOptions: [{ id: 'model', name: 'Model', category: 'model', type: 'select', currentValue: 'fixture', options: [{ value: 'fixture', name: 'Fixture' }] }] };
});
app.onRequest('session/set_mode', () => ({}));
app.onRequest('session/set_config_option', () => ({ configOptions: [] }));
app.onNotification('session/cancel', async () => { await log({ event: 'cancel' }); });
app.onRequest('session/close', async () => { await log({ event: 'close' }); return {}; });
app.onRequest('session/prompt', async ({ params, client }) => {
  const text = params.prompt[0].text;
  const context = JSON.parse(text.slice(text.indexOf('\n\n') + 2));
  if (context.caller !== 'OpenCode') throw new Error('Missing caller identity');
  const task = context.currentRequest.content.map((part) => part.text).join('\n');
  const spec = task.startsWith('/') ? { scenario: 'history' } : JSON.parse(task);
  const update = (update) => client.notify('session/update', { sessionId, update });
  if (spec.scenario === 'exit') process.exit(7);
  if (spec.scenario === 'orphan-exit') {
    const descendant = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { stdio: 'ignore' });
    await log({ event: 'descendant', pid: descendant.pid });
    process.exit(7);
  }
  if (spec.scenario === 'stop') return { stopReason: spec.stopReason };
  if (spec.scenario === 'environment') await update({ sessionUpdate: 'agent_message_chunk', content: { type: 'text', text: JSON.stringify({ apiKey: !!process.env.ANTHROPIC_API_KEY, authToken: !!process.env.ANTHROPIC_AUTH_TOKEN, baseURL: !!process.env.ANTHROPIC_BASE_URL, oauthToken: !!process.env.CLAUDE_CODE_OAUTH_TOKEN, executableOverride: !!process.env.CLAUDE_CODE_EXECUTABLE, userprofile: !!process.env.USERPROFILE, path: !!process.env.PATH, options }) } });
  if (spec.scenario === 'no-permission') {
    await update({ sessionUpdate: 'tool_call', toolCallId: 'unbrokered', name: 'Read', title: 'Read', rawInput: { file_path: 'fixture.txt' }, status: 'pending' });
    await update({ sessionUpdate: 'tool_call_update', toolCallId: 'unbrokered', status: spec.status, rawOutput: spec.output });
  }
  if (spec.scenario === 'protocol-error') throw new Error('Fixture protocol failure');
  if (spec.scenario === 'parent-crash') {
    // Model an adapter whose EOF disposal cannot finish while foreground work
    // remains active. Transport errors must not turn this into a normal exit.
    process.stdout.on('error', () => {});
    process.on('unhandledRejection', () => {});
    process.on('uncaughtException', () => {});
    setInterval(() => {}, 1000);
    await log({ event: 'guardian', pid: process.ppid });
    const script = `const fs = require('node:fs'); setTimeout(() => fs.writeFileSync(${JSON.stringify(spec.sentinel)}, 'ORPHAN_SIDE_EFFECT'), 4000); setInterval(() => {}, 1000); process.send('ready');`;
    const descendant = spawn(process.execPath, ['-e', script], { stdio: ['ignore', 'ignore', 'ignore', 'ipc'] });
    await new Promise((resolve) => descendant.once('message', resolve));
    await log({ event: 'descendant', pid: descendant.pid });
    await update({ sessionUpdate: 'agent_message_chunk', content: { type: 'text', text: 'PARENT_CRASH_READY' } });
    await new Promise(() => {});
  }
  if (spec.scenario === 'hang') {
    const descendant = spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { stdio: 'ignore' });
    await log({ event: 'descendant', pid: descendant.pid });
    await update({ sessionUpdate: 'agent_message_chunk', content: { type: 'text', text: 'RUNNING' } });
    await new Promise(() => {});
  }
  if (spec.scenario === 'history') {
    await update({ sessionUpdate: 'agent_message_chunk', content: { type: 'text', text: JSON.stringify({ context, prompt: text }) } });
  }
  if (spec.scenario === 'tool') {
    const toolCallId = 'same-id-across-processes';
    const name = spec.tool ?? 'Read';
    const rawInput = spec.input ?? { file_path: resolve('fixture.txt') };
    await update({ sessionUpdate: 'agent_thought_chunk', content: { type: 'text', text: 'Checking permission' } });
    await update({ sessionUpdate: 'tool_call', toolCallId, name, title: 'UNTRUSTED TITLE', status: 'pending', rawInput: { file_path: rawInput.file_path }, content: [] });
    await update({ sessionUpdate: 'tool_call_update', toolCallId, rawInput });
    const result = await client.request('session/request_permission', {
      sessionId,
      toolCall: { toolCallId, name, title: 'UNTRUSTED TITLE', rawInput },
      options: [{ kind: 'allow_once', optionId: 'yes', name: 'Allow' }, { kind: 'reject_once', optionId: 'no', name: 'Deny' }],
    });
    const allowed = result.outcome.outcome === 'selected' && result.outcome.optionId === 'yes';
    let output = 'DENIED';
    if (allowed) output = 'TOOL_APPROVED';
    if (allowed && name === 'Read') output = await readFile(rawInput.file_path, 'utf8');
    if (allowed && (name === 'Write' || name === 'Edit')) { await writeFile(rawInput.file_path, rawInput.content); output = 'WRITTEN'; }
    await update({ sessionUpdate: 'tool_call_update', toolCallId, status: allowed ? 'completed' : 'failed', rawOutput: output });
    await update({ sessionUpdate: 'agent_message_chunk', content: { type: 'text', text: output } });
  }
  return { stopReason: 'end_turn' };
});
app.connect(ndJsonStream(Writable.toWeb(process.stdout), Readable.toWeb(process.stdin)));
