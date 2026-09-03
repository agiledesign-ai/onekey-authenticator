import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { AccountItem } from '../model/AccountItem';
import { AccountStorage } from './AccountStorage';
import { AssetStorePolicy } from './AssetStorePolicy';

export type AssetQuery = (query: asset.AssetMap) => asset.AssetMap[];

function querySystemAssets(query: asset.AssetMap): asset.AssetMap[] {
  return asset.querySync(query);
}

/** 使用系统 Asset Store 保存完整账号记录，禁止系统备份或跨设备同步。 */
export class AssetAccountStorage implements AccountStorage {
  private static readonly PAGE_SIZE: number = 40;
  private static readonly RECORD_TYPE: string = 'securekey-account-v2';
  private static readonly ALIAS_PREFIX: string = 'securekey-account-';
  private readonly queryAssets: AssetQuery;

  constructor(queryAssets: AssetQuery = querySystemAssets) {
    this.queryAssets = queryAssets;
  }

  loadAll(): AccountItem[] {
    const aliases: Uint8Array[] = this.listAliases();
    const accounts: AccountItem[] = [];
    for (let i: number = 0; i < aliases.length; i++) {
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.ALIAS, aliases[i]);
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const records: asset.AssetMap[] = this.queryAssets(query);
      const secret = records[0]?.get(asset.Tag.SECRET);
      if (!(secret instanceof Uint8Array)) {
        throw new Error('Asset Store record does not contain a secret');
      }
      accounts.push(JSON.parse(this.decode(secret)) as AccountItem);
    }
    accounts.sort((first: AccountItem, second: AccountItem) => {
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
    return accounts;
  }

  /** 批量查询只能返回属性；密文由 loadAll 再按别名单条读取。 */
  private listAliases(): Uint8Array[] {
    const aliases: Uint8Array[] = [];
    let offset: number = 0;
    while (true) {
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.DATA_LABEL_CRITICAL_1, this.encode(AssetAccountStorage.RECORD_TYPE));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ATTRIBUTES);
      query.set(asset.Tag.RETURN_LIMIT, AssetAccountStorage.PAGE_SIZE);
      query.set(asset.Tag.RETURN_OFFSET, offset);
      let page: asset.AssetMap[];
      try {
        page = this.queryAssets(query);
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
        // Asset Store uses NOT_FOUND for both an empty store and the end of pagination.
        if (businessError.code === asset.ErrorCode.NOT_FOUND) {
          break;
        }
        throw error as Error;
      }
      for (let i: number = 0; i < page.length; i++) {
        const alias = page[i].get(asset.Tag.ALIAS);
        if (alias instanceof Uint8Array) {
          aliases.push(alias);
        }
      }
      if (page.length < AssetAccountStorage.PAGE_SIZE) {
        break;
      }
      offset += page.length;
    }
    return aliases;
  }

  save(account: AccountItem): void {
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, this.alias(account.id));
    attributes.set(asset.Tag.SECRET, this.encode(JSON.stringify(account)));
    AssetStorePolicy.applyPersistenceGuards(attributes);
    attributes.set(asset.Tag.DATA_LABEL_CRITICAL_1, this.encode(AssetAccountStorage.RECORD_TYPE));
    asset.addSync(attributes);
  }

  remove(id: string): void {
    this.removeAlias(this.alias(id));
  }

  /** remove 只接受 ALIAS，不能用 DATA_LABEL_CRITICAL_1 批量删除。 */
  clear(): void {
    const aliases: Uint8Array[] = this.listAliases();
    for (let i: number = 0; i < aliases.length; i++) {
      this.removeAlias(aliases[i]);
    }
  }

  private removeAlias(alias: Uint8Array): void {
    const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, alias);
    try {
      asset.removeSync(query);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      if (businessError.code === asset.ErrorCode.NOT_FOUND) {
        return;
      }
      throw error as Error;
    }
  }

  private alias(id: string): Uint8Array {
    return this.encode(AssetAccountStorage.ALIAS_PREFIX + id);
  }

  private encode(value: string): Uint8Array {
    return util.TextEncoder.create('utf-8').encodeInto(value);
  }

  private decode(value: Uint8Array): string {
    return util.TextDecoder.create('utf-8').decode(value);
  }
}
