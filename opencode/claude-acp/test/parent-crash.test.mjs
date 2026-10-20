import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn, execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { access, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const exec = promisify(execFile);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const root = resolve(process.env.USERPROFILE, 'AppData/Local/Temp/opencode/claude-acp-integration');

async function identities(pids) {
  const script = `@(Get-Process -Id ${pids.join(',')} -ErrorAction SilentlyContinue | ForEach-Object { [pscustomobject]@{ pid=$_.Id; name=$_.ProcessName; started=$_.StartTime.ToUniversalTime().Ticks.ToString() } }) | ConvertTo-Json -Compress; exit 0`;
  const { stdout } = await exec('powershell.exe', ['-NoProfile', '-Command', script], { windowsHide: true });
  const result = stdout.trim() ? JSON.parse(stdout) : [];
  return Array.isArray(result) ? result : [result];
}

test('hard death of only the model host closes guardian, adapter and descendant without a future side effect', { skip: process.platform !== 'win32' }, async () => {
  const cwd = await mkdtemp(resolve(root, 'parent-crash-'));
  const host = spawn(process.execPath, [fileURLToPath(new URL('./host-process.mjs', import.meta.url)), cwd], { detached: true, stdio: ['ignore', 'ignore', 'pipe', 'ipc'], windowsHide: true });
  const report = { cwd, hostPID: host.pid, status: 'running', identities: [] };
  host.stderr.on('data', (data) => { report.stderr = (report.stderr ?? '') + data.toString(); });
  let owned = [];
  try {
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Model host did not reach an active ACP inference')), 15000);
      host.once('message', (message) => { clearTimeout(timeout); if (message.hostPID !== host.pid) reject(new Error('Host PID must identify the actual interpreter, not a launcher shim')); else resolve(); });
      host.once('error', (error) => { clearTimeout(timeout); reject(error); });
      host.once('exit', () => { clearTimeout(timeout); reject(new Error(`Model host exited before the crash trigger: ${report.stderr ?? ''}`)); });
    });
    const lifecycle = (await readFile(resolve(cwd, 'lifecycle.jsonl'), 'utf8')).trim().split('\n').map(JSON.parse);
    const roles = ['start', 'guardian', 'descendant'];
    const pids = roles.map((role) => lifecycle.find((entry) => entry.event === role)?.pid);
    assert.ok(pids.every(Number.isInteger));
    report.roles = Object.fromEntries(roles.map((role, index) => [role, pids[index]]));
    owned = await identities([host.pid, ...pids]);
    report.identities = owned;
    assert.equal(owned.length, 4, 'host, guardian, adapter and grandchild must all be active before the crash');
    assert.equal(host.kill('SIGKILL'), true, 'kill only the exact model host, never its process tree');
    report.killMethod = 'ChildProcess.kill(SIGKILL) on the exact host PID only; no taskkill/T';
    const deadline = Date.now() + 1500;
    let survivors;
    do {
      const current = await identities(owned.map((entry) => entry.pid));
      survivors = current.filter((entry) => owned.some((original) => original.pid === entry.pid && original.started === entry.started));
      if (survivors.length) await sleep(50);
    } while (survivors.length && Date.now() < deadline);
    report.survivors = survivors;
    assert.deepEqual(survivors, [], 'guardian, adapter and grandchild survived the owning model host');
    await sleep(4200);
    await assert.rejects(access(resolve(cwd, 'orphan-sentinel.txt')), { code: 'ENOENT' });
    report.futureSentinelAbsent = true;
    report.status = 'pass';
  } catch (error) {
    report.status = 'fail';
    report.error = String(error.stack ?? error);
    throw error;
  } finally {
    if (host.exitCode === null && host.signalCode === null) host.kill('SIGKILL');
    if (owned.length) {
      const current = await identities(owned.map((entry) => entry.pid));
      const guardian = current.find((entry) => entry.pid === report.roles.guardian && owned.some((original) => original.pid === entry.pid && original.started === entry.started));
      // Failure cleanup kills only the captured guardian identity. Its job
      // then closes; this is deliberately after the survival assertion.
      if (guardian) process.kill(guardian.pid, 'SIGKILL');
      const until = Date.now() + 3000;
      let remaining;
      do {
        const latest = await identities(owned.map((entry) => entry.pid));
        remaining = latest.filter((entry) => owned.some((original) => original.pid === entry.pid && original.started === entry.started));
        if (remaining.length) await sleep(50);
      } while (remaining.length && Date.now() < until);
      report.cleanupSurvivors = remaining;
      for (const entry of remaining) process.kill(entry.pid, 'SIGKILL');
    }
    if (host.connected) host.disconnect();
    await writeFile(resolve(cwd, 'report.json'), JSON.stringify(report, null, 2));
    console.log(`Parent-crash evidence: ${resolve(cwd, 'report.json')}`);
  }
});
