import { AccountItem } from '../model/AccountItem';
import { OtpType } from '../model/OtpType';
import { AccountSecurityPolicy } from '../security/AccountSecurityPolicy';
import { SecretCodec } from './SecretCodec';
import { OtpCore } from './OtpCore';

/** 统一 OTP 生成结果；HOTP 不提供倒计时。 */
export interface OtpGenerateResult {
  code: string;
  remainingSeconds: number;
  counter: number;
}

/** 按账号类型生成 TOTP、HOTP 或 Steam 验证码。 */
export class OtpEngine {
  static generate(account: AccountItem, time?: Date): OtpGenerateResult {
    if (!AccountSecurityPolicy.isValidCredential({
      type: account.type,
      secret: account.secretKey,
      algorithm: account.algorithm,
      digits: account.digits,
      period: account.period,
      counter: account.counter
    })) {
      throw new Error('不支持的 OTP 参数');
    }

    const keyBytes: Uint8Array = account.type === OtpType.STEAM ?
      SecretCodec.decodeBase32(SecretCodec.canonicalizeSteamSecret(account.secretKey)) :
      SecretCodec.decodeBase32(account.secretKey);
    if (keyBytes.length === 0) {
      throw new Error('不支持的 OTP 参数');
    }

    const algorithm: string = account.type === OtpType.STEAM ? 'SHA1' : account.algorithm.toUpperCase();
    let movingFactor: number = account.counter;
    let remainingSeconds: number = 0;
    if (account.type !== OtpType.HOTP) {
      const now: Date = time !== undefined ? time : new Date();
      const epoch: number = Math.floor(now.getTime() / 1000);
      movingFactor = Math.floor(epoch / account.period);
      remainingSeconds = account.period - (epoch % account.period);
    }

    const hmac: Uint8Array = OtpCore.hmac(algorithm, keyBytes, OtpCore.counterToBytes(movingFactor));
    keyBytes.fill(0);
    const code: string = account.type === OtpType.STEAM ?
      OtpCore.steamCode(hmac) :
      OtpCore.dynamicTruncation(hmac, account.digits);
    return {
      code: code,
      remainingSeconds: remainingSeconds,
      counter: account.counter
    };
  }
}
