import { describe, expect, it } from '@ohos/hypium';
import { AccountItem } from '../main/ets/model/AccountItem';
import { createGroupItem } from '../main/ets/model/GroupItem';
import { OtpType } from '../main/ets/model/OtpType';
import { CloudRecordCodec } from '../main/ets/features/cloud/model/CloudRecordCodec';

export default function cloudRecordCodecTest() {
  describe('CloudRecordCodec', () => {
    it('maps pinned and secretKey for cloud account rows', 0, () => {
      const account: AccountItem = {
        id: 'acc-1',
        type: OtpType.HOTP,
        serviceName: 'GitHub',
        accountName: 'astra',
        badgeColor: '#4285F4',
        secretKey: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA256',
        digits: 8,
        period: 30,
        counter: 7,
        groupId: 'work',
        pinned: true,
        sortIndex: 3,
        createdAt: 11,
        updatedAt: 22,
        schemaVersion: 3
      };

      const row = CloudRecordCodec.accountToRow(account);
      expect(row.id).assertEqual('acc-1');
      expect(row.type).assertEqual('HOTP');
      expect(row.secretKey).assertEqual('JBSWY3DPEHPK3PXP');
      expect(row.pinned).assertEqual(1);
      expect(row.groupId).assertEqual('work');

      const restored: AccountItem = CloudRecordCodec.rowToAccount(row);
      expect(restored.pinned).assertEqual(true);
      expect(restored.type).assertEqual(OtpType.HOTP);
      expect(restored.secretKey).assertEqual('JBSWY3DPEHPK3PXP');
      expect(restored.schemaVersion).assertEqual(3);
    });

    it('maps unpinned accounts to zero and restores groups', 0, () => {
      const account: AccountItem = {
        id: 'acc-2',
        type: OtpType.STEAM,
        serviceName: 'Steam',
        accountName: 'astra',
        badgeColor: '#111111',
        secretKey: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 5,
        period: 30,
        counter: 0,
        groupId: '',
        pinned: false,
        sortIndex: 1,
        createdAt: 1,
        updatedAt: 2,
        schemaVersion: 3
      };
      const group = createGroupItem('g-1', '工作', 4, 9);
      expect(group !== null).assertTrue();
      if (group === null) {
        return;
      }

      expect(CloudRecordCodec.accountToRow(account).pinned).assertEqual(0);
      const groupRow = CloudRecordCodec.groupToRow(group);
      expect(groupRow.id).assertEqual('g-1');
      expect(groupRow.name).assertEqual('工作');
      expect(CloudRecordCodec.rowToGroup(groupRow).sortIndex).assertEqual(4);
    });
  });
}
