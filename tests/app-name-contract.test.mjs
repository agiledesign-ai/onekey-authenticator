import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('display name is 2FA验证器-工具 in the public phone app', () => {
  assert.match(read('AppScope/resources/base/element/string.json'), /"value": "2FA验证器-工具"/);
  assert.match(read('entry/src/main/resources/base/element/string.json'), /"value": "2FA验证器-工具"/);
  assert.match(read('entry/src/main/ets/common/config/AppConfig.ets'), /APP_NAME: string = '2FA验证器-工具'/);
});

test('page copy uses generic 2FA验证器 wording instead of the branded app name', () => {
  const pageFiles = [
    'entry/src/main/ets/pages/Index.ets',
    'entry/src/main/ets/pages/CloudSpacePage.ets',
    'entry/src/main/ets/pages/TwoFactorGuidePage.ets',
    'entry/src/main/ets/features/home/components/HomeContent.ets',
    'entry/src/main/ets/features/onboarding/components/LaunchIntro.ets',
    'entry/src/main/ets/features/security/service/FaceAuthService.ets',
    'entry/src/main/ets/features/settings/model/SettingsDetailContent.ets',
    'entry/src/main/ets/features/card/model/CardProjection.ets'
  ];
  for (const file of pageFiles) {
    const source = read(file);
    assert.match(source, /2FA验证器/);
    assert.equal(source.includes('2FA验证器-工具'), false, file);
  }
});
