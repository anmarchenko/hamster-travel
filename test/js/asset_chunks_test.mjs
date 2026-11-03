// Run after mix assets.deploy. Phoenix only rewrites source-map JS references,
// so every relative module import in its digested output must remain available.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const staticDir = resolve('priv/static');
const manifestPath = resolve(staticDir, 'cache_manifest.json');

test('digested production entry resolves all static and lazy chunk imports', {
  skip: !existsSync(manifestPath) && 'run mix assets.deploy first',
}, () => {
  const manifest = JSON.parse(readFileSync(manifestPath));
  const entry = resolve(staticDir, manifest.latest['assets/app.js']);
  const visited = new Set();
  function visit(path) {
    if (visited.has(path)) return;
    visited.add(path);
    assert.ok(existsSync(path), `missing imported asset: ${path}`);
    const source = readFileSync(path, 'utf8');
    const imports = [...source.matchAll(/(?:from\s*|import\s*\(?)["'](\.\.?\/[^"']+\.js)["']/g)];
    for (const [, imported] of imports) visit(resolve(dirname(path), imported));
  }
  visit(entry);
  assert.ok([...visited].some((path) => /user_map-[A-Z0-9]+\.js$/.test(path)));
  assert.ok([...visited].some((path) => /formatted_text_area-[A-Z0-9]+\.js$/.test(path)));
  assert.ok(readFileSync(entry, 'utf8').includes('import('), 'features must use dynamic imports');
});
