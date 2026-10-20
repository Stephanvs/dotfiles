import { randomUUID } from 'node:crypto';
import { isAbsolute, relative, resolve } from 'node:path';
import { realpath } from 'node:fs/promises';
import type { Plugin } from '@opencode/plugin/effect';
import { Effect } from 'effect';
import { Session } from '@opencode/schema/session';
import type { RequestPermissionRequest, RequestPermissionResponse } from '@agentclientprotocol/sdk';

type Capability = { session: Pick<Plugin.Context['session'], 'get'>; permission: Pick<Plugin.Context['permission'], 'assert'> };
const registryKey = Symbol.for('opencode.claude-acp.brokers.v1');
const processRegistry = globalThis as typeof globalThis & { [registryKey]?: Map<string, Capability> };
const brokers = processRegistry[registryKey] ??= new Map<string, Capability>();

export function registerBroker(ctx: Capability) {
  const id = randomUUID();
  brokers.set(id, ctx);
  return { id, dispose() { brokers.delete(id); } };
}

export function getBroker(id: string): Capability {
  const ctx = brokers.get(id);
  if (!ctx) throw new Error('Claude ACP permission broker is unavailable. Load the V2 plugin in this location.');
  return ctx;
}

async function canonical(path: string): Promise<string> {
  try { return await realpath(path); }
  catch {
    const parent = resolve(path, '..');
    return parent === path ? path : resolve(await canonical(parent), relative(parent, path));
  }
}

export async function permission(ctx: Capability, sessionID: string | undefined, cwd: string, invocationID: string, request: RequestPermissionRequest, signal: AbortSignal): Promise<RequestPermissionResponse> {
  const selected = (kind: 'allow_once' | 'reject_once'): RequestPermissionResponse => {
    const option = request.options.find((option) => option.kind === kind);
    return { outcome: option ? { outcome: 'selected', optionId: option.optionId } : { outcome: 'cancelled' } };
  };
  if (!sessionID || signal.aborted) return { outcome: { outcome: 'cancelled' } };
  const call = request.toolCall;
  const name = call.name ?? (call._meta?.claudeCode as { toolName?: string } | undefined)?.toolName;
  const input = call.rawInput;
  if (!input || typeof input !== 'object' || Array.isArray(input)) return selected('reject_once');
  const raw = input as Record<string, unknown>;
  const checks: Array<{ action: string; resources: string[] }> = [];
  if (name === 'Bash') {
    if (typeof raw.command !== 'string' || raw.run_in_background === true || /(?:&|\bnohup\b|\bdisown\b|\bStart-Process\b)/i.test(raw.command)) return selected('reject_once');
    // Shell input is not a safe path parser. Require the broader scope explicitly.
    checks.push({ action: 'shell', resources: [raw.command] }, { action: 'external_directory', resources: ['*'] });
  } else {
    const action = name === 'Read' ? 'read' : name === 'Write' || name === 'Edit' ? 'edit' : name === 'Glob' ? 'glob' : name === 'Grep' ? 'grep' : undefined;
    if (!action) return selected('reject_once');
    const path = action === 'read' || action === 'edit' ? raw.file_path : raw.path ?? cwd;
    if (typeof path !== 'string') return selected('reject_once');
    if ((action === 'glob' || action === 'grep') && typeof raw.pattern !== 'string') return selected('reject_once');
    const target = await canonical(action === 'glob' ? resolve(cwd, path, raw.pattern as string) : resolve(cwd, path));
    const root = await canonical(cwd);
    const rel = relative(root, target);
    if (isAbsolute(rel) || rel === '..' || rel.startsWith(`..${process.platform === 'win32' ? '\\' : '/'}`)) checks.push({ action: 'external_directory', resources: [target] });
    const resource = action === 'glob' || action === 'grep' ? raw.pattern : target;
    if (typeof resource !== 'string') return selected('reject_once');
    checks.push({ action, resources: [resource] });
  }
  try {
    const id = Session.ID.make(sessionID);
    await Effect.runPromise(Effect.gen(function* () {
      const session = yield* ctx.session.get({ sessionID: id });
      for (const check of checks) yield* ctx.permission.assert({ sessionID: id, agent: session.agent, ...check, save: [], metadata: { claudeACPInvocation: invocationID, tool: name, input: raw, cwd } });
    }), { signal });
    return selected('allow_once');
  } catch { return signal.aborted ? { outcome: { outcome: 'cancelled' } } : selected('reject_once'); }
}
