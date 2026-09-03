import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('cloud space client keeps Asset Store as source of truth', () => {
  const coordinator = read('entry/src/main/ets/features/cloud/service/CloudSyncCoordinator.ets');
  const mirror = read('entry/src/main/ets/features/cloud/store/CloudMirrorStore.ets');
  const accountStore = read('entry/src/main/ets/common/store/AccountStore.ets');
  assert.match(coordinator, /CloudMergePolicy.merge/);
  assert.match(mirror, /secretKey/);
  assert.match(mirror, /CREATE TABLE IF NOT EXISTS \$\{ACCOUNT_TABLE\}/);
  assert.match(mirror, /CREATE TABLE IF NOT EXISTS \$\{GROUP_TABLE\}/);
  assert.match(mirror, /ACCOUNT_TABLE: string = 'accounts'/);
  assert.match(mirror, /GROUP_TABLE: string = 'groups'/);
  assert.match(accountStore, /CloudLocalHooks.onAccountUpserted/);
  assert.match(accountStore, /replaceAll/);
  assert.equal(mirror.includes('steamGuardData'), false);
});

test('manual cloud push refreshes the cloud baseline before uploading', () => {
  const coordinator = read('entry/src/main/ets/features/cloud/service/CloudSyncCoordinator.ets');
  const pushMethod = coordinator.match(/\n  async push\(\): Promise<CloudCommandResult> \{([\s\S]*?)\n  \}\n\n  async pull/);
  assert.ok(pushMethod, 'CloudSyncCoordinator.push method should be present');
  const body = pushMethod[1];
  const baselineIndex = body.indexOf('this.mirror.pull(');
  const uploadIndex = body.indexOf('this.mirror.push(');
  assert.ok(baselineIndex >= 0, 'push must refresh the cloud baseline first');
  assert.ok(uploadIndex > baselineIndex, 'native-first upload must follow the baseline refresh');
});

test('cloud sync logs the platform progress code and table statistics', () => {
  const mirror = read('entry/src/main/ets/features/cloud/store/CloudMirrorStore.ets');
  assert.match(mirror, /STORE_NAME: string = 'securekeyAccounts\.db'/);
  assert.match(mirror, /CloudMirrorStore\.sync progress/);
  assert.match(mirror, /details\.schedule/);
  assert.match(mirror, /details\.code/);
  assert.match(mirror, /details\.details\[ACCOUNT_TABLE\]/);
});

test('cloud command keeps the platform failure status instead of masking it', () => {
  const coordinator = read('entry/src/main/ets/features/cloud/service/CloudSyncCoordinator.ets');
  assert.match(coordinator, /lastFailureStatus/);
  assert.match(coordinator, /this\.failureStatus\('推送失败'\)/);
  assert.match(coordinator, /this\.failureStatus\('推送准备失败'\)/);
  assert.match(coordinator, /state\.finished && !state\.success/);
});

test('cloud space page is wired under security and backup', () => {
  const page = read('entry/src/main/ets/pages/CloudSpacePage.ets');
  const policy = read('entry/src/main/ets/features/settings/model/SettingsDetailPolicy.ets');
  assert.match(page, /登录华为账号/);
  assert.match(page, /CloudSyncRuntime.login\(/);
  assert.match(page, /CloudAutoSyncPolicy.canOperateSwitch/);
  assert.match(page, /shouldRejectEnable/);
  assert.match(page, /restoreAccount/);
  assert.match(page, /云空间自动同步/);
  assert.match(page, /手动推送/);
  assert.match(page, /手动获取/);
  assert.match(page, /云空间管理/);
  assert.match(policy, /pages\/CloudSpacePage/);
});

test('huawei account restore uses the system account silently', () => {
  const service = read('entry/src/main/ets/features/cloud/service/HuaweiAccountService.ets');
  const policy = read('entry/src/main/ets/features/cloud/model/HuaweiAccountLoginPolicy.ets');
  const runtime = read('entry/src/main/ets/features/cloud/service/CloudSyncRuntime.ets');
  assert.match(policy, /forceLogin\(intent: HuaweiLoginIntent\): boolean/);
  assert.match(policy, /acceptSilentLoginWithoutProfile/);
  assert.match(policy, /static messageFor/);
  assert.match(policy, /1001502003/);
  assert.match(policy, /华为账号登录参数配置错误/);
  assert.match(policy, /cancelBeforeLogin/);
  assert.match(policy, /attachCsrfState/);
  assert.match(policy, /authorizationScopes/);
  assert.match(service, /HuaweiAccountLoginPolicy.messageFor/);
  assert.match(service, /createCancelAuthorizationRequest/);
  assert.match(service, /createLoginWithHuaweiIDRequest/);
  assert.match(service, /authorizationScopes/);
  assert.match(policy, /openid/);
  assert.match(policy, /profile/);
  assert.match(service, /async restore\(\)/);
  assert.match(service, /getOsAccountDistributedInfo/);
  assert.match(service, /probeSystemAccountName/);
  assert.equal(service.includes('readClientId'), false);
  assert.match(runtime, /CloudSyncRuntime.restoreAccount\(\)/);
  assert.match(runtime, /probeSystemAccountName/);
  assert.match(runtime, /login\(context/);
});
