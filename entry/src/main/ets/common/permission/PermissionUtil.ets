import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { Log } from '../utils/LogUtil';

/** 权限已授权状态码 */
const PERMISSION_GRANTED: number = 0;

/**
 * 权限申请封装（基于 abilityAccessCtrl）。
 * request 接收 Context 以弹窗请求权限；check 通过 bundleManager 获取 tokenId 静态检查。
 */
export class Permission {
  static readonly CAMERA: Permissions = 'ohos.permission.CAMERA';

  /** 检查指定权限是否已授权。 */
  static check(permission: Permissions): boolean {
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const tokenId: number = bundleInfo.appInfo.accessTokenId;
      const status: number = atManager.checkAccessTokenSync(tokenId, permission);
      return status === PERMISSION_GRANTED;
    } catch {
      Log.e('Permission.check failed');
      return false;
    }
  }

  /** 请求权限，返回是否最终授权。context 应为 UIAbilityContext。 */
  static request(context: common.Context, permission: Permissions): Promise<boolean> {
    return new Promise<boolean>((resolve: (value: boolean) => void) => {
      if (Permission.check(permission)) {
        resolve(true);
        return;
      }
      try {
        const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(context, [permission], (err: Error, result) => {
          if (err) {
            Log.e('Permission.request failed: ' + JSON.stringify(err));
            resolve(false);
          } else {
            resolve(result.authResults[0] === PERMISSION_GRANTED);
          }
        });
      } catch {
        Log.e('Permission.request exception');
        resolve(false);
      }
    });
  }
}
