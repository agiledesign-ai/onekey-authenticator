import { AccountItem } from '../../../model/AccountItem';
import { AccountListPolicy } from '../../account/model/AccountListPolicy';

/** 导出勾选规则：只处理账号 ID，不读取密钥或验证码。 */
export class ExportSelectionPolicy {
  static visibleAccounts(accounts: AccountItem[]): AccountItem[] {
    return AccountListPolicy.filter(accounts, '');
  }

  static allIds(accounts: AccountItem[]): string[] {
    const visible: AccountItem[] = ExportSelectionPolicy.visibleAccounts(accounts);
    const ids: string[] = [];
    for (let i: number = 0; i < visible.length; i++) {
      ids.push(visible[i].id);
    }
    return ids;
  }

  static normalize(selected: string[], accounts: AccountItem[]): string[] {
    const allowed: string[] = ExportSelectionPolicy.allIds(accounts);
    const result: string[] = [];
    for (let i: number = 0; i < allowed.length; i++) {
      if (selected.indexOf(allowed[i]) >= 0) {
        result.push(allowed[i]);
      }
    }
    return result;
  }

  static setSelected(
    id: string,
    checked: boolean,
    selected: string[],
    accounts: AccountItem[]
  ): string[] {
    const current: string[] = ExportSelectionPolicy.normalize(selected, accounts);
    const index: number = current.indexOf(id);
    if (checked) {
      if (index >= 0) {
        return current;
      }
      return ExportSelectionPolicy.normalize(current.concat([id]), accounts);
    }
    if (index < 0) {
      return current;
    }
    const next: string[] = [];
    for (let i: number = 0; i < current.length; i++) {
      if (current[i] !== id) {
        next.push(current[i]);
      }
    }
    return next;
  }

  static selectAll(accounts: AccountItem[]): string[] {
    return ExportSelectionPolicy.allIds(accounts);
  }

  static isAllSelected(selected: string[], accounts: AccountItem[]): boolean {
    const ids: string[] = ExportSelectionPolicy.allIds(accounts);
    return ids.length > 0 &&
      ExportSelectionPolicy.normalize(selected, accounts).length === ids.length;
  }

  static canExport(accountCount: number, selectedCount: number): boolean {
    return accountCount > 0 && selectedCount > 0;
  }

  static helper(accountCount: number, selectedCount: number): string {
    if (accountCount === 0) {
      return '暂无账号可导出';
    }
    if (selectedCount === 0) {
      return '请勾选要导出的账号';
    }
    return '';
  }

  static pickAccounts(accounts: AccountItem[], selected: string[]): AccountItem[] {
    const ids: string[] = ExportSelectionPolicy.normalize(selected, accounts);
    const visible: AccountItem[] = ExportSelectionPolicy.visibleAccounts(accounts);
    const picked: AccountItem[] = [];
    for (let i: number = 0; i < visible.length; i++) {
      if (ids.indexOf(visible[i].id) >= 0) {
        picked.push(visible[i]);
      }
    }
    return picked;
  }
}
