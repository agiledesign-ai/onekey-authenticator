import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('cloud feature policy exists and defaults to disabled', () => {
  const policyPath = join(root, 'entry/src/main/ets/features/cloud/model/CloudFeaturePolicy.ets');

  assert.equal(existsSync(policyPath), true);
  assert.match(readFileSync(policyPath, 'utf8'), /ENABLED:\s*boolean\s*=\s*false/);
});

test('app startup initializes cloud only through the feature policy', () => {
  const ability = read('entry/src/main/ets/entryability/EntryAbility.ets');

  assert.match(ability, /CloudFeaturePolicy\.isEnabled\(\)/);
  assert.match(
    ability,
    /if\s*\(CloudFeaturePolicy\.isEnabled\(\)\)\s*\{\s*CloudSyncRuntime\.init\(this\.context\);\s*\}/
  );
});

test('security and backup page hides the cloud row by default', () => {
  const page = read('entry/src/main/ets/pages/SecurityBackupPage.ets');

  assert.match(page, /if\s*\(CloudFeaturePolicy\.isEnabled\(\)\)/);
  assert.ok(page.indexOf('CloudFeaturePolicy.isEnabled()') < page.indexOf("title: '华为云空间'"));
});

test('default manifests contain no cloud identity or cloud permissions', () => {
  const moduleJson = read('entry/src/main/module.json5');
  const appJson = read('AppScope/app.json5');

  assert.equal(/client_id|ohos\.permission\.INTERNET|DISTRIBUTED_DATASYNC/.test(moduleJson), false);
  assert.match(appJson, /"cloudStructuredDataSyncEnabled"\s*:\s*false/);
});
