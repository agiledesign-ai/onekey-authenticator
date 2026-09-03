import { ACCOUNT_SCHEMA_VERSION, AccountItem, AccountStorage } from 'otp_core';
import { AccountSecurityPolicy } from '../../features/security/model/AccountSecurityPolicy';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { AssetAccountStorage } from './AssetAccountStorage';
import { CardUpdateService } from '../../features/card/service/CardUpdateService';
import { CloudLocalHooks } from '../../features/cloud/service/CloudLocalHooks';
import { OtpType } from '../../model/OtpType';

export { AccountStorage };

/** 旧版明文数据来源，只能用于一次性迁移。 */
export interface LegacyAccountSource {
  readLegacyJson(): string;
  markMigrated(): void;
}

export interface AccountImportSummary {
  imported: number;
  duplicates: number;
  invalid: number;
}

interface AccountImportPlan {
  accounts: AccountItem[];
  summary: AccountImportSummary;
}

interface LegacyAccountRecord {
  id: string;
  serviceName: string;
  accountName: string;
  badgeColor: string;
  secretKey: string;
}

class PreferencesLegacyAccountSource implements LegacyAccountSource {
  readLegacyJson(): string {
    return PreferencesUtil.getString(AccountStore.LEGACY_KEY, '');
  }

  markMigrated(): void {
    PreferencesUtil.putNumber(AccountStore.STORAGE_VERSION_KEY, AccountStore.STORAGE_VERSION);
    PreferencesUtil.delete(AccountStore.LEGACY_KEY);
  }
}

/**
 * 账号状态管理。生产环境只通过 Asset Store 持久化，Preferences 仅用于旧数据迁移。
 */
export class AccountStore {
  static readonly KEY: string = 'accountList';
  static readonly LEGACY_KEY: string = 'accountList';
  static readonly RECENTLY_ADDED_KEY: string = 'recentlyAddedAccountId';
  static readonly STORAGE_VERSION_KEY: string = 'accountStorageVersion';
  static readonly STORAGE_VERSION: number = 2;
  private static storage: AccountStorage = new AssetAccountStorage();

