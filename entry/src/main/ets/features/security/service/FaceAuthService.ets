import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';
import { FaceAuthResult } from '../model/FaceUnlockPolicy';

/** 仅调用 HarmonyOS 系统人脸认证，不读取或保存任何人脸特征。 */
export class FaceAuthService {
  static checkAvailability(): FaceAuthResult {
    try {
      userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL2);
      return FaceAuthResult.SUCCESS;
    } catch (error) {
      return FaceAuthService.mapResult((error as BusinessError).code);
    }
  }

  static authenticate(): Promise<FaceAuthResult> {
    return new Promise<FaceAuthResult>((resolve: (value: FaceAuthResult) => void) => {
      try {
        const challenge: Uint8Array = cryptoFramework.createRandom().generateRandomSync(32).data;
        const authParam: userAuth.AuthParam = {
          challenge: challenge,
          authType: [userAuth.UserAuthType.FACE],
          authTrustLevel: userAuth.AuthTrustLevel.ATL2
        };
        const widgetParam: userAuth.WidgetParam = {
          title: '验证人脸以打开2FA验证器',
          navigationButtonText: '取消'
        };
        const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
        const callback: userAuth.IAuthCallback = {
          onResult: (result: userAuth.UserAuthResult): void => {
            instance.off('result', callback);
            resolve(FaceAuthService.mapResult(result.result));
          }
        };
        instance.on('result', callback);
        instance.start();
      } catch (error) {
        resolve(FaceAuthService.mapResult((error as BusinessError).code));
      }
    });
  }

  private static mapResult(code: number): FaceAuthResult {
    if (code === userAuth.UserAuthResultCode.SUCCESS) {
      return FaceAuthResult.SUCCESS;
    }
    if (code === userAuth.UserAuthResultCode.CANCELED ||
      code === userAuth.UserAuthResultCode.CANCELED_FROM_WIDGET) {
      return FaceAuthResult.CANCELED;
    }
    if (code === userAuth.UserAuthResultCode.NOT_ENROLLED) {
      return FaceAuthResult.NOT_ENROLLED;
    }
    if (code === userAuth.UserAuthResultCode.TYPE_NOT_SUPPORT ||
      code === userAuth.UserAuthResultCode.TRUST_LEVEL_NOT_SUPPORT) {
      return FaceAuthResult.UNSUPPORTED;
    }
    if (code === userAuth.UserAuthResultCode.TIMEOUT) {
      return FaceAuthResult.TIMEOUT;
    }
    if (code === userAuth.UserAuthResultCode.LOCKED) {
      return FaceAuthResult.LOCKED;
    }
    return FaceAuthResult.FAILED;
  }
}
