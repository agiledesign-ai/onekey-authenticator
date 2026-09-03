import { describe, expect, it } from '@ohos/hypium';
import { AccountListPolicy } from '../main/ets/features/account/model/AccountListPolicy';
import { AccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';

function account(
  id: string,
  serviceName: string,
  accountName: string,
  pinned: boolean,
  sortIndex: number
): AccountItem {
  return {
    id: id,
    type: OtpType.TOTP,
    serviceName: serviceName,
    accountName: accountName,
    badgeColor: '#0A59F7',
    secretKey: 'JBSWY3DPEHPK3PXP',
    algorithm: 'SHA1',
    digits: 6,
    period: 30,
    counter: 0,
    groupId: '',
    pinned: pinned,
    sortIndex: sortIndex,
    createdAt: 1,
    updatedAt: 1,
    schemaVersion: 3
  };
}

export default function accountListPolicyTest() {
  describe('AccountListPolicy', () => {
    it('filters by service or account name and never inspects the secret', 0, () => {
      const accounts: AccountItem[] = [
        account('1', 'GitHub', 'astra@example.com', false, 2),
        account('2', 'Steam', 'player', true, 1),
        account('3', 'Corp VPN', 'secret-looking', false, 3)
      ];
      const result = AccountListPolicy.filter(accounts, '  git  ');
      expect(result.length).assertEqual(1);
      expect(result[0].id).assertEqual('1');
      expect(AccountListPolicy.filter(accounts, 'JBSWY3DPEHPK3PXP').length).assertEqual(0);
      expect(AccountListPolicy.filter(accounts, 'player')[0].id).assertEqual('2');
    });

    it('keeps pinned accounts first inside search results', 0, () => {
      const accounts: AccountItem[] = [
        account('1', 'Alpha Mail', 'one', false, 1),
        account('2', 'Alpha Drive', 'two', true, 2),
        account('3', 'Beta', 'alpha', false, 3)
      ];
      const result = AccountListPolicy.filter(accounts, 'alpha');
      expect(result.length).assertEqual(3);
      expect(result[0].id).assertEqual('2');
    });

    it('puts pinned accounts first even when the search box is empty', 0, () => {
      const accounts: AccountItem[] = [
        account('1', 'GitHub', 'one', false, 1),
        account('2', 'Steam', 'two', true, 3),
        account('3', 'VPN', 'three', false, 2)
      ];
      const result = AccountListPolicy.filter(accounts, '   ');
      expect(result.length).assertEqual(3);
      expect(result[0].id).assertEqual('2');
      expect(result[1].id).assertEqual('1');
      expect(result[2].id).assertEqual('3');
    });
  });
}
