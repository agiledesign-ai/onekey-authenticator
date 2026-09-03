import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';

/** 本机存储通知云同步的钩子，避免 AccountStore 与 Runtime 循环依赖。 */
export class CloudLocalHooks {
  static onAccountUpserted: (item: AccountItem) => void = (_item: AccountItem): void => {};
  static onAccountRemoved: (id: string) => void = (_id: string): void => {};
  static onAccountsCleared: (ids: string[]) => void = (_ids: string[]): void => {};
  static onGroupUpserted: (item: GroupItem) => void = (_item: GroupItem): void => {};
}
