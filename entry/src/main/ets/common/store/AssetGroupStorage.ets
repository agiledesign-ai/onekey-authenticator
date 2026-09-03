import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { AssetStorePolicy } from 'otp_core';
import { GroupItem } from '../../model/GroupItem';

export interface GroupStorage {
  loadAll(): GroupItem[];
  save(group: GroupItem): void;
  remove(id: string): void;
  clear(): void;
}

export type GroupAssetQuery = (query: asset.AssetMap) => asset.AssetMap[];

function querySystemAssets(query: asset.AssetMap): asset.AssetMap[] {
  return asset.querySync(query);
}

/** 使用 Asset Store 保存分组记录，禁止系统备份或跨设备同步。 */
export class AssetGroupStorage implements GroupStorage {
  private static readonly PAGE_SIZE: number = 40;
  private static readonly RECORD_TYPE: string = 'securekey-group-v1';
  private static readonly ALIAS_PREFIX: string = 'securekey-group-';
  private readonly queryAssets: GroupAssetQuery;

  constructor(queryAssets: GroupAssetQuery = querySystemAssets) {
    this.queryAssets = queryAssets;
  }

  loadAll(): GroupItem[] {
    const aliases: Uint8Array[] = this.listAliases();
    const groups: GroupItem[] = [];
    for (let i: number = 0; i < aliases.length; i++) {
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.ALIAS, aliases[i]);
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const records: asset.AssetMap[] = this.queryAssets(query);
      const secret = records.length > 0 ? records[0].get(asset.Tag.SECRET) : undefined;
      if (!(secret instanceof Uint8Array)) {
        throw new Error('Asset Store group record does not contain a secret');
      }
      groups.push(JSON.parse(this.decode(secret)) as GroupItem);
    }
    groups.sort((first: GroupItem, second: GroupItem) => {
      if (first.sortIndex !== second.sortIndex) {
        return first.sortIndex - second.sortIndex;
      }
      return first.id < second.id ? -1 : 1;
    });
    return groups;
  }

  save(group: GroupItem): void {
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, this.alias(group.id));
    attributes.set(asset.Tag.SECRET, this.encode(JSON.stringify(group)));
    AssetStorePolicy.applyPersistenceGuards(attributes);
    attributes.set(asset.Tag.DATA_LABEL_CRITICAL_1, this.encode(AssetGroupStorage.RECORD_TYPE));
    asset.addSync(attributes);
  }

  remove(id: string): void {
    this.removeAlias(this.alias(id));
  }

  clear(): void {
    const aliases: Uint8Array[] = this.listAliases();
    for (let i: number = 0; i < aliases.length; i++) {
      this.removeAlias(aliases[i]);
    }
  }

  private listAliases(): Uint8Array[] {
    const aliases: Uint8Array[] = [];
    let offset: number = 0;
    while (true) {
      const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
      query.set(asset.Tag.DATA_LABEL_CRITICAL_1, this.encode(AssetGroupStorage.RECORD_TYPE));
      query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ATTRIBUTES);
      query.set(asset.Tag.RETURN_LIMIT, AssetGroupStorage.PAGE_SIZE);
      query.set(asset.Tag.RETURN_OFFSET, offset);
      let page: asset.AssetMap[];
      try {
        page = this.queryAssets(query);
      } catch (error) {
        const businessError: BusinessError = error as BusinessError;
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
      if (page.length < AssetGroupStorage.PAGE_SIZE) {
        break;
      }
      offset += page.length;
    }
    return aliases;
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
    return this.encode(AssetGroupStorage.ALIAS_PREFIX + id);
  }

  private encode(value: string): Uint8Array {
    return util.TextEncoder.create('utf-8').encodeInto(value);
  }

  private decode(value: Uint8Array): string {
    return util.TextDecoder.create('utf-8').decode(value);
  }
}
