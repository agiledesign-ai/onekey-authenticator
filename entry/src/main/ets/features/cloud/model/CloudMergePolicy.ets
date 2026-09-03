import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';

/** 本机或云端的账号与分组快照。 */
export interface CloudMergeSnapshot {
  accounts: AccountItem[];
  groups: GroupItem[];
}

/**
 * 按 id 安全合并本机与云端快照。无 I/O。
 */
export class CloudMergePolicy {
  static merge(local: CloudMergeSnapshot, cloud: CloudMergeSnapshot): CloudMergeSnapshot {
    const groups: GroupItem[] = CloudMergePolicy.mergeGroups(local.groups, cloud.groups);
    const groupIds: string[] = [];
    for (let i: number = 0; i < groups.length; i++) {
      groupIds.push(groups[i].id);
    }
    const mergedAccounts: AccountItem[] = CloudMergePolicy.mergeAccounts(local.accounts, cloud.accounts);
    const accounts: AccountItem[] = [];
    for (let i: number = 0; i < mergedAccounts.length; i++) {
      const item: AccountItem = mergedAccounts[i];
      if (item.groupId.length > 0 && groupIds.indexOf(item.groupId) < 0) {
        accounts.push(CloudMergePolicy.withGroupId(item, ''));
      } else {
        accounts.push(item);
      }
    }
    return { accounts: accounts, groups: groups };
  }

  private static mergeAccounts(localItems: AccountItem[], cloudItems: AccountItem[]): AccountItem[] {
    const result: AccountItem[] = [];
    const seen: string[] = [];
    for (let i: number = 0; i < localItems.length; i++) {
      const localItem: AccountItem = localItems[i];
      const cloudItem: AccountItem | null = CloudMergePolicy.findAccount(cloudItems, localItem.id);
      if (cloudItem === null || localItem.updatedAt >= cloudItem.updatedAt) {
        result.push(localItem);
      } else {
        result.push(cloudItem);
      }
      seen.push(localItem.id);
    }
    for (let i: number = 0; i < cloudItems.length; i++) {
      if (seen.indexOf(cloudItems[i].id) < 0) {
        result.push(cloudItems[i]);
      }
    }
    return result;
  }

  private static mergeGroups(localItems: GroupItem[], cloudItems: GroupItem[]): GroupItem[] {
    const result: GroupItem[] = [];
    const seen: string[] = [];
    for (let i: number = 0; i < localItems.length; i++) {
      const localItem: GroupItem = localItems[i];
      const cloudItem: GroupItem | null = CloudMergePolicy.findGroup(cloudItems, localItem.id);
      if (cloudItem === null || localItem.updatedAt >= cloudItem.updatedAt) {
        result.push(localItem);
      } else {
        result.push(cloudItem);
      }
      seen.push(localItem.id);
    }
    for (let i: number = 0; i < cloudItems.length; i++) {
      if (seen.indexOf(cloudItems[i].id) < 0) {
        result.push(cloudItems[i]);
      }
    }
    return result;
  }

  private static findAccount(items: AccountItem[], id: string): AccountItem | null {
    for (let i: number = 0; i < items.length; i++) {
      if (items[i].id === id) {
        return items[i];
      }
    }
    return null;
  }

  private static findGroup(items: GroupItem[], id: string): GroupItem | null {
    for (let i: number = 0; i < items.length; i++) {
      if (items[i].id === id) {
        return items[i];
      }
    }
    return null;
  }

  private static withGroupId(account: AccountItem, groupId: string): AccountItem {
    return {
      id: account.id,
      type: account.type,
      serviceName: account.serviceName,
      accountName: account.accountName,
      badgeColor: account.badgeColor,
      secretKey: account.secretKey,
      algorithm: account.algorithm,
      digits: account.digits,
      period: account.period,
      counter: account.counter,
      groupId: groupId,
      pinned: account.pinned,
      sortIndex: account.sortIndex,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      schemaVersion: account.schemaVersion
    };
  }
}
