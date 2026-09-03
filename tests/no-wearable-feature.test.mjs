import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('public project declares only entry and otp_core modules', () => {
  assert.equal(existsSync(join(root, 'build-profile.json5')), true);
  const profile = read('build-profile.json5');

  assert.match(profile, /"name"\s*:\s*"entry"/);
  assert.match(profile, /"name"\s*:\s*"otp_core"/);
  assert.equal(/"name"\s*:\s*"wear"/.test(profile), false);
  assert.equal(existsSync(join(root, 'wear')), false);
});

test('phone source has no wearable route metadata or implementation', () => {
  assert.equal(existsSync(join(root, 'entry/src/main/module.json5')), true);
  assert.equal(existsSync(join(root, 'entry/src/main/ets/features/wear')), false);
  assert.equal(existsSync(join(root, 'entry/src/main/ets/pages/SendToWatchPage.ets')), false);

  const moduleJson = read('entry/src/main/module.json5');
  const routes = read('entry/src/main/ets/features/settings/model/SettingsDetailPolicy.ets');
  const pages = read('entry/src/main/resources/base/profile/main_pages.json');
  const combined = `${moduleJson}\n${routes}\n${pages}`;

  assert.equal(/wearEngineRemoteAppNameList|SendToWatchPage|SEND_WATCH/.test(combined), false);
});

test('phone tests no longer register wearable suites', () => {
  const list = read('entry/src/test/List.test.ets');

  assert.equal(/WearAccountPolicy|WearSendPolicy|WatchSyncRecord/.test(list), false);
});
