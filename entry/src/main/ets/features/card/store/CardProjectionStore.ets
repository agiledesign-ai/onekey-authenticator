import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountItem } from '../../../model/AccountItem';
import { CardProjection, CardProjectionPolicy } from '../model/CardProjection';

export interface StringMapStore {
  get(key: string): string;
  set(key: string, value: string): boolean;
}

export class MemoryStringMapStore implements StringMapStore {
  private values: Map<string, string> = new Map<string, string>();

  get(key: string): string {
    if (!this.values.has(key)) {
      return '';
    }
    return this.values.get(key) as string;
  }

  set(key: string, value: string): boolean {
    this.values.set(key, value);
    return true;
  }
}

export class PreferencesStringMapStore implements StringMapStore {
  private context: common.Context;
  private storeName: string;

  constructor(context: common.Context, storeName: string) {
    this.context = context;
    this.storeName = storeName;
  }

  get(key: string): string {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: this.storeName });
      const value: string | number | boolean = store.getSync(key, '') as string;
      return typeof value === 'string' ? value : '';
    } catch {
      return '';
    }
  }

  set(key: string, value: string): boolean {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: this.storeName });
      store.putSync(key, value);
      store.flushSync();
      return true;
    } catch {
      return false;
    }
  }
}

/** 卡片投影存储。只写服务名和掩码账号名。 */
export class CardProjectionStore {
  private static readonly KEY: string = 'projections';
  private store: StringMapStore;

  constructor(store: StringMapStore) {
    this.store = store;
  }

  rebuild(accounts: AccountItem[]): void {
    const projections: CardProjection[] = [];
    for (let i: number = 0; i < accounts.length; i++) {
      const projection: CardProjection | null = CardProjectionPolicy.fromAccount(accounts[i]);
      if (projection !== null) {
        projections.push(projection);
      }
    }
    this.store.set(CardProjectionStore.KEY, JSON.stringify(projections));
  }

  list(): CardProjection[] {
    const raw: string = this.store.get(CardProjectionStore.KEY);
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: Object = JSON.parse(raw) as Object;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const items: Object[] = parsed as Object[];
      const result: CardProjection[] = [];
      for (let i: number = 0; i < items.length; i++) {
        const item = items[i] as CardProjection;
        if (typeof item.accountId === 'string' && item.accountId.length > 0) {
          result.push({
            accountId: item.accountId,
            serviceName: typeof item.serviceName === 'string' ? item.serviceName : '',
            maskedAccountName: typeof item.maskedAccountName === 'string' ? item.maskedAccountName : '•••',
            badgeColor: typeof item.badgeColor === 'string' ? item.badgeColor : '#C4C4C4',
            exists: item.exists === true
          });
        }
      }
      return result;
    } catch {
      return [];
    }
  }

  get(accountId: string): CardProjection {
    const projections: CardProjection[] = this.list();
    for (let i: number = 0; i < projections.length; i++) {
      if (projections[i].accountId === accountId) {
        return projections[i];
      }
    }
    return CardProjectionPolicy.fromMissing(accountId);
  }
}
