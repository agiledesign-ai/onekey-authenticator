import { AccountItem } from '../../../model/AccountItem';
import { AccountListPolicy } from '../../account/model/AccountListPolicy';

/** 服务卡片令牌选择：全局最多 8 个，按勾选顺序展示。 */
export class CardTokenPolicy {
  static readonly LIMIT: number = 8;

  static normalizeDimension(dimension: string): string {
    if (dimension === '1*2' || dimension === '1') {
      return '1*2';
    }
    if (dimension === '2*4' || dimension === '3') {
      return '2*4';
    }
    return '2*2';
  }

  static maxSlots(dimension: string): number {
    const normalized: string = CardTokenPolicy.normalizeDimension(dimension);
    if (normalized === '1*2') {
      return 1;
    }
    if (normalized === '2*4') {
      return 4;
    }
    return 2;
  }

  static sanitizeIds(ids: string[]): string[] {
    const result: string[] = [];
    for (let i: number = 0; i < ids.length; i++) {
      const id: string = ids[i].trim();
      if (id.length === 0 || result.indexOf(id) >= 0) {
        continue;
      }
      result.push(id);
      if (result.length >= CardTokenPolicy.LIMIT) {
        break;
      }
    }
    return result;
  }

  static toggle(id: string, selected: string[], allowedIds: string[]): string[] {
    const current: string[] = CardTokenPolicy.sanitizeIds(selected);
    const allowed: string[] = [];
    for (let i: number = 0; i < current.length; i++) {
      if (allowedIds.indexOf(current[i]) >= 0) {
        allowed.push(current[i]);
      }
    }
    if (allowedIds.indexOf(id) < 0) {
      return allowed;
    }
    const index: number = allowed.indexOf(id);
    if (index >= 0) {
      const next: string[] = [];
      for (let i: number = 0; i < allowed.length; i++) {
        if (allowed[i] !== id) {
          next.push(allowed[i]);
        }
      }
      return next;
    }
    if (allowed.length >= CardTokenPolicy.LIMIT) {
      return allowed;
    }
    return allowed.concat([id]);
  }

  static resolveAccounts(accounts: AccountItem[], selectedIds: string[]): AccountItem[] {
    const ordered: AccountItem[] = AccountListPolicy.filter(accounts, '');
    const selected: string[] = CardTokenPolicy.sanitizeIds(selectedIds);
    const resolved: AccountItem[] = [];
    for (let i: number = 0; i < selected.length; i++) {
      const match: AccountItem | null = CardTokenPolicy.find(ordered, selected[i]);
      if (match !== null) {
        resolved.push(match);
      }
    }
    if (selected.length > 0) {
      return resolved;
    }
    const fallback: AccountItem[] = [];
    for (let i: number = 0; i < ordered.length && fallback.length < CardTokenPolicy.LIMIT; i++) {
      fallback.push(ordered[i]);
    }
    return fallback;
  }

  private static find(accounts: AccountItem[], id: string): AccountItem | null {
    for (let i: number = 0; i < accounts.length; i++) {
      if (accounts[i].id === id) {
        return accounts[i];
      }
    }
    return null;
  }
}
