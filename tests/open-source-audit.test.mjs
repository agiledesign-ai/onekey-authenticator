import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function audit(relativePath) {
  return spawnSync(
    process.execPath,
    ['scripts/open-source-audit.mjs', '--path', relativePath],
    { cwd: root, encoding: 'utf8' }
  );
}

test('accepts content that belongs in the public source tree', () => {
  const result = audit('tests/fixtures/open-source-audit/allowed.txt');

  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /Open-source audit passed/);
});

test('rejects signing secrets without printing their values', () => {
  const result = audit('tests/fixtures/open-source-audit/forbidden-signing.txt');

  assert.equal(result.status, 1);
  assert.match(result.stderr, /signing-secret/);
  assert.equal(result.stderr.includes('DO_NOT_USE_SECRET_VALUE'), false);
});

test('rejects wearable implementation references', () => {
  const result = audit('tests/fixtures/open-source-audit/forbidden-wear.txt');

  assert.equal(result.status, 1);
  assert.match(result.stderr, /wearable-feature/);
});

test('does not report its own rule definitions as public source violations', () => {
  const result = audit('.');

  assert.equal(result.status, 0, result.stderr || result.stdout);
});
