import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const publicBundleName = 'com.agiledesign.onekeyauthenticator.opensource';
const privateBundleName = ['com', 'halolion', 'authenticator'].join('.');

function read(relativePath) {
  const path = join(root, relativePath);
  assert.equal(existsSync(path), true, `${relativePath} must exist`);
  return readFileSync(path, 'utf8');
}

test('public app uses its independent bundle and keeps cloud data sync disabled', () => {
  const app = read('AppScope/app.json5');

  assert.match(app, new RegExp(publicBundleName.replaceAll('.', '\\.')));
  assert.match(app, /"versionName"\s*:\s*"1\.0\.5"/);
  assert.match(app, /"cloudStructuredDataSyncEnabled"\s*:\s*false/);
});

test('service card targets the public bundle', () => {
  const card = read('entry/src/main/ets/pages/CardConfigPage.ets');

  assert.match(card, new RegExp(publicBundleName.replaceAll('.', '\\.')));
  assert.equal(card.includes(privateBundleName), false);
});

test('public build profile contains no signing configuration', () => {
  const profile = read('build-profile.json5');

  assert.equal(/signingConfigs|signingConfig|keyPassword|storePassword/.test(profile), false);
});
