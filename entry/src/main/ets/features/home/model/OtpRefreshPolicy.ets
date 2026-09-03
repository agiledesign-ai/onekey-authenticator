import { OtpType } from '../../../model/OtpType';

/** 判断缓存的 TOTP 验证码是否需要重新计算。 */
export class OtpRefreshPolicy {
  static shouldRefresh(
    hasCachedCode: boolean,
    previousEpoch: number,
    currentEpoch: number,
    period: number
  ): boolean {
    if (!hasCachedCode) {
      return true;
    }
    const previousStep: number = Math.floor(previousEpoch / period);
    const currentStep: number = Math.floor(currentEpoch / period);
    return previousStep !== currentStep;
  }

  static usesTimeStep(type: OtpType): boolean {
    return type !== OtpType.HOTP;
  }
}
