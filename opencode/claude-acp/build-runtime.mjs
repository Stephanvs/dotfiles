import { createHash } from 'node:crypto';
import { mkdir, readFile, readdir, rename, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const compiled = resolve(root, '.build');
const dist = resolve(root, 'dist');
const files = new Map();
for (const name of (await readdir(compiled)).sort()) {
  if (name.endsWith('.js') || name.endsWith('.d.ts')) files.set(name, await readFile(resolve(compiled, name)));
}
for (const name of ['guardian.cs', 'guardian.ps1']) files.set(name, await readFile(resolve(root, name)));
const hash = createHash('sha256');
for (const [name, bytes] of files) hash.update(name).update('\0').update(bytes).update('\0');
const generation = hash.digest('hex').slice(0, 24);
const runtime = resolve(dist, 'runtime', generation);
await mkdir(runtime, { recursive: true });
for (const [name, bytes] of files) {
  const path = resolve(runtime, name);
  try { await writeFile(path, bytes, { flag: 'wx' }); }
  catch (error) {
    if (error.code !== 'EEXIST' || !(await readFile(path)).equals(bytes)) throw error;
  }
}

// Core caches native provider entrypoints for the process lifetime. Publish a
// complete immutable graph first, then atomically move the plugin entry to it.
const entry = `export { default } from './runtime/${generation}/index.js';\n`;
const temporary = resolve(dist, `index-${process.pid}.tmp`);
await writeFile(temporary, entry);
await rename(temporary, resolve(dist, 'index.js'));

// Keep the documented direct-provider entry and Node test boundary available.
for (const [name, bytes] of files) if (name !== 'index.js') await writeFile(resolve(dist, name), bytes);
console.log(`Claude ACP runtime generation ${generation}`);
