import { describe, expect, it } from '@ohos/hypium';
import { AccountItem } from '../main/ets/model/AccountItem';
import { GroupItem } from '../main/ets/model/GroupItem';
import { OtpType } from '../main/ets/model/OtpType';
import { CloudMergePolicy } from '../main/ets/features/cloud/model/CloudMergePolicy';

function account(id: string, updatedAt: number, groupId: string = ''): AccountItem {
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
    groupId: groupId,
    pinned: false,
    sortIndex: 1,
    createdAt: 1,
    updatedAt: updatedAt,
    schemaVersion: 3
  };
}

function group(id: string, name: string, updatedAt: number): GroupItem {
  return {
    id: id,
    name: name,
    sortIndex: 1,
    createdAt: 1,
    updatedAt: updatedAt
  };
}

export default function cloudMergePolicyTest() {
  describe('CloudMergePolicy', () => {
    it('adds cloud-only accounts and groups', 0, () => {
      const merged = CloudMergePolicy.merge(
        { accounts: [account('local-1', 10)], groups: [group('g-local', '本机', 10)] },
        { accounts: [account('cloud-1', 20)], groups: [group('g-cloud', '云端', 20)] }
      );

      expect(merged.accounts.length).assertEqual(2);
      expect(merged.groups.length).assertEqual(2);
      expect(merged.accounts[0].id === 'local-1' || merged.accounts[1].id === 'local-1').assertTrue();
      expect(merged.accounts[0].id === 'cloud-1' || merged.accounts[1].id === 'cloud-1').assertTrue();
    });

    it('keeps the newer updatedAt when both sides have the same id', 0, () => {
      const merged = CloudMergePolicy.merge(
        {
          accounts: [account('a-1', 10)],
          groups: [group('g-1', '旧名', 10)]
        },
        {
          accounts: [account('a-1', 30)],
          groups: [group('g-1', '新名', 30)]
        }
      );

      expect(merged.accounts.length).assertEqual(1);
      expect(merged.accounts[0].updatedAt).assertEqual(30);
      expect(merged.groups[0].name).assertEqual('新名');
    });

    it('keeps the local record when updatedAt is equal', 0, () => {
      const localAccount: AccountItem = account('a-1', 20);
      localAccount.serviceName = '本机';
      const cloudAccount: AccountItem = account('a-1', 20);
      cloudAccount.serviceName = '云端';
      const merged = CloudMergePolicy.merge(
        { accounts: [localAccount], groups: [group('g-1', '本机', 20)] },
        { accounts: [cloudAccount], groups: [group('g-1', '云端', 20)] }
      );

      expect(merged.accounts[0].serviceName).assertEqual('本机');
      expect(merged.groups[0].name).assertEqual('本机');
    });

    it('keeps local-only records that the cloud does not have', 0, () => {
      const merged = CloudMergePolicy.merge(
        { accounts: [account('only-local', 10)], groups: [group('only-local', '仅本机', 10)] },
        { accounts: [], groups: [] }
      );

      expect(merged.accounts.length).assertEqual(1);
      expect(merged.accounts[0].id).assertEqual('only-local');
      expect(merged.groups[0].id).assertEqual('only-local');
    });

    it('clears groupId when the merged groups do not contain it', 0, () => {
      const merged = CloudMergePolicy.merge(
        { accounts: [account('a-1', 10, 'missing')], groups: [] },
        { accounts: [], groups: [] }
      );

      expect(merged.accounts[0].groupId).assertEqual('');
    });

    it('keeps groupId when the merged groups contain it', 0, () => {
      const merged = CloudMergePolicy.merge(
        { accounts: [account('a-1', 10, 'work')], groups: [] },
        { accounts: [], groups: [group('work', '工作', 5)] }
      );

      expect(merged.accounts[0].groupId).assertEqual('work');
      expect(merged.groups[0].id).assertEqual('work');
    });
  });
}
