import { AccountItem } from '../../../model/AccountItem';

/** 首页搜索与置顶排序，不读取密钥或验证码。 */
export class AccountListPolicy {
  static filter(accounts: AccountItem[], query: string): AccountItem[] {
    const keyword: string = query.trim().toLowerCase();
    const matched: AccountItem[] = [];
    for (let i: number = 0; i < accounts.length; i++) {
      const account: AccountItem = accounts[i];
      if (keyword.length === 0 || AccountListPolicy.matches(account, keyword)) {
        matched.push(account);
      }
    }
    matched.sort((first: AccountItem, second: AccountItem) => {
      if (first.pinned !== second.pinned) {
        return first.pinned ? -1 : 1;
      }
      if (first.sortIndex !== second.sortIndex) {
        return first.sortIndex - second.sortIndex;
      }
      if (first.id === second.id) {
        return 0;
      }
      return first.id < second.id ? -1 : 1;
    });
    return matched;
  }

  private static matches(account: AccountItem, keyword: string): boolean {
    return account.serviceName.toLowerCase().includes(keyword) ||
      account.accountName.toLowerCase().includes(keyword);
  }
}
