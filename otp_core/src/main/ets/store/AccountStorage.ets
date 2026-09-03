import { AccountItem } from '../model/AccountItem';

/** 账号加密存储边界，供手机 AccountStore 与手表仓库共用。 */
export interface AccountStorage {
  loadAll(): AccountItem[];
  save(account: AccountItem): void;
  remove(id: string): void;
  clear(): void;
}
