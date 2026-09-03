import { describe, expect, it } from '@ohos/hypium';
import { AccountItem } from '../main/ets/model/AccountItem';
import { createGroupItem, GroupItem } from '../main/ets/model/GroupItem';
import { OtpType } from '../main/ets/model/OtpType';
import { GroupStorage, GroupStore } from '../main/ets/common/store/GroupStore';

class MemoryGroupStorage implements GroupStorage {
  groups: GroupItem[] = [];
  private saveAttempts: number = 0;
  private failingSaveAttempt: number = 0;

  failOnSave(attempt: number): void {
    this.saveAttempts = 0;
    this.failingSaveAttempt = attempt;
  }

  loadAll(): GroupItem[] {
    return this.groups.slice();
  }

  save(group: GroupItem): void {
    this.saveAttempts++;
    if (this.saveAttempts === this.failingSaveAttempt) {
      this.failingSaveAttempt = 0;
      throw new Error('write failed');
    }
    const index: number = this.groups.findIndex((item: GroupItem) => item.id === group.id);
    if (index >= 0) {
      this.groups[index] = group;
    } else {
      this.groups.push(group);
    }
  }

  remove(id: string): void {
    this.groups = this.groups.filter((item: GroupItem) => item.id !== id);
  }

  clear(): void {
    this.groups = [];
  }
}

function accountIn(groupId: string): AccountItem {
  return {
    id: 'acc-1',
    type: OtpType.TOTP,
    serviceName: 'GitHub',
    accountName: 'astra',
    badgeColor: '#0A59F7',
    secretKey: 'JBSWY3DPEHPK3PXP',
    algorithm: 'SHA1',
    digits: 6,
    period: 30,
    counter: 0,
    groupId: groupId,
    pinned: false,
    sortIndex: 1,
    createdAt: 1,
    updatedAt: 1,
    schemaVersion: 3
  };
}

export default function groupStoreTest() {
  describe('GroupStore', () => {
    it('saves and lists normalized groups', 0, () => {
      const storage: MemoryGroupStorage = new MemoryGroupStorage();
      GroupStore.init(storage);
      const created = createGroupItem('g-1', '  工作  ', 2, 1000);
      expect(created !== null).assertTrue();
      if (created === null) {
        return;
      }
      expect(GroupStore.add(created)).assertEqual(true);
      expect(GroupStore.list().length).assertEqual(1);
      expect(GroupStore.list()[0].name).assertEqual('工作');
    });

    it('rejects a duplicate group name', 0, () => {
      const storage: MemoryGroupStorage = new MemoryGroupStorage();
      GroupStore.init(storage);
      const first = createGroupItem('g-1', '工作', 1, 1000);
      const second = createGroupItem('g-2', '工作', 2, 1001);
      if (first === null || second === null) {
        return;
      }
      expect(GroupStore.add(first)).assertEqual(true);
      expect(GroupStore.add(second)).assertEqual(false);
    });

    it('ungroups accounts then deletes the group, and rolls back when ungroup fails', 0, () => {
      const storage: MemoryGroupStorage = new MemoryGroupStorage();
      GroupStore.init(storage);
      const created = createGroupItem('work', '工作', 1, 1000);
      if (created === null) {
        return;
      }
      GroupStore.add(created);
      let accounts: AccountItem[] = [accountIn('work')];
      expect(GroupStore.remove('work', {
        ungroup: (groupId: string): boolean => {
          accounts = accounts.map((item: AccountItem) => {
            if (item.groupId !== groupId) {
              return item;
            }
            const next: AccountItem = item;
            next.groupId = '';
            return next;
          });
          return true;
        }
      })).assertEqual(true);
      expect(GroupStore.list().length).assertEqual(0);
      expect(accounts[0].groupId).assertEqual('');

      GroupStore.add(created);
      expect(GroupStore.remove('work', {
        ungroup: (_groupId: string): boolean => {
          return false;
        }
      })).assertEqual(false);
      expect(GroupStore.list().length).assertEqual(1);
    });

    it('replaceAll restores the previous snapshot when a write fails', 0, () => {
      const storage: MemoryGroupStorage = new MemoryGroupStorage();
      GroupStore.init(storage);
      const first = createGroupItem('g-1', '工作', 1, 1000);
      if (first === null) {
        return;
      }
      GroupStore.add(first);
      storage.failOnSave(2);
      const second = createGroupItem('g-2', '生活', 2, 1001);
      if (second === null) {
        return;
      }
      expect(GroupStore.replaceAll([first, second])).assertEqual(false);
      expect(GroupStore.list().length).assertEqual(1);
      expect(GroupStore.list()[0].id).assertEqual('g-1');
    });
  });
}
