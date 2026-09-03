import { describe, expect, it } from '@ohos/hypium';
import { ExportSelectionPolicy } from '../main/ets/features/backup/model/ExportSelectionPolicy';
import { AccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';

function account(id: string, serviceName: string, pinned: boolean, sortIndex: number): AccountItem {
  return {
    id: id,
    type: OtpType.TOTP,
    serviceName: serviceName,
    accountName: `${serviceName} user`,
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

export default function exportSelectionPolicyTest() {
  describe('ExportSelectionPolicy', () => {
    it('keeps pinned accounts first and drops unknown ids', 0, () => {
      const accounts: AccountItem[] = [
        account('a', 'GitHub', false, 1),
        account('b', 'Steam', true, 2),
        account('c', 'VPN', false, 3)
      ];
      const normalized: string[] = ExportSelectionPolicy.normalize(['c', 'missing', 'b', 'a'], accounts);
      expect(normalized.length).assertEqual(3);
      expect(normalized[0]).assertEqual('b');
      expect(normalized[1]).assertEqual('a');
      expect(normalized[2]).assertEqual('c');
    });

    it('toggles selection without exporting unselected accounts', 0, () => {
      const accounts: AccountItem[] = [
        account('a', 'GitHub', false, 1),
        account('b', 'Steam', true, 2)
      ];
      const selected: string[] = ExportSelectionPolicy.setSelected('a', true, [], accounts);
      expect(ExportSelectionPolicy.pickAccounts(accounts, selected).length).assertEqual(1);
      expect(ExportSelectionPolicy.pickAccounts(accounts, selected)[0].id).assertEqual('a');

      const cleared: string[] = ExportSelectionPolicy.setSelected('a', false, selected, accounts);
      expect(ExportSelectionPolicy.pickAccounts(accounts, cleared).length).assertEqual(0);
      expect(ExportSelectionPolicy.canExport(accounts.length, cleared.length)).assertEqual(false);
      expect(ExportSelectionPolicy.helper(accounts.length, 0)).assertEqual('请勾选要导出的账号');
    });

    it('selects every visible account by default and blocks empty lists', 0, () => {
      const accounts: AccountItem[] = [
        account('a', 'GitHub', false, 1),
        account('b', 'Steam', true, 2)
      ];
      const selected: string[] = ExportSelectionPolicy.selectAll(accounts);
      expect(selected.length).assertEqual(2);
      expect(ExportSelectionPolicy.isAllSelected(selected, accounts)).assertTrue();
      expect(ExportSelectionPolicy.canExport(2, 2)).assertTrue();
      expect(ExportSelectionPolicy.canExport(0, 0)).assertEqual(false);
      expect(ExportSelectionPolicy.helper(0, 0)).assertEqual('暂无账号可导出');
      expect(ExportSelectionPolicy.helper(2, 2)).assertEqual('');
    });
  });
}
