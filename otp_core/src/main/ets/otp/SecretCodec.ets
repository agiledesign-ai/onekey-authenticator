const BASE32_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const BASE64_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** 严格 Base32 / Base64 编解码，非法字符直接失败。 */
export class SecretCodec {
  static decodeBase32(input: string): Uint8Array {
    const normalized: string = input.trim().toUpperCase().replace(/=+$/g, '');
    if (normalized.length === 0) {
      return new Uint8Array(0);
    }
    const bytes: number[] = [];
    let buffer: number = 0;
    let bitsLeft: number = 0;
    for (let i: number = 0; i < normalized.length; i++) {
      const value: number = BASE32_ALPHABET.indexOf(normalized.charAt(i));
      if (value < 0) {
        return new Uint8Array(0);
      }
      buffer = ((buffer << 5) | value) >>> 0;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bytes.push((buffer >> (bitsLeft - 8)) & 0xFF);
        bitsLeft -= 8;
      }
    }
    return new Uint8Array(bytes);
  }

  static encodeBase32(bytes: Uint8Array): string {
    let result: string = '';
    let buffer: number = 0;
    let bits: number = 0;
    for (let i: number = 0; i < bytes.length; i++) {
      buffer = (buffer << 8) | bytes[i];
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        result += BASE32_ALPHABET.charAt((buffer >> bits) & 31);
      }
    }
    if (bits > 0) {
      result += BASE32_ALPHABET.charAt((buffer << (5 - bits)) & 31);
    }
    return result;
  }

  static encodeBase64(bytes: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < bytes.length; i += 3) {
      const a: number = bytes[i];
      const b: number = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const c: number = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += BASE64_ALPHABET.charAt((a >> 2) & 63);
      result += BASE64_ALPHABET.charAt(((a & 3) << 4) | ((b >> 4) & 15));
      if (i + 1 < bytes.length) {
        result += BASE64_ALPHABET.charAt(((b & 15) << 2) | ((c >> 6) & 3));
      } else {
        result += '=';
      }
      if (i + 2 < bytes.length) {
        result += BASE64_ALPHABET.charAt(c & 63);
      } else {
        result += '=';
      }
    }
    return result;
  }

  static decodeBase64(input: string): Uint8Array {
    const normalized: string = input.trim().replace(/-/g, '+').replace(/_/g, '/');
    if (normalized.length === 0 || normalized.length % 4 === 1) {
      return new Uint8Array(0);
    }
    const bytes: number[] = [];
    let buffer: number = 0;
    let bits: number = 0;
    for (let i: number = 0; i < normalized.length; i++) {
      const ch: string = normalized.charAt(i);
      if (ch === '=') {
        break;
      }
      const value: number = BASE64_ALPHABET.indexOf(ch);
      if (value < 0) {
        return new Uint8Array(0);
      }
      buffer = (buffer << 6) | value;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        bytes.push((buffer >> bits) & 0xFF);
      }
    }
    return new Uint8Array(bytes);
  }

  static canonicalizeSteamSecret(secret: string): string {
    const asBase32: Uint8Array = SecretCodec.decodeBase32(secret);
    if (asBase32.length > 0) {
      return SecretCodec.encodeBase32(asBase32);
    }
    const asBase64: Uint8Array = SecretCodec.decodeBase64(secret);
    if (asBase64.length > 0) {
      return SecretCodec.encodeBase32(asBase64);
    }
    return '';
  }
}
