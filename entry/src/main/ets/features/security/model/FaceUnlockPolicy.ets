/** 统一人脸认证结果，隔离系统错误码与页面业务。 */
export enum FaceAuthResult {
  SUCCESS,
  CANCELED,
  NOT_ENROLLED,
  UNSUPPORTED,
  TIMEOUT,
  LOCKED,
  FAILED
}

/** 仅人脸应用锁的纯状态规则。 */
export class FaceUnlockPolicy {
  static canEnable(result: FaceAuthResult): boolean {
    return result === FaceAuthResult.SUCCESS;
  }

  static shouldLockOnForeground(enabled: boolean): boolean {
    return enabled;
  }

  static isContentVisible(enabled: boolean, authenticated: boolean): boolean {
    return !enabled || authenticated;
  }

  static messageFor(result: FaceAuthResult): string {
    if (result === FaceAuthResult.NOT_ENROLLED) {
      return '请先在系统设置中录入人脸';
    }
    if (result === FaceAuthResult.UNSUPPORTED) {
      return '当前设备不支持人脸解锁';
    }
    if (result === FaceAuthResult.CANCELED) {
      return '已取消人脸识别';
    }
    if (result === FaceAuthResult.TIMEOUT) {
      return '人脸识别超时，请重试';
    }
    if (result === FaceAuthResult.LOCKED) {
      return '人脸识别已被系统锁定，请稍后重试';
    }
    return result === FaceAuthResult.SUCCESS ? '' : '人脸识别失败，请重试';
  }
}
