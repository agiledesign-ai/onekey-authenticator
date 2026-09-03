import { describe, expect, it } from '@ohos/hypium';
import { AccountItem } from '../main/ets/model/AccountItem';
import { GroupItem } from '../main/ets/model/GroupItem';
import { OtpType } from '../main/ets/model/OtpType';
import {
  CloudAuthGate,
  CloudLocalVault,
  CloudMergeSnapshot,
  CloudMirrorGateway,
  CloudSettingsPort,
  CloudSyncCoordinator
} from '../main/ets/features/cloud/service/CloudSyncCoordinator';
import { CloudSettings, CloudSettingsFactory } from '../main/ets/features/cloud/model/CloudSettings';
import { CloudSyncState } from '../main/ets/features/cloud/model/CloudSyncState';

function account(id: string): AccountItem {
  return {
    id: id,
    type: OtpType.TOTP,
    serviceName: id,
    accountName: 'demo',
    badgeColor: '#0A59F7',
    secretKey: 'JBSWY3DPEHPK3PXP',
    algorithm: 'SHA1',
    digits: 6,
    period: 30,
    counter: 0,
    groupId: '',
    pinned: false,
    sortIndex: 1,
    createdAt: 1,
    updatedAt: 1,
    schemaVersion: 3
  };
}

function successState(status: string): CloudSyncState {
  return { status: status, finished: true, success: true };
}

class FakeSettings implements CloudSettingsPort {
  value: CloudSettings = CloudSettingsFactory.empty();

  load(): CloudSettings {
    return {
      autoSync: this.value.autoSync,
      loggedIn: this.value.loggedIn,
      nickname: this.value.nickname,
      avatarUri: this.value.avatarUri,
      userId: this.value.userId,
      status: this.value.status,
      lastSyncTime: this.value.lastSyncTime
    };
  }

  save(settings: CloudSettings): void {
    this.value = settings;
  }
}

class FakeAuth implements CloudAuthGate {
  loggedIn: boolean = false;
  grant: boolean = true;
  delayGrant: Promise<void> | null = null;

  isLoggedIn(): boolean {
    return this.loggedIn;
  }

  async requestDataSync(): Promise<boolean> {
    if (this.delayGrant !== null) {
      await this.delayGrant;
    }
    return this.grant;
  }
}

class FakeMirror implements CloudMirrorGateway {
  autoSync: boolean = false;
  stagedAccounts: AccountItem[] = [];
  deletedIds: string[] = [];
  pushOk: boolean = true;
  pullOk: boolean = true;
  pullSnapshot: CloudMergeSnapshot = { accounts: [], groups: [] };
  pushCalls: number = 0;

  async configure(enabled: boolean): Promise<boolean> {
    this.autoSync = enabled;
    return true;
  }

  async stageAll(accounts: AccountItem[], _groups: GroupItem[]): Promise<boolean> {
    this.stagedAccounts = accounts.slice();
    return true;
  }

  async stageAccount(item: AccountItem): Promise<boolean> {
    this.stagedAccounts.push(item);
    return true;
  }

  async deleteAccount(id: string): Promise<boolean> {
    this.deletedIds.push(id);
    return true;
  }

  async deleteAccounts(ids: string[]): Promise<boolean> {
    this.deletedIds = this.deletedIds.concat(ids);
    return true;
  }

  async push(_listener: (state: CloudSyncState) => void): Promise<boolean> {
    this.pushCalls++;
    return this.pushOk;
  }

  async pull(_listener: (state: CloudSyncState) => void): Promise<CloudMergeSnapshot | null> {
    if (!this.pullOk) {
      return null;
    }
    return this.pullSnapshot;
  }
}

class FakeVault implements CloudLocalVault {
  current: CloudMergeSnapshot = { accounts: [account('local-1')], groups: [] };
  failReplace: boolean = false;
  restored: boolean = false;

  snapshot(): CloudMergeSnapshot {
    return {
      accounts: this.current.accounts.slice(),
      groups: this.current.groups.slice()
    };
  }

  replace(next: CloudMergeSnapshot): boolean {
    if (this.failReplace) {
      return false;
    }
    this.current = {
      accounts: next.accounts.slice(),
      groups: next.groups.slice()
    };
    return true;
  }

  restore(previous: CloudMergeSnapshot): boolean {
    this.restored = true;
    this.current = {
      accounts: previous.accounts.slice(),
      groups: previous.groups.slice()
    };
    return true;
  }
}

function coordinator(auth: FakeAuth, mirror: FakeMirror, vault: FakeVault,
  settings: FakeSettings): CloudSyncCoordinator {
  return new CloudSyncCoordinator(auth, mirror, vault, settings);
}

