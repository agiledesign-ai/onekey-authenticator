import { common } from '@kit.AbilityKit';
import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';
import { CloudCommandResult } from '../model/CloudSyncState';
import { AccountGroupVault } from '../store/AccountGroupVault';
import { CloudMirrorStore } from '../store/CloudMirrorStore';
import { CloudSettingsStore } from '../store/CloudSettingsStore';
import { CloudLocalHooks } from './CloudLocalHooks';
import { CloudPermission } from './CloudPermission';
import { CloudSyncCoordinator } from './CloudSyncCoordinator';
import { HuaweiAccountService } from './HuaweiAccountService';

/** 进程内云同步入口。未初始化时本机增删改不写 RDB。 */
export class CloudSyncRuntime {
  private static coordinator: CloudSyncCoordinator | null = null;
  private static accounts: HuaweiAccountService | null = null;
  private static context: common.UIAbilityContext | null = null;

  static init(context: common.UIAbilityContext): void {
    CloudSettingsStore.hydrate();
    const settings: CloudSettingsStore = new CloudSettingsStore();
    CloudSyncRuntime.context = context;
    CloudSyncRuntime.accounts = new HuaweiAccountService(context, settings);
    CloudSyncRuntime.coordinator = new CloudSyncCoordinator(
      new CloudPermission(context),
      new CloudMirrorStore(context),
      new AccountGroupVault(),
      settings
    );
    CloudLocalHooks.onAccountUpserted = (item: AccountItem): void => {
      CloudSyncRuntime.coordinator?.onLocalAccountUpserted(item);
    };
    CloudLocalHooks.onAccountRemoved = (id: string): void => {
      CloudSyncRuntime.coordinator?.onLocalAccountRemoved(id);
    };
    CloudLocalHooks.onAccountsCleared = (ids: string[]): void => {
      CloudSyncRuntime.coordinator?.onLocalAccountsCleared(ids);
    };
    CloudLocalHooks.onGroupUpserted = (item: GroupItem): void => {
      CloudSyncRuntime.coordinator?.onLocalGroupUpserted(item);
    };
    CloudSyncRuntime.restoreAccount();
  }

  static async restoreAccount(): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.accounts === null) {
      return { success: false, status: '无法读取华为账号' };
    }
    const result = await CloudSyncRuntime.accounts.restore();
    return { success: result.success, status: result.message };
  }

  static async probeSystemAccountName(): Promise<string> {
    if (CloudSyncRuntime.accounts === null) {
      return '';
    }
    return await CloudSyncRuntime.accounts.probeSystemAccountName();
  }

  static async login(context?: common.UIAbilityContext): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.accounts === null) {
      return { success: false, status: '无法拉起华为账号登录' };
    }
    const result = await CloudSyncRuntime.accounts.login(context);
    return { success: result.success, status: result.message };
  }

  static async logout(): Promise<void> {
    if (CloudSyncRuntime.accounts !== null) {
      await CloudSyncRuntime.accounts.logout();
    }
    CloudSyncRuntime.coordinator?.logout();
  }

  static async enableAutoSync(): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.coordinator === null) {
      return { success: false, status: '云同步不可用' };
    }
    CloudSettingsStore.setSyncing(true);
    try {
      return await CloudSyncRuntime.coordinator.enableAutoSync();
    } finally {
      CloudSettingsStore.setSyncing(false);
    }
  }

  static async disableAutoSync(): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.coordinator === null) {
      return { success: false, status: '云同步不可用' };
    }
    return await CloudSyncRuntime.coordinator.disableAutoSync();
  }

  static async push(): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.coordinator === null) {
      return { success: false, status: '云同步不可用' };
    }
    CloudSettingsStore.setSyncing(true);
    try {
      return await CloudSyncRuntime.coordinator.push();
    } finally {
      CloudSettingsStore.setSyncing(false);
    }
  }

  static async pull(): Promise<CloudCommandResult> {
    if (CloudSyncRuntime.coordinator === null) {
      return { success: false, status: '云同步不可用' };
    }
    CloudSettingsStore.setSyncing(true);
    try {
      return await CloudSyncRuntime.coordinator.pull();
    } finally {
      CloudSettingsStore.setSyncing(false);
    }
  }

  static async openCloudSpaceSettings(): Promise<boolean> {
    if (CloudSyncRuntime.context === null) {
      return false;
    }
    try {
      await CloudSyncRuntime.context.startAbility({
        action: 'ohos.want.action.viewData',
        uri: 'hicloud://cloudDrive/getInfo?path=MainActivity'
      });
      return true;
    } catch {
      return false;
    }
  }

  static onAccountUpserted(item: AccountItem): void {
    CloudSyncRuntime.coordinator?.onLocalAccountUpserted(item);
  }

  static onAccountRemoved(id: string): void {
    CloudSyncRuntime.coordinator?.onLocalAccountRemoved(id);
  }

  static onAccountsCleared(ids: string[]): void {
    CloudSyncRuntime.coordinator?.onLocalAccountsCleared(ids);
  }

  static onGroupUpserted(item: GroupItem): void {
    CloudSyncRuntime.coordinator?.onLocalGroupUpserted(item);
  }
}
