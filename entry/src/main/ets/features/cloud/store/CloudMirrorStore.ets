import { common } from '@kit.AbilityKit';
import { cloudData, relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';
import { Log } from '../../../common/utils/LogUtil';
import { CloudAccountRow, CloudGroupRow, CloudRecordCodec } from '../model/CloudRecordCodec';
import { CloudMergeSnapshot } from '../model/CloudMergePolicy';
import { CloudSyncState } from '../model/CloudSyncState';
import { CloudMirrorGateway } from '../service/CloudSyncCoordinator';

// Cloud container is named "securekeyAccounts" in AppGallery Connect;
// ArkData maps it from the local database name without the .db suffix.
const STORE_NAME: string = 'securekeyAccounts.db';
const ACCOUNT_TABLE: string = 'accounts';
const GROUP_TABLE: string = 'groups';
const CLOUD_SYNC_TIMEOUT_MS: number = 120000;

const SQL_CREATE_ACCOUNTS: string = `
  CREATE TABLE IF NOT EXISTS ${ACCOUNT_TABLE} (
    id TEXT PRIMARY KEY,
    type TEXT,
    serviceName TEXT,
    accountName TEXT,
    secretKey TEXT,
    algorithm TEXT,
    digits INTEGER,
    period INTEGER,
    counter INTEGER,
    groupId TEXT,
    pinned INTEGER,
    sortIndex INTEGER,
    createdAt INTEGER,
    updatedAt INTEGER,
    schemaVersion INTEGER,
    badgeColor TEXT
  )
`;

const SQL_CREATE_GROUPS: string = `
  CREATE TABLE IF NOT EXISTS ${GROUP_TABLE} (
    id TEXT PRIMARY KEY,
    name TEXT,
    sortIndex INTEGER,
    createdAt INTEGER,
    updatedAt INTEGER
  )
`;

/**
 * ArkData RDB 云镜像。不是本机真源，只在用户开启云空间后写入。
 */
export class CloudMirrorStore implements CloudMirrorGateway {
  private readonly context: common.UIAbilityContext;
  private store: relationalStore.RdbStore | null = null;
  private configuredAutoSync: boolean | null = null;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async configure(autoSync: boolean): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      await CloudMirrorStore.configureNetworkStrategy();
      if (this.configuredAutoSync !== autoSync) {
        await store.setDistributedTables(
          [ACCOUNT_TABLE, GROUP_TABLE],
          relationalStore.DistributedType.DISTRIBUTED_CLOUD,
          { autoSync: autoSync }
        );
        this.configuredAutoSync = autoSync;
      }
      return true;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      Log.e(`CloudMirrorStore.configure failed ${businessError.code}`);
      return false;
    }
  }

  async stageAll(accounts: AccountItem[], groups: GroupItem[]): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      for (let i: number = 0; i < accounts.length; i++) {
        await CloudMirrorStore.upsertAccount(store, CloudRecordCodec.accountToRow(accounts[i]));
      }
      for (let i: number = 0; i < groups.length; i++) {
        await CloudMirrorStore.upsertGroup(store, CloudRecordCodec.groupToRow(groups[i]));
      }
      return true;
    } catch (error) {
      Log.e('CloudMirrorStore.stageAll failed');
      return false;
    }
  }

  async stageAccount(item: AccountItem): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      await CloudMirrorStore.upsertAccount(store, CloudRecordCodec.accountToRow(item));
      return true;
    } catch {
      Log.e('CloudMirrorStore.stageAccount failed');
      return false;
    }
  }

  async deleteAccount(id: string): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      await store.delete(new relationalStore.RdbPredicates(ACCOUNT_TABLE).equalTo('id', id));
      return true;
    } catch {
      Log.e('CloudMirrorStore.deleteAccount failed');
      return false;
    }
  }

  async deleteAccounts(ids: string[]): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      for (let i: number = 0; i < ids.length; i++) {
        await store.delete(new relationalStore.RdbPredicates(ACCOUNT_TABLE).equalTo('id', ids[i]));
      }
      return true;
    } catch {
      Log.e('CloudMirrorStore.deleteAccounts failed');
      return false;
    }
  }

  async push(listener: (state: CloudSyncState) => void): Promise<boolean> {
    return await this.sync(relationalStore.SyncMode.SYNC_MODE_NATIVE_FIRST, listener);
  }

  async pull(listener: (state: CloudSyncState) => void): Promise<CloudMergeSnapshot | null> {
    if (!await this.sync(relationalStore.SyncMode.SYNC_MODE_CLOUD_FIRST, listener)) {
      return null;
    }
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      return {
        accounts: await CloudMirrorStore.readAccounts(store),
        groups: await CloudMirrorStore.readGroups(store)
      };
    } catch {
      Log.e('CloudMirrorStore.pull read failed');
      return null;
    }
  }

  private async getStore(): Promise<relationalStore.RdbStore> {
    if (this.store !== null) {
      return this.store;
    }
    const config: relationalStore.StoreConfig = {
      name: STORE_NAME,
      securityLevel: relationalStore.SecurityLevel.S3,
      autoCleanDirtyData: true
    };
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(this.context, config);
    await store.executeSql(SQL_CREATE_ACCOUNTS);
    await store.executeSql(SQL_CREATE_GROUPS);
    this.store = store;
    return store;
  }

  private async sync(
    mode: relationalStore.SyncMode,
    listener: (state: CloudSyncState) => void
  ): Promise<boolean> {
    try {
      const store: relationalStore.RdbStore = await this.getStore();
      try {
        await store.cleanDirtyData(ACCOUNT_TABLE);
        await store.cleanDirtyData(GROUP_TABLE);
      } catch {
        Log.e('CloudMirrorStore.cleanDirtyData failed');
      }
      return await new Promise<boolean>((resolve: (value: boolean) => void) => {
        let settled: boolean = false;
        let timeoutId: number = -1;
        const finish = (success: boolean): void => {
          if (!settled) {
            settled = true;
            if (timeoutId >= 0) {
              clearTimeout(timeoutId);
            }
            resolve(success);
          }
        };
        timeoutId = setTimeout((): void => {
          Log.e(`CloudMirrorStore.sync timed out mode=${mode}`);
          listener({ status: '同步超时', finished: true, success: false });
          finish(false);
        }, CLOUD_SYNC_TIMEOUT_MS);
        store.cloudSync(mode, [ACCOUNT_TABLE, GROUP_TABLE], (details: relationalStore.ProgressDetails): void => {
          Log.i(`CloudMirrorStore.sync progress schedule=${details.schedule} code=${details.code}`);
          const tableDetails = details.details[ACCOUNT_TABLE];
          if (tableDetails) {
            Log.i(`CloudMirrorStore.sync statistics upload=${JSON.stringify(tableDetails.upload)} ` +
              `download=${JSON.stringify(tableDetails.download)}`);
          }
          const state: CloudSyncState = CloudMirrorStore.toState(details);
          listener(state);
          if (state.finished) {
            finish(state.success);
          }
        }).catch((error: BusinessError): void => {
          Log.e(`CloudMirrorStore.sync request failed ${error.code} ${error.message}`);
          listener({ status: `同步失败 (${error.code})`, finished: true, success: false });
          finish(false);
        });
      });
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      Log.e(`CloudMirrorStore.sync failed ${businessError.code}`);
      listener({ status: '同步失败', finished: true, success: false });
      return false;
    }
  }

  private static async configureNetworkStrategy(): Promise<void> {
    try {
      await cloudData.setCloudStrategy(cloudData.StrategyType.NETWORK, [
        cloudData.NetWorkStrategy.WIFI,
        cloudData.NetWorkStrategy.CELLULAR
      ]);
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;
      Log.e(`CloudMirrorStore.setCloudStrategy failed ${businessError.code}`);
    }
  }

  private static async upsertAccount(store: relationalStore.RdbStore, row: CloudAccountRow): Promise<void> {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = row.id;
    bucket['type'] = row.type;
    bucket['serviceName'] = row.serviceName;
    bucket['accountName'] = row.accountName;
    bucket['secretKey'] = row.secretKey;
    bucket['algorithm'] = row.algorithm;
    bucket['digits'] = row.digits;
    bucket['period'] = row.period;
    bucket['counter'] = row.counter;
    bucket['groupId'] = row.groupId;
    bucket['pinned'] = row.pinned;
    bucket['sortIndex'] = row.sortIndex;
    bucket['createdAt'] = row.createdAt;
    bucket['updatedAt'] = row.updatedAt;
    bucket['schemaVersion'] = row.schemaVersion;
    bucket['badgeColor'] = row.badgeColor;
    const predicates = new relationalStore.RdbPredicates(ACCOUNT_TABLE).equalTo('id', row.id);
    const changed: number = await store.update(bucket, predicates);
    if (changed <= 0) {
      await store.insert(ACCOUNT_TABLE, bucket);
    }
  }

  private static async upsertGroup(store: relationalStore.RdbStore, row: CloudGroupRow): Promise<void> {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['id'] = row.id;
    bucket['name'] = row.name;
    bucket['sortIndex'] = row.sortIndex;
    bucket['createdAt'] = row.createdAt;
    bucket['updatedAt'] = row.updatedAt;
    const predicates = new relationalStore.RdbPredicates(GROUP_TABLE).equalTo('id', row.id);
    const changed: number = await store.update(bucket, predicates);
    if (changed <= 0) {
      await store.insert(GROUP_TABLE, bucket);
    }
  }

  private static async readAccounts(store: relationalStore.RdbStore): Promise<AccountItem[]> {
    const rows: AccountItem[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(`SELECT * FROM ${ACCOUNT_TABLE}`);
      while (resultSet.goToNextRow()) {
        rows.push(CloudRecordCodec.rowToAccount({
          id: CloudMirrorStore.rowString(resultSet, 'id'),
          type: CloudMirrorStore.rowString(resultSet, 'type'),
          serviceName: CloudMirrorStore.rowString(resultSet, 'serviceName'),
          accountName: CloudMirrorStore.rowString(resultSet, 'accountName'),
          secretKey: CloudMirrorStore.rowString(resultSet, 'secretKey'),
          algorithm: CloudMirrorStore.rowString(resultSet, 'algorithm'),
          digits: CloudMirrorStore.rowLong(resultSet, 'digits'),
          period: CloudMirrorStore.rowLong(resultSet, 'period'),
          counter: CloudMirrorStore.rowLong(resultSet, 'counter'),
          groupId: CloudMirrorStore.rowString(resultSet, 'groupId'),
          pinned: CloudMirrorStore.rowLong(resultSet, 'pinned'),
          sortIndex: CloudMirrorStore.rowLong(resultSet, 'sortIndex'),
          createdAt: CloudMirrorStore.rowLong(resultSet, 'createdAt'),
          updatedAt: CloudMirrorStore.rowLong(resultSet, 'updatedAt'),
          schemaVersion: CloudMirrorStore.rowLong(resultSet, 'schemaVersion'),
          badgeColor: CloudMirrorStore.rowString(resultSet, 'badgeColor')
        }));
      }
    } finally {
      if (resultSet !== null) {
        resultSet.close();
      }
    }
    return rows;
  }

  private static async readGroups(store: relationalStore.RdbStore): Promise<GroupItem[]> {
    const rows: GroupItem[] = [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.querySql(`SELECT * FROM ${GROUP_TABLE}`);
      while (resultSet.goToNextRow()) {
        rows.push(CloudRecordCodec.rowToGroup({
          id: CloudMirrorStore.rowString(resultSet, 'id'),
          name: CloudMirrorStore.rowString(resultSet, 'name'),
          sortIndex: CloudMirrorStore.rowLong(resultSet, 'sortIndex'),
          createdAt: CloudMirrorStore.rowLong(resultSet, 'createdAt'),
          updatedAt: CloudMirrorStore.rowLong(resultSet, 'updatedAt')
        }));
      }
    } finally {
      if (resultSet !== null) {
        resultSet.close();
      }
    }
    return rows;
  }

  private static rowString(resultSet: relationalStore.ResultSet, column: string): string {
    try {
      return resultSet.getString(resultSet.getColumnIndex(column));
    } catch {
      return '';
    }
  }

  private static rowLong(resultSet: relationalStore.ResultSet, column: string): number {
    try {
      return resultSet.getLong(resultSet.getColumnIndex(column));
    } catch {
      return 0;
    }
  }

  private static toState(details: relationalStore.ProgressDetails): CloudSyncState {
    if (details.code === relationalStore.ProgressCode.NETWORK_ERROR) {
      return { status: '网络异常', finished: true, success: false };
    }
    if (details.code === relationalStore.ProgressCode.CLOUD_DISABLED) {
      return { status: '云服务未启用（3）', finished: true, success: false };
    }
    if (details.code === relationalStore.ProgressCode.NO_SPACE_FOR_ASSET) {
      return { status: '云空间不足', finished: true, success: false };
    }
    if (details.code !== relationalStore.ProgressCode.SUCCESS) {
      return { status: `同步失败（${details.code}）`, finished: true, success: false };
    }
    if (details.schedule === relationalStore.Progress.SYNC_FINISH) {
      return { status: '同步成功', finished: true, success: true };
    }
    return { status: '同步中', finished: false, success: false };
  }
}
