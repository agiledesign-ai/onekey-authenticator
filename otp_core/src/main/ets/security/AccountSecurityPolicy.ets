import { OtpConfig } from '../model/OtpConfig';
import { OtpType } from '../model/OtpType';

/** 用于参数校验和重复检测的标准 OTP 身份。 */
export interface OtpCredential {
  type: OtpType;
  secret: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
}

/** 账号密钥校验和重复检测策略。 */
export class AccountSecurityPolicy {
  static normalizeSecret(secret: string): string {
    const normalized: string = secret.trim().toUpperCase();
    return new RegExp(OtpConfig.SECRET_PATTERN).test(normalized) ? normalized : '';
  }

  /** 按验证码类型校验并约束参数，避免存储无意义的兼容组合。 */
  static isValidCredential(credential: OtpCredential): boolean {
    const algorithm: string = credential.algorithm.toUpperCase();
    if (AccountSecurityPolicy.normalizeSecret(credential.secret).length === 0 ||
      !AccountSecurityPolicy.isSupportedAlgorithm(algorithm)) {
      return false;
    }

    if (credential.type === OtpType.TOTP) {
      return AccountSecurityPolicy.isStandardDigits(credential.digits) &&
        AccountSecurityPolicy.isStandardPeriod(credential.period) &&
        credential.counter === 0;
    }
    if (credential.type === OtpType.HOTP) {
      return AccountSecurityPolicy.isStandardDigits(credential.digits) &&
        credential.period === 30 &&
        Number.isInteger(credential.counter) &&
        credential.counter >= 0 &&
        credential.counter <= Number.MAX_SAFE_INTEGER;
    }
    if (credential.type === OtpType.STEAM) {
      return algorithm === 'SHA1' &&
        credential.digits === 5 &&
        credential.period === 30 &&
        credential.counter === 0;
    }
    return false;
  }

  static isDuplicate(first: OtpCredential, second: OtpCredential): boolean {
    if (!AccountSecurityPolicy.isValidCredential(first) ||
      !AccountSecurityPolicy.isValidCredential(second) ||
      first.type !== second.type) {
      return false;
    }
    const firstSecret: string = AccountSecurityPolicy.normalizeSecret(first.secret);
    const secondSecret: string = AccountSecurityPolicy.normalizeSecret(second.secret);
    if (firstSecret !== secondSecret) {
      return false;
    }
    if (first.type === OtpType.STEAM) {
      return true;
    }
    const hasSameCoreParameters: boolean =
      first.algorithm.toUpperCase() === second.algorithm.toUpperCase() &&
      first.digits === second.digits;
    return first.type === OtpType.HOTP ? hasSameCoreParameters :
      hasSameCoreParameters && first.period === second.period;
  }

  private static isSupportedAlgorithm(algorithm: string): boolean {
    return algorithm === 'SHA1' || algorithm === 'SHA256' || algorithm === 'SHA512';
  }

  private static isStandardDigits(digits: number): boolean {
    return digits === 6 || digits === 8;
  }

  private static isStandardPeriod(period: number): boolean {
    return period === 15 || period === 30 || period === 60;
  }
}
