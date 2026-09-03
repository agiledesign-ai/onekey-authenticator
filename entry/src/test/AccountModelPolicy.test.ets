import { describe, expect, it } from '@ohos/hypium';
import { createAccountItem } from '../main/ets/model/AccountItem';
import { createGroupItem, isSameGroupName } from '../main/ets/model/GroupItem';
import { OtpType } from '../main/ets/model/OtpType';

export default function accountModelPolicyTest() {
  describe('AccountModelPolicy', () => {
    it('creates a schema v3 TOTP account with canonical defaults', 0, () => {
      const account = createAccountItem(
        'account-1',
        'GitHub',
        'astra@example.com',
        'JBSWY3DPEHPK3PXP',
        { type: OtpType.TOTP }
      );

      expect(account.type).assertEqual(OtpType.TOTP);
      expect(account.algorithm).assertEqual('SHA1');
      expect(account.digits).assertEqual(6);
      expect(account.period).assertEqual(30);
      expect(account.counter).assertEqual(0);
      expect(account.groupId).assertEqual('');
      expect(account.schemaVersion).assertEqual(3);
    });

    it('creates normalized groups and rejects empty names', 0, () => {
      const group = createGroupItem('group-1', '  工作  ', 3, 1000);
      const emptyGroup = createGroupItem('group-2', '   ', 4, 1000);

      expect(group !== null).assertTrue();
      if (group !== null) {
        expect(group.name).assertEqual('工作');
        expect(group.sortIndex).assertEqual(3);
        expect(group.createdAt).assertEqual(1000);
        expect(group.updatedAt).assertEqual(1000);
      }
      expect(emptyGroup === null).assertTrue();
      expect(isSameGroupName(' Work ', 'work')).assertTrue();
      expect(isSameGroupName('Work', 'Personal')).assertFalse();
    });

    it('creates HOTP and Steam accounts with type-specific parameters', 0, () => {
      const hotp = createAccountItem(
        'account-2',
        'VPN',
        'astra',
        'JBSWY3DPEHPK3PXP',
        {
          type: OtpType.HOTP,
          algorithm: 'SHA256',
          digits: 8,
          counter: 42,
          groupId: 'work'
        }
      );
      const steam = createAccountItem(
        'account-3',
        'Steam',
        'astra',
        'JBSWY3DPEHPK3PXP',
        { type: OtpType.STEAM }
      );

      expect(hotp.algorithm).assertEqual('SHA256');
      expect(hotp.digits).assertEqual(8);
      expect(hotp.counter).assertEqual(42);
      expect(hotp.groupId).assertEqual('work');
      expect(steam.algorithm).assertEqual('SHA1');
      expect(steam.digits).assertEqual(5);
      expect(steam.period).assertEqual(30);
      expect(steam.counter).assertEqual(0);
    });
  });
}
