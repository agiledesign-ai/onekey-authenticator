import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('release metadata advances to 1.0.5 with a matching changelog', () => {
  const app = read('AppScope/app.json5');
  const config = read('entry/src/main/ets/common/config/AppConfig.ets');
  const readme = read('README.md');

  assert.match(app, /"versionCode": 1000005/);
  assert.match(app, /"versionName": "1\.0\.5"/);
  assert.match(config, /APP_VERSION_LABEL: string = 'v1\.0\.5'/);
  assert.match(readme, /当前版本：\*\*1\.0\.5\*\*（`versionCode` 1000005）/);
  assert.match(readme, /## 1\.0\.5 更新/);
  assert.match(readme, /2FA验证器-工具/);
});