export default function cloudSyncCoordinatorTest() {
  describe('CloudSyncCoordinator', () => {
    it('keeps auto sync off when the Huawei account is not signed in', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      const settings: FakeSettings = new FakeSettings();
      const result = await coordinator(auth, new FakeMirror(), new FakeVault(), settings).enableAutoSync();

      expect(result.success).assertEqual(false);
      expect(result.status).assertEqual('请先登录');
      expect(settings.value.autoSync).assertEqual(false);
    });

    it('keeps auto sync off when distributed data sync is denied', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      auth.grant = false;
      const settings: FakeSettings = new FakeSettings();
      const result = await coordinator(auth, new FakeMirror(), new FakeVault(), settings).enableAutoSync();

      expect(result.success).assertEqual(false);
      expect(result.status).assertEqual('未授权云同步');
      expect(settings.value.autoSync).assertEqual(false);
    });

    it('enables auto sync after a successful push and merged pull', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      const mirror: FakeMirror = new FakeMirror();
      mirror.pullSnapshot = { accounts: [account('cloud-1')], groups: [] };
      const vault: FakeVault = new FakeVault();
      const settings: FakeSettings = new FakeSettings();
      const result = await coordinator(auth, mirror, vault, settings).enableAutoSync();

      expect(result.success).assertEqual(true);
      expect(settings.value.autoSync).assertEqual(true);
      expect(mirror.autoSync).assertEqual(true);
      expect(vault.current.accounts.length).assertEqual(2);
    });

    it('rejects a second command while a sync is running', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      let releaseGrant: () => void = () => {};
      auth.delayGrant = new Promise<void>((resolve: () => void) => {
        releaseGrant = resolve;
      });
      const sync: CloudSyncCoordinator = coordinator(auth, new FakeMirror(), new FakeVault(), new FakeSettings());
      const first = sync.enableAutoSync();
      const second = await sync.push();
      expect(second.success).assertEqual(false);
      expect(second.status).assertEqual('正在同步，请稍候');
      releaseGrant();
      await first;
    });

    it('does not write the mirror when auto sync is off', 0, async () => {
      const mirror: FakeMirror = new FakeMirror();
      const sync: CloudSyncCoordinator = coordinator(new FakeAuth(), mirror, new FakeVault(), new FakeSettings());
      await sync.onLocalAccountUpserted(account('new-1'));
      await sync.onLocalAccountRemoved('new-1');
      expect(mirror.stagedAccounts.length).assertEqual(0);
      expect(mirror.deletedIds.length).assertEqual(0);
    });

    it('stages and deletes through the mirror only after auto sync is on', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      const mirror: FakeMirror = new FakeMirror();
      const settings: FakeSettings = new FakeSettings();
      const sync: CloudSyncCoordinator = coordinator(auth, mirror, new FakeVault(), settings);
      await sync.enableAutoSync();
      await sync.onLocalAccountUpserted(account('new-1'));
      await sync.onLocalAccountRemoved('gone-1');
      await sync.onLocalAccountsCleared(['a', 'b']);
      expect(mirror.stagedAccounts[mirror.stagedAccounts.length - 1].id).assertEqual('new-1');
      expect(mirror.deletedIds.indexOf('gone-1') >= 0).assertTrue();
      expect(mirror.deletedIds.indexOf('a') >= 0).assertTrue();
    });

    it('restores the local snapshot when applying a pull fails', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      const mirror: FakeMirror = new FakeMirror();
      mirror.pullSnapshot = { accounts: [account('cloud-1')], groups: [] };
      const vault: FakeVault = new FakeVault();
      vault.failReplace = true;
      const settings: FakeSettings = new FakeSettings();
      const result = await coordinator(auth, mirror, vault, settings).enableAutoSync();
      expect(result.success).assertEqual(false);
      expect(vault.restored).assertEqual(true);
      expect(settings.value.autoSync).assertEqual(false);
    });

    it('turns auto sync off on logout without changing local data', 0, async () => {
      const auth: FakeAuth = new FakeAuth();
      auth.loggedIn = true;
      const vault: FakeVault = new FakeVault();
      const settings: FakeSettings = new FakeSettings();
      const sync: CloudSyncCoordinator = coordinator(auth, new FakeMirror(), vault, settings);
      await sync.enableAutoSync();
      sync.logout();
      expect(settings.value.autoSync).assertEqual(false);
      expect(settings.value.loggedIn).assertEqual(false);
      expect(vault.current.accounts[0].id).assertEqual('local-1');
    });
  });
}
