import { CloudLocalHooks } from '../../features/cloud/service/CloudLocalHooks';
import { createGroupItem, GroupItem, isSameGroupName } from '../../model/GroupItem';
import { AssetGroupStorage, GroupStorage } from './AssetGroupStorage';

export { GroupStorage };

export interface GroupRemovalHooks {
  ungroup: (groupId: string) => boolean;
}

/**
 * 本机分组真源。与账号一样走 Asset Store，默认不同步到系统云。
 */
export class GroupStore {
  static readonly KEY: string = 'groupList';
  private static storage: GroupStorage = new AssetGroupStorage();

  static init(storage: GroupStorage = new AssetGroupStorage()): void {
    GroupStore.storage = storage;
    AppStorage.setOrCreate(GroupStore.KEY, GroupStore.storage.loadAll());
  }

  static list(): GroupItem[] {
    const list: GroupItem[] | undefined = AppStorage.get<GroupItem[]>(GroupStore.KEY);
    return list !== undefined ? list : [];
  }

  static get(id: string): GroupItem | null {
    const groups: GroupItem[] = GroupStore.list();
    for (let i: number = 0; i < groups.length; i++) {
      if (groups[i].id === id) {
        return groups[i];
      }
    }
    return null;
  }

  static add(item: GroupItem): boolean {
    const normalized: GroupItem | null = GroupStore.normalize(item);
    if (normalized === null || GroupStore.hasName(normalized.name, '')) {
      return false;
    }
    try {
      GroupStore.storage.save(normalized);
    } catch {
      return false;
    }
    AppStorage.setOrCreate(GroupStore.KEY, GroupStore.list().concat(normalized));
    CloudLocalHooks.onGroupUpserted(normalized);
    return true;
  }

  static update(item: GroupItem): boolean {
    const existing: GroupItem | null = GroupStore.get(item.id);
    if (existing === null) {
      return false;
    }
    const normalized: GroupItem | null = GroupStore.normalize({
      id: item.id,
      name: item.name,
      sortIndex: item.sortIndex,
      createdAt: existing.createdAt,
      updatedAt: item.updatedAt
    });
    if (normalized === null || GroupStore.hasName(normalized.name, item.id)) {
      return false;
    }
    try {
      GroupStore.storage.save(normalized);
    } catch {
      return false;
    }
    const next: GroupItem[] = GroupStore.list().map((group: GroupItem) => {
      return group.id === normalized.id ? normalized : group;
    });
    AppStorage.setOrCreate(GroupStore.KEY, next);
    CloudLocalHooks.onGroupUpserted(normalized);
    return true;
  }

  static remove(id: string, hooks: GroupRemovalHooks | null = null): boolean {
    const existing: GroupItem | null = GroupStore.get(id);
    if (existing === null) {
      return true;
    }
    if (hooks !== null && !hooks.ungroup(id)) {
      return false;
    }
    try {
      GroupStore.storage.remove(id);
    } catch {
      return false;
    }
    AppStorage.setOrCreate(GroupStore.KEY, GroupStore.list().filter((item: GroupItem) => item.id !== id));
    return true;
  }

  static replaceAll(groups: GroupItem[]): boolean {
    const previous: GroupItem[] = GroupStore.list();
    const normalized: GroupItem[] = [];
    for (let i: number = 0; i < groups.length; i++) {
      const item: GroupItem | null = GroupStore.normalize(groups[i]);
      if (item === null) {
        return false;
      }
      normalized.push(item);
    }
    try {
      GroupStore.storage.clear();
      for (let i: number = 0; i < normalized.length; i++) {
        GroupStore.storage.save(normalized[i]);
      }
    } catch {
      GroupStore.restore(previous);
      return false;
    }
    AppStorage.setOrCreate(GroupStore.KEY, normalized);
    return true;
  }

  private static restore(previous: GroupItem[]): void {
    try {
      GroupStore.storage.clear();
      for (let i: number = 0; i < previous.length; i++) {
        GroupStore.storage.save(previous[i]);
      }
    } catch {
      AppStorage.setOrCreate(GroupStore.KEY, previous);
      return;
    }
    AppStorage.setOrCreate(GroupStore.KEY, previous);
  }

  private static hasName(name: string, ignoredId: string): boolean {
    const groups: GroupItem[] = GroupStore.list();
    for (let i: number = 0; i < groups.length; i++) {
      if (groups[i].id !== ignoredId && isSameGroupName(groups[i].name, name)) {
        return true;
      }
    }
    return false;
  }

  private static normalize(item: GroupItem): GroupItem | null {
    const createdAt: number = item.createdAt > 0 ? item.createdAt : Date.now();
    const created: GroupItem | null = createGroupItem(item.id, item.name, item.sortIndex, createdAt);
    if (created === null) {
      return null;
    }
    return {
      id: created.id,
      name: created.name,
      sortIndex: created.sortIndex,
      createdAt: created.createdAt,
      updatedAt: item.updatedAt > 0 ? item.updatedAt : created.updatedAt
    };
  }
}
