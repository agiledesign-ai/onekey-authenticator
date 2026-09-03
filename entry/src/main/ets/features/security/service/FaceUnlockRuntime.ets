import { AccountStore } from '../../../common/store/AccountStore';
import { PreferencesUtil } from '../../../common/utils/PreferencesUtil';
import { FaceUnlockPolicy } from '../model/FaceUnlockPolicy';

/** 持久化人脸锁开关，并连接应用前后台生命周期。 */
export class FaceUnlockRuntime {
  static readonly ENABLED_PREFERENCE_KEY: string = 'faceUnlockEnabled';
  static readonly ENABLED_STATE_KEY: string = 'faceUnlockEnabled';
  static readonly CONTENT_VISIBLE_KEY: string = 'faceUnlockContentVisible';
  static readonly AUTH_REQUEST_KEY: string = 'faceUnlockAuthRequestToken';
  private static enabled: boolean = false;

  static init(): void {
    FaceUnlockRuntime.enabled = PreferencesUtil.getNumber(
      FaceUnlockRuntime.ENABLED_PREFERENCE_KEY,
      0
    ) === 1;
    AppStorage.setOrCreate(FaceUnlockRuntime.ENABLED_STATE_KEY, FaceUnlockRuntime.enabled);
    AppStorage.setOrCreate(
      FaceUnlockRuntime.CONTENT_VISIBLE_KEY,
      FaceUnlockPolicy.isContentVisible(FaceUnlockRuntime.enabled, false)
    );
    AppStorage.setOrCreate(FaceUnlockRuntime.AUTH_REQUEST_KEY, 0);
    if (FaceUnlockRuntime.enabled) {
      AccountStore.unload();
    }
  }

  static isEnabled(): boolean {
    return FaceUnlockRuntime.enabled;
  }

  /** 首次人脸验证成功后才允许持久化启用状态。 */
  static enable(): void {
    FaceUnlockRuntime.enabled = true;
    PreferencesUtil.putNumber(FaceUnlockRuntime.ENABLED_PREFERENCE_KEY, 1);
    AppStorage.setOrCreate(FaceUnlockRuntime.ENABLED_STATE_KEY, true);
    AppStorage.setOrCreate(FaceUnlockRuntime.CONTENT_VISIBLE_KEY, true);
  }

  static disable(): void {
    FaceUnlockRuntime.enabled = false;
    PreferencesUtil.putNumber(FaceUnlockRuntime.ENABLED_PREFERENCE_KEY, 0);
    AppStorage.setOrCreate(FaceUnlockRuntime.ENABLED_STATE_KEY, false);
    AppStorage.setOrCreate(FaceUnlockRuntime.CONTENT_VISIBLE_KEY, true);
  }

  static unlock(): void {
    if (FaceUnlockRuntime.enabled) {
      AppStorage.setOrCreate(FaceUnlockRuntime.CONTENT_VISIBLE_KEY, true);
    }
  }

  static enterBackground(): void {
    if (!FaceUnlockPolicy.shouldLockOnForeground(FaceUnlockRuntime.enabled)) {
      return;
    }
    AccountStore.unload();
    AppStorage.setOrCreate(FaceUnlockRuntime.CONTENT_VISIBLE_KEY, false);
  }

  static enterForeground(): boolean {
    if (!FaceUnlockPolicy.shouldLockOnForeground(FaceUnlockRuntime.enabled)) {
      return false;
    }
    AppStorage.setOrCreate(FaceUnlockRuntime.CONTENT_VISIBLE_KEY, false);
    const request: number = AppStorage.get<number>(FaceUnlockRuntime.AUTH_REQUEST_KEY) ?? 0;
    AppStorage.setOrCreate(FaceUnlockRuntime.AUTH_REQUEST_KEY, request + 1);
    return true;
  }
}
