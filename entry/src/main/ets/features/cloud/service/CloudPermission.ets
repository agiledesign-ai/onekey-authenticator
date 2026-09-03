import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { Log } from '../../../common/utils/LogUtil';
import { CloudAuthGate } from './CloudSyncCoordinator';
import { CloudSettingsStore } from '../store/CloudSettingsStore';

const DATA_SYNC_PERMISSION: Permissions = 'ohos.permission.DISTRIBUTED_DATASYNC';

/** 华为账号登录态与跨设备同步权限。 */
export class CloudPermission implements CloudAuthGate {
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  isLoggedIn(): boolean {
    return new CloudSettingsStore().load().loggedIn;
  }

  async requestDataSync(): Promise<boolean> {
    try {
      const manager = abilityAccessCtrl.createAtManager();
      const status = manager.getSelfPermissionStatus(DATA_SYNC_PERMISSION);
      if (status === abilityAccessCtrl.PermissionStatus.GRANTED) {
        return true;
      }
      if (status === abilityAccessCtrl.PermissionStatus.DENIED) {
        const settingResults = await manager.requestPermissionOnSetting(this.context, [DATA_SYNC_PERMISSION]);
        return settingResults.length > 0 &&
          settingResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
      }
      const result = await manager.requestPermissionsFromUser(this.context, [DATA_SYNC_PERMISSION]);
      return result.authResults.length > 0 &&
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      Log.e('CloudPermission.requestDataSync failed ' + JSON.stringify(error));
      return false;
    }
  }
}