  /** 初始化安全存储，并在确认新记录可读后删除旧版明文。 */
  static init(
    storage: AccountStorage = new AssetAccountStorage(),
    legacySource: LegacyAccountSource = new PreferencesLegacyAccountSource()
  ): void {
    AccountStore.storage = storage;
    AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, '');
    const legacyJson: string = legacySource.readLegacyJson();
    if (legacyJson.length > 0) {
      const legacyAccounts: LegacyAccountRecord[] = JSON.parse(legacyJson) as LegacyAccountRecord[];
      const migratedAccounts: AccountItem[] = [];
      for (let i: number = 0; i < legacyAccounts.length; i++) {
        const migrated: AccountItem | null = AccountStore.migrateLegacy(legacyAccounts[i], i);
        if (migrated === null) {
          throw new Error('旧版账号包含无效密钥，迁移已停止');
        }
        AccountStore.storage.save(migrated);
        migratedAccounts.push(migrated);
      }
      const verified: AccountItem[] = AccountStore.storage.loadAll();
      AccountStore.verifyMigration(migratedAccounts, verified);
      legacySource.markMigrated();
    }
    AppStorage.setOrCreate(AccountStore.KEY, AccountStore.storage.loadAll());
    AppStorage.setOrCreate('accountsReady', true);
    CardUpdateService.sync(AccountStore.list());
  }

  static list(): AccountItem[] {
    const list: AccountItem[] | undefined = AppStorage.get<AccountItem[]>(AccountStore.KEY);
    return list !== undefined ? list : [];
  }

  static get(id: string): AccountItem | null {
    const accounts: AccountItem[] = AccountStore.list();
    for (let i: number = 0; i < accounts.length; i++) {
      if (accounts[i].id === id) {
        return accounts[i];
      }
    }
    return null;
  }

  static add(item: AccountItem): boolean {
    const normalized: AccountItem | null = AccountStore.normalize(item);
    if (normalized === null || AccountStore.hasDuplicate(normalized, '')) {
      return false;
    }
    try {
      AccountStore.storage.save(normalized);
    } catch {
      return false;
    }
    const next: AccountItem[] = AccountStore.list().concat(normalized);
    AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, normalized.id);
    AppStorage.setOrCreate(AccountStore.KEY, next);
    CardUpdateService.sync(next);
    CloudLocalHooks.onAccountUpserted(normalized);
    return true;
  }

  static update(item: AccountItem): boolean {
    const existing: AccountItem | null = AccountStore.get(item.id);
    if (existing === null) {
      return false;
    }
    const candidate: AccountItem = {
      id: item.id,
      type: item.type,
      serviceName: item.serviceName,
      accountName: item.accountName,
      badgeColor: item.badgeColor,
      secretKey: item.secretKey,
      algorithm: item.algorithm,
      digits: item.digits,
      period: item.period,
      counter: item.counter,
      groupId: item.groupId,
      pinned: item.pinned,
      sortIndex: item.sortIndex,
      createdAt: existing.createdAt,
      updatedAt: Date.now(),
      schemaVersion: ACCOUNT_SCHEMA_VERSION
    };
    const normalized: AccountItem | null = AccountStore.normalize(candidate);
    if (normalized === null ||
      AccountStore.hasDuplicate(normalized, item.id)) {
      return false;
    }
    AccountStore.storage.save(normalized);
    const current: AccountItem[] = AccountStore.list();
    const next: AccountItem[] = current.map((account: AccountItem) => {
      return account.id === normalized.id ? normalized : account;
    });
    AppStorage.setOrCreate(AccountStore.KEY, next);
    CardUpdateService.sync(next);
    CloudLocalHooks.onAccountUpserted(normalized);
    return true;
  }

  static advanceHotp(id: string): boolean {
    const existing: AccountItem | null = AccountStore.get(id);
    if (existing === null || existing.type !== OtpType.HOTP) {
      return false;
    }
    if (existing.counter >= Number.MAX_SAFE_INTEGER) {
      return false;
    }
    const updated: AccountItem = {
      id: existing.id,
      type: existing.type,
      serviceName: existing.serviceName,
      accountName: existing.accountName,
      badgeColor: existing.badgeColor,
      secretKey: existing.secretKey,
      algorithm: existing.algorithm,
      digits: existing.digits,
      period: existing.period,
      counter: existing.counter + 1,
      groupId: existing.groupId,
      pinned: existing.pinned,
      sortIndex: existing.sortIndex,
      createdAt: existing.createdAt,
      updatedAt: Date.now(),
      schemaVersion: existing.schemaVersion
    };
    try {
      AccountStore.storage.save(updated);
    } catch {
      return false;
    }
    const current: AccountItem[] = AccountStore.list();
    const next: AccountItem[] = current.map((account: AccountItem) => {
      return account.id === updated.id ? updated : account;
    });
    AppStorage.setOrCreate(AccountStore.KEY, next);
    CloudLocalHooks.onAccountUpserted(updated);
    return true;
  }

  static setPinned(id: string, pinned: boolean): boolean {
    const existing: AccountItem | null = AccountStore.get(id);
    if (existing === null) {
      return false;
    }
    if (existing.pinned === pinned) {
      return true;
    }
    const updated: AccountItem = {
      id: existing.id,
      type: existing.type,
      serviceName: existing.serviceName,
      accountName: existing.accountName,
      badgeColor: existing.badgeColor,
      secretKey: existing.secretKey,
      algorithm: existing.algorithm,
      digits: existing.digits,
      period: existing.period,
      counter: existing.counter,
      groupId: existing.groupId,
      pinned: pinned,
      sortIndex: existing.sortIndex,
      createdAt: existing.createdAt,
      updatedAt: Date.now(),
      schemaVersion: existing.schemaVersion
    };
    return AccountStore.update(updated);
  }

  static remove(id: string): void {
    AccountStore.storage.remove(id);
    const current: AccountItem[] = AccountStore.list();
    const next: AccountItem[] = current.filter((item: AccountItem) => item.id !== id);
    AppStorage.setOrCreate(AccountStore.KEY, next);
    AccountStore.consumeRecentlyAdded(id);
    CardUpdateService.sync(next);
    CloudLocalHooks.onAccountRemoved(id);
  }

  static clear(): void {
    const current: AccountItem[] = AccountStore.list();
    const ids: string[] = [];
    for (let i: number = 0; i < current.length; i++) {
      ids.push(current[i].id);
    }
    AccountStore.storage.clear();
    AppStorage.setOrCreate(AccountStore.KEY, []);
    AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, '');
    CardUpdateService.sync([]);
    CloudLocalHooks.onAccountsCleared(ids);
  }

  static replaceAll(accounts: AccountItem[]): boolean {
    const previous: AccountItem[] = AccountStore.list();
    try {
      AccountStore.storage.clear();
      for (let i: number = 0; i < accounts.length; i++) {
        AccountStore.storage.save(accounts[i]);
      }
    } catch {
      AccountStore.restore(previous);
      return false;
    }
    AppStorage.setOrCreate(AccountStore.KEY, accounts);
    CardUpdateService.sync(accounts);
    return true;
  }

  private static restore(previous: AccountItem[]): void {
    try {
      AccountStore.storage.clear();
      for (let i: number = 0; i < previous.length; i++) {
        AccountStore.storage.save(previous[i]);
      }
    } catch {
      AppStorage.setOrCreate(AccountStore.KEY, previous);
      CardUpdateService.sync(previous);
      return;
    }
    AppStorage.setOrCreate(AccountStore.KEY, previous);
    CardUpdateService.sync(previous);
  }

  /** 应用锁定时清除 UI 内存中的账号与密钥，不修改 Asset Store。 */
  static unload(): void {
    AppStorage.setOrCreate(AccountStore.KEY, []);
    AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, '');
    AppStorage.setOrCreate('accountsReady', false);
  }

  /**
   * 批量导入前先完成校验与去重；安全存储写入失败时撤销本批新增记录。
   */
  static importAccounts(items: AccountItem[]): AccountImportSummary {
    const plan: AccountImportPlan = AccountStore.planImport(items);
    const current: AccountItem[] = AccountStore.list();
    const planned: AccountItem[] = plan.accounts;

    const savedIds: string[] = [];
    try {
      for (let i: number = 0; i < planned.length; i++) {
        AccountStore.storage.save(planned[i]);
        savedIds.push(planned[i].id);
      }
    } catch {
      for (let i: number = 0; i < savedIds.length; i++) {
        AccountStore.storage.remove(savedIds[i]);
      }
      throw new Error('批量导入写入失败');
    }

    if (planned.length > 0) {
      AppStorage.setOrCreate(AccountStore.KEY, current.concat(planned));
      AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, planned[planned.length - 1].id);
      CardUpdateService.sync(AccountStore.list());
      for (let i: number = 0; i < planned.length; i++) {
        CloudLocalHooks.onAccountUpserted(planned[i]);
      }
    }
    return plan.summary;
  }

  /** 只生成统计结果，不访问安全存储。 */
  static previewImport(items: AccountItem[]): AccountImportSummary {
    return AccountStore.planImport(items).summary;
  }

  static recentlyAddedId(): string {
    const id: string | undefined = AppStorage.get<string>(AccountStore.RECENTLY_ADDED_KEY);
    return id !== undefined ? id : '';
  }

  static consumeRecentlyAdded(id: string): void {
    if (AccountStore.recentlyAddedId() === id) {
      AppStorage.setOrCreate(AccountStore.RECENTLY_ADDED_KEY, '');
    }
  }

  private static normalize(item: AccountItem): AccountItem | null {
    if (item === null ||
      typeof item.id !== 'string' ||
      typeof item.type !== 'string' ||
      typeof item.serviceName !== 'string' ||
      typeof item.accountName !== 'string' ||
      typeof item.badgeColor !== 'string' ||
      typeof item.secretKey !== 'string' ||
      typeof item.algorithm !== 'string' ||
      typeof item.digits !== 'number' ||
      typeof item.period !== 'number' ||
      typeof item.counter !== 'number' ||
      typeof item.groupId !== 'string' ||
      typeof item.pinned !== 'boolean' ||
      typeof item.sortIndex !== 'number' ||
      typeof item.createdAt !== 'number' ||
      typeof item.updatedAt !== 'number' ||
      typeof item.schemaVersion !== 'number') {
      return null;
    }
    const secret: string = AccountSecurityPolicy.normalizeSecret(item.secretKey);
    const serviceName: string = item.serviceName.trim();
    const algorithm: string = item.algorithm.toUpperCase();
    if (secret.length === 0 || serviceName.length === 0 || item.id.length === 0 ||
      !AccountSecurityPolicy.isValidCredential({
        type: item.type,
        secret: secret,
        algorithm: algorithm,
        digits: item.digits,
        period: item.period,
        counter: item.counter
      }) ||
      !Number.isInteger(item.sortIndex) ||
      item.createdAt <= 0 || item.updatedAt <= 0 ||
      item.schemaVersion !== ACCOUNT_SCHEMA_VERSION) {
      return null;
    }
    const normalized: AccountItem = {
      id: item.id,
      type: item.type,
      serviceName: serviceName,
      accountName: item.accountName.trim().length > 0 ? item.accountName.trim() : `${serviceName} 账号`,
      badgeColor: item.badgeColor,
      secretKey: secret,
      algorithm: algorithm,
      digits: item.digits,
      period: item.period,
      counter: item.counter,
      groupId: item.groupId,
      pinned: item.pinned,
      sortIndex: item.sortIndex,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      schemaVersion: item.schemaVersion
    };
    return normalized;
  }

  private static planImport(items: AccountItem[]): AccountImportPlan {
    const current: AccountItem[] = AccountStore.list();
    const planned: AccountItem[] = [];
    let duplicates: number = 0;
    let invalid: number = 0;
    for (let i: number = 0; i < items.length; i++) {
      const normalized: AccountItem | null = AccountStore.normalize(items[i]);
      if (normalized === null) {
        invalid++;
        continue;
      }
      if (AccountStore.hasDuplicateIn(normalized, current.concat(planned), '')) {
        duplicates++;
        continue;
      }
      planned.push(AccountStore.withUniqueImportId(normalized, current.concat(planned), i));
    }
    return {
      accounts: planned,
      summary: { imported: planned.length, duplicates: duplicates, invalid: invalid }
    };
  }

  private static hasDuplicate(candidate: AccountItem, ignoredId: string): boolean {
    return AccountStore.hasDuplicateIn(candidate, AccountStore.list(), ignoredId);
  }

  private static hasDuplicateIn(candidate: AccountItem, accounts: AccountItem[], ignoredId: string): boolean {
    for (let i: number = 0; i < accounts.length; i++) {
      const account: AccountItem = accounts[i];
      if (account.id !== ignoredId && AccountSecurityPolicy.isDuplicate(
        {
          type: candidate.type,
          secret: candidate.secretKey,
          algorithm: candidate.algorithm,
          digits: candidate.digits,
          period: candidate.period,
          counter: candidate.counter
        },
        {
          type: account.type,
          secret: account.secretKey,
          algorithm: account.algorithm,
          digits: account.digits,
          period: account.period,
          counter: account.counter
        }
      )) {
        return true;
      }
    }
    return false;
  }

  private static withUniqueImportId(candidate: AccountItem, accounts: AccountItem[], index: number): AccountItem {
    let idExists: boolean = false;
    for (let i: number = 0; i < accounts.length; i++) {
      if (accounts[i].id === candidate.id) {
        idExists = true;
        break;
      }
    }
    if (!idExists) {
      return candidate;
    }
    return {
      id: `${candidate.id}-import-${Date.now()}-${index}`,
      type: candidate.type,
      serviceName: candidate.serviceName,
      accountName: candidate.accountName,
      badgeColor: candidate.badgeColor,
      secretKey: candidate.secretKey,
      algorithm: candidate.algorithm,
      digits: candidate.digits,
      period: candidate.period,
      counter: candidate.counter,
      groupId: candidate.groupId,
      pinned: candidate.pinned,
      sortIndex: candidate.sortIndex,
      createdAt: candidate.createdAt,
      updatedAt: candidate.updatedAt,
      schemaVersion: candidate.schemaVersion
    };
  }

  private static migrateLegacy(item: LegacyAccountRecord, index: number): AccountItem | null {
    if (item === null ||
      typeof item.id !== 'string' ||
      typeof item.serviceName !== 'string' ||
      typeof item.accountName !== 'string' ||
      typeof item.badgeColor !== 'string' ||
      typeof item.secretKey !== 'string') {
      return null;
    }
    const now: number = Date.now();
    return AccountStore.normalize({
      id: item.id,
      type: OtpType.TOTP,
      serviceName: item.serviceName,
      accountName: item.accountName,
      badgeColor: item.badgeColor,
      secretKey: item.secretKey,
      algorithm: 'SHA1',
      digits: 6,
      period: 30,
      counter: 0,
      groupId: '',
      pinned: false,
      sortIndex: now + index,
      createdAt: now,
      updatedAt: now,
      schemaVersion: ACCOUNT_SCHEMA_VERSION
    });
  }

  private static verifyMigration(legacy: AccountItem[], stored: AccountItem[]): void {
    for (let i: number = 0; i < legacy.length; i++) {
      let matched: boolean = false;
      for (let j: number = 0; j < stored.length; j++) {
        if (legacy[i].id === stored[j].id &&
          AccountSecurityPolicy.normalizeSecret(legacy[i].secretKey) === stored[j].secretKey) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        throw new Error('安全存储验证失败，迁移已停止');
      }
    }
  }
}
