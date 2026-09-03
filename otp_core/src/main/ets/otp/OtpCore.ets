import { hmacSha1 } from './CryptoUtil';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';

const STEAM_ALPHABET: string = '23456789BCDFGHJKMNPQRTVWXY';

/** HMAC、计数器编码和动态截断的共享实现。 */
export class OtpCore {
  static counterToBytes(counter: number): Uint8Array {
    const bytes: Uint8Array = new Uint8Array(8);
    const high: number = Math.floor(counter / 0x100000000);
    const low: number = counter % 0x100000000;
    bytes[0] = (high >>> 24) & 0xFF;
    bytes[1] = (high >>> 16) & 0xFF;
    bytes[2] = (high >>> 8) & 0xFF;
    bytes[3] = high & 0xFF;
    bytes[4] = (low >>> 24) & 0xFF;
    bytes[5] = (low >>> 16) & 0xFF;
    bytes[6] = (low >>> 8) & 0xFF;
    bytes[7] = low & 0xFF;
    return bytes;
  }

  static hmac(algorithm: string, keyBytes: Uint8Array, counterBytes: Uint8Array): Uint8Array {
    if (algorithm === 'SHA1') {
      return hmacSha1(keyBytes, counterBytes);
    }
    const keyGenerator = cryptoFramework.createSymKeyGenerator('HMAC');
    const key = keyGenerator.convertKeySync({ data: keyBytes });
    const mac = cryptoFramework.createMac(algorithm);
    mac.initSync(key);
    mac.updateSync({ data: counterBytes });
    return mac.doFinalSync().data;
  }

  static dynamicTruncation(hmac: Uint8Array, digits: number): string {
    const offset: number = hmac[hmac.length - 1] & 0x0F;
    const truncated: number = (((hmac[offset] & 0x7F) << 24)
      | (hmac[offset + 1] << 16)
      | (hmac[offset + 2] << 8)
      | hmac[offset + 3]) >>> 0;
    const modulo: number = Math.pow(10, digits);
    const code: number = truncated % modulo;
    return code.toString().padStart(digits, '0');
  }

  static steamCode(hmac: Uint8Array): string {
    const offset: number = hmac[hmac.length - 1] & 0x0F;
    let code: number = (((hmac[offset] & 0x7F) << 24)
      | (hmac[offset + 1] << 16)
      | (hmac[offset + 2] << 8)
      | hmac[offset + 3]) >>> 0;
    let result: string = '';
    for (let i: number = 0; i < 5; i++) {
      result += STEAM_ALPHABET.charAt(code % STEAM_ALPHABET.length);
      code = Math.floor(code / STEAM_ALPHABET.length);
    }
    return result;
  }
}
