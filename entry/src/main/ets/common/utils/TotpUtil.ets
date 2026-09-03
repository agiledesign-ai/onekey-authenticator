import { AppConfig } from '../config/AppConfig';
import { createAccountItem } from '../../model/AccountItem';
import { OtpType } from '../../model/OtpType';
import { OtpEngine } from '../../features/otp/engine/OtpEngine';

/** TOTP 生成结果 */
export interface TotpResult {
  /** 当前验证码 */
  code: string;
  /** 当前周期剩余秒数 */
  remainingSeconds: number;
}

/** 兼容入口，实际生成由 OtpEngine 完成。 */
export class TotpUtil {
  static generate(
    secret: string,
    time?: Date,
    algorithm: string = 'SHA1',
    digits: number = AppConfig.TOTP_DIGITS,
    period: number = AppConfig.TOTP_PERIOD
  ): TotpResult {
    const account = createAccountItem('totp-util', 'TOTP', 'TOTP', secret, {
      type: OtpType.TOTP,
      algorithm: algorithm,
      digits: digits,
      period: period
    });
    const result = OtpEngine.generate(account, time);
    return { code: result.code, remainingSeconds: result.remainingSeconds };
  }
}
