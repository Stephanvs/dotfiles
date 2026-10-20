import { spawn } from 'node:child_process';
import { Readable, Writable } from 'node:stream';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { realpathSync, statSync } from 'node:fs';
import { delimiter, isAbsolute, join } from 'node:path';
import { ClientApp, ndJsonStream } from '@agentclientprotocol/sdk';
import type { NewSessionResponse, RequestPermissionRequest, RequestPermissionResponse, SessionUpdate } from '@agentclientprotocol/sdk';
import { sessionOptions } from './policy.js';
import { subscriptionEnvironment } from './environment.js';

export type AdapterCommand = readonly [string, ...string[]];
export interface ACPHandlers {
  update(update: SessionUpdate): void;
  permission(request: RequestPermissionRequest): Promise<RequestPermissionResponse>;
}

function executableOnPath(name: string): string {
  for (const directory of (process.env.PATH ?? '').split(delimiter)) {
    const absolute = directory.replace(/^"|"$/g, '');
    if (!isAbsolute(absolute)) continue;
    try {
      const path = realpathSync(join(absolute, name));
      if (statSync(path).isFile()) return path;
    } catch { continue; }
  }
  throw new Error(`Claude ACP requires an installed ${name} executable on PATH; bundled Claude CLI fallback is disabled`);
}

export function adapterCommand(): AdapterCommand {
  const require = createRequire(import.meta.url);
  // OpenCode may be a compiled Bun executable, not an interpreter for JS files.
  return [executableOnPath('node.exe'), require.resolve('@agentclientprotocol/claude-agent-acp/dist/index.js')];
}

export class ACPProcess {
  private readonly child;
  private readonly connection;
  private sessionID?: string;
  private closing?: Promise<void>;
  private readonly exited: Promise<void>;
  private stderr = '';
  private signal?: AbortSignal;
  private readonly cancel = () => { void this.close().catch((error) => this.connection.close(error)); };

  constructor(cwd: string, handlers: ACPHandlers, command?: AdapterCommand) {
    if (process.platform !== 'win32') throw new Error('Claude ACP local provider currently supports Windows only (owned process-tree cleanup)');
    const env = subscriptionEnvironment();
    if (command === undefined) env.CLAUDE_CODE_EXECUTABLE = executableOnPath('claude.exe');
    const selected = command ?? adapterCommand();
    const quote = (value: string) => '"' + value.replace(/(\\*)"/g, '$1$1\\"').replace(/(\\+)$/g, '$1$1') + '"';
    const launch = Buffer.from(JSON.stringify({ commandLine: selected.map(quote).join(' '), cwd, parentPid: process.pid })).toString('base64');
    const powershell = join(process.env.SystemRoot ?? 'C:\\Windows', 'System32/WindowsPowerShell/v1.0/powershell.exe');
    this.child = spawn(powershell, ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', fileURLToPath(new URL('./guardian.ps1', import.meta.url)), '-Launch', launch], { cwd, env, stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
    this.exited = new Promise((resolve) => {
      this.child.once('exit', () => resolve());
      this.child.once('error', () => resolve());
    });
    this.child.stderr.on('data', (data: Buffer) => { this.stderr = (this.stderr + data.toString()).slice(-4000); });
    const app = new ClientApp();
    app.onRequest('session/request_permission', ({ params }) => handlers.permission(params));
    app.onNotification('session/update', ({ params }) => {
      if (params.sessionId === this.sessionID) handlers.update(params.update);
    });
    this.connection = app.connect(ndJsonStream(Writable.toWeb(this.child.stdin), Readable.toWeb(this.child.stdout) as unknown as ReadableStream<Uint8Array>));
    this.child.once('error', (error) => this.connection.close(error));
    this.child.once('exit', (code) => this.connection.close(new Error(`Claude ACP exited (${code}). ${this.stderr}`)));
  }

  async open(cwd: string, signal: AbortSignal): Promise<NewSessionResponse> {
    signal.throwIfAborted();
    this.signal = signal;
    signal.addEventListener('abort', this.cancel, { once: true });
    await this.connection.agent.request('initialize', {
      protocolVersion: 1,
      clientInfo: { name: 'opencode-claude-acp', version: '0.1.0' },
      clientCapabilities: {},
    }, { cancellationSignal: signal });
    const session = await this.connection.agent.request('session/new', {
      cwd, mcpServers: [],
      _meta: { claudeCode: { options: sessionOptions() } },
    }, { cancellationSignal: signal });
    this.sessionID = session.sessionId;
    await this.connection.agent.request('session/set_mode', { sessionId: session.sessionId, modeId: 'default' }, { cancellationSignal: signal });
    await this.disableFast(session.configOptions, signal);
    return session;
  }

  async model(modelID: string, signal: AbortSignal) {
    if (!this.sessionID) throw new Error('Claude ACP session is not open');
    const result = await this.connection.agent.request('session/set_config_option', { sessionId: this.sessionID, configId: 'model', value: modelID }, { cancellationSignal: signal });
    await this.disableFast(result.configOptions, signal);
    return result;
  }

  private async disableFast(options: NewSessionResponse['configOptions'], signal: AbortSignal) {
    const fast = options?.find((option) => option.id === 'fast');
    if (fast?.type === 'select' && fast.options.some((option) => 'value' in option && option.value === 'off')) await this.connection.agent.request('session/set_config_option', { sessionId: this.sessionID!, configId: fast.id, value: 'off' }, { cancellationSignal: signal });
  }

  async prompt(text: string, signal: AbortSignal) {
    if (!this.sessionID) throw new Error('Claude ACP session is not open');
    return this.connection.agent.request('session/prompt', { sessionId: this.sessionID, prompt: [{ type: 'text', text }] }, { cancellationSignal: signal });
  }

  close(): Promise<void> {
    return this.closing ??= this.cleanup();
  }

  private async cleanup() {
    this.signal?.removeEventListener('abort', this.cancel);
    if (this.sessionID) {
      await this.connection.agent.notify('session/cancel', { sessionId: this.sessionID }).catch(() => {});
      await Promise.race([
        this.connection.agent.request('session/close', { sessionId: this.sessionID }).catch(() => {}),
        new Promise<void>((resolve) => setTimeout(resolve, 750)),
      ]);
    }
    if (this.child.pid && this.child.exitCode === null && this.child.signalCode === null) this.child.kill();
    this.connection.close();
    this.child.stdin.destroy();
    this.child.stdout.destroy();
    await Promise.race([this.exited, new Promise<never>((_, reject) => setTimeout(() => reject(new Error('Claude ACP guardian cleanup timed out')), 3000).unref())]);
    if (this.child.exitCode === 126) throw new Error(`Claude ACP guardian failed: ${this.stderr}`);
  }
}

export async function discoverModels(cwd: string, lifetime?: AbortSignal) {
  const acp = new ACPProcess(cwd, { update() {}, async permission() { return { outcome: { outcome: 'cancelled' } }; } });
  const timeout = AbortSignal.timeout(45_000);
  const signal = lifetime ? AbortSignal.any([lifetime, timeout]) : timeout;
  try {
    const session = await acp.open(cwd, signal);
    const model = session.configOptions?.find((option) => option.category === 'model');
    if (!model || model.type !== 'select') throw new Error('Claude ACP did not advertise its model catalog');
    return model.options.flatMap((option) => 'value' in option ? [{ id: option.value, name: option.name }] : option.options.map((item) => ({ id: item.value, name: item.name })));
  } finally { await acp.close(); }
}
