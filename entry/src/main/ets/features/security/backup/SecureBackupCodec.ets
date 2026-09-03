import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { AccountItem } from '../../../model/AccountItem';

interface BackupEnvelope {
  format: string;
  version: number;
  kdf: string;
  iterations: number;
  salt: string;
  iv: string;
  payload: string;
}

/** 加密能力边界，生产环境使用 HarmonyOS Crypto Architecture Kit。 */
export interface BackupCryptoProvider {
  randomBytes(length: number): Uint8Array;
  deriveKey(password: string, salt: Uint8Array, iterations: number): Uint8Array;
  encrypt(plainText: Uint8Array, key: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array;
  decrypt(encrypted: Uint8Array, key: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array;
}

class PlatformBackupCryptoProvider implements BackupCryptoProvider {
  private static readonly TAG_LENGTH: number = 16;

  randomBytes(length: number): Uint8Array {
    return cryptoFramework.createRandom().generateRandomSync(length).data;
  }

  deriveKey(password: string, salt: Uint8Array, iterations: number): Uint8Array {
    const kdf = cryptoFramework.createKdf('PBKDF2|SHA256');
    const spec: cryptoFramework.PBKDF2Spec = {
      algName: 'PBKDF2',
      password: password,
      salt: salt,
      iterations: iterations,
      keySize: 32
    };
    return kdf.generateSecretSync(spec).data;
  }

  encrypt(plainText: Uint8Array, keyBytes: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array {
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = keyGenerator.convertKeySync({ data: keyBytes });
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: aad },
      authTag: { data: new Uint8Array(PlatformBackupCryptoProvider.TAG_LENGTH) }
    };
    cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, params);
    return cipher.doFinalSync({ data: plainText }).data;
  }

  decrypt(encrypted: Uint8Array, keyBytes: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array {
    if (encrypted.length <= PlatformBackupCryptoProvider.TAG_LENGTH) {
      throw new Error('Invalid encrypted payload');
    }
    const cipherText: Uint8Array = encrypted.slice(
      0,
      encrypted.length - PlatformBackupCryptoProvider.TAG_LENGTH
    );
    const authTag: Uint8Array = encrypted.slice(
      encrypted.length - PlatformBackupCryptoProvider.TAG_LENGTH
    );
    const keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    const key = keyGenerator.convertKeySync({ data: keyBytes });
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec',
      iv: { data: iv },
      aad: { data: aad },
      authTag: { data: authTag }
    };
    cipher.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, key, params);
    return cipher.doFinalSync({ data: cipherText }).data;
  }
}

/**
 * SecureKey 加密备份编解码器。
 * PBKDF2-SHA256 从用户密码派生密钥，AES-256-GCM 同时提供机密性和篡改检测。
 */
export class SecureBackupCodec {
  private static readonly FORMAT: string = 'securekey-vault';
  private static readonly VERSION: number = 1;
  private static readonly KDF: string = 'PBKDF2|SHA256';
  private static readonly ITERATIONS: number = 310_000;
  private static readonly SALT_LENGTH: number = 16;
  private static readonly IV_LENGTH: number = 12;
  private static readonly BASE64_ALPHABET: string =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  private static readonly PLATFORM_CRYPTO: BackupCryptoProvider = new PlatformBackupCryptoProvider();

  static async encrypt(
    accounts: AccountItem[],
    password: string,
    cryptoProvider: BackupCryptoProvider = SecureBackupCodec.PLATFORM_CRYPTO
  ): Promise<string> {
    SecureBackupCodec.requirePassword(password);
    const salt: Uint8Array = cryptoProvider.randomBytes(SecureBackupCodec.SALT_LENGTH);
    const iv: Uint8Array = cryptoProvider.randomBytes(SecureBackupCodec.IV_LENGTH);
    const saltText: string = SecureBackupCodec.toBase64(salt);
    const ivText: string = SecureBackupCodec.toBase64(iv);
    const aad: Uint8Array = SecureBackupCodec.encode(
      SecureBackupCodec.headerText(saltText, ivText)
    );
    const keyBytes: Uint8Array = cryptoProvider.deriveKey(
      password,
      salt,
      SecureBackupCodec.ITERATIONS
    );
    let cipherText: Uint8Array;
    try {
      cipherText = cryptoProvider.encrypt(
        SecureBackupCodec.encode(JSON.stringify(accounts)),
        keyBytes,
        iv,
        aad
      );
    } finally {
      keyBytes.fill(0);
    }

    const envelope: BackupEnvelope = {
      format: SecureBackupCodec.FORMAT,
      version: SecureBackupCodec.VERSION,
      kdf: SecureBackupCodec.KDF,
      iterations: SecureBackupCodec.ITERATIONS,
      salt: saltText,
      iv: ivText,
      payload: SecureBackupCodec.toBase64(cipherText)
    };
    return JSON.stringify(envelope);
  }

  static async decrypt(
    content: string,
    password: string,
    cryptoProvider: BackupCryptoProvider = SecureBackupCodec.PLATFORM_CRYPTO
  ): Promise<AccountItem[]> {
    SecureBackupCodec.requirePassword(password);
    try {
      const envelope: BackupEnvelope = JSON.parse(content) as BackupEnvelope;
      SecureBackupCodec.validateEnvelope(envelope);
      const salt: Uint8Array = SecureBackupCodec.fromBase64(envelope.salt);
      const iv: Uint8Array = SecureBackupCodec.fromBase64(envelope.iv);
      const payload: Uint8Array = SecureBackupCodec.fromBase64(envelope.payload);
      const aad: Uint8Array = SecureBackupCodec.encode(
        SecureBackupCodec.headerText(envelope.salt, envelope.iv)
      );
      const keyBytes: Uint8Array = cryptoProvider.deriveKey(
        password,
        salt,
        SecureBackupCodec.ITERATIONS
      );
      let plainBytes: Uint8Array;
      try {
        plainBytes = cryptoProvider.decrypt(payload, keyBytes, iv, aad);
      } finally {
        keyBytes.fill(0);
      }
      let accounts: AccountItem[];
      try {
        accounts = JSON.parse(SecureBackupCodec.decode(plainBytes)) as AccountItem[];
      } finally {
        plainBytes.fill(0);
      }
      if (accounts === null || !Array.isArray(accounts)) {
        throw new Error('Invalid backup payload');
      }
      return accounts;
    } catch {
      throw new Error('密码错误或文件无效');
    }
  }

  private static requirePassword(password: string): void {
    if (password.length < 8) {
      throw new Error('备份密码至少需要 8 位');
    }
  }

  private static validateEnvelope(envelope: BackupEnvelope): void {
    if (envelope === null ||
      envelope.format !== SecureBackupCodec.FORMAT ||
      envelope.version !== SecureBackupCodec.VERSION ||
      envelope.kdf !== SecureBackupCodec.KDF ||
      envelope.iterations !== SecureBackupCodec.ITERATIONS ||
      envelope.salt.length === 0 ||
      envelope.iv.length === 0 ||
      envelope.payload.length === 0) {
      throw new Error('Invalid backup envelope');
    }
  }

  private static headerText(salt: string, iv: string): string {
    return `${SecureBackupCodec.FORMAT}|${SecureBackupCodec.VERSION}|${SecureBackupCodec.KDF}|` +
      `${SecureBackupCodec.ITERATIONS}|${salt}|${iv}`;
  }

  private static encode(value: string): Uint8Array {
    const bytes: number[] = [];
    for (let i: number = 0; i < value.length; i++) {
      let codePoint: number = value.charCodeAt(i);
      if (codePoint >= 0xD800 && codePoint <= 0xDBFF && i + 1 < value.length) {
        const low: number = value.charCodeAt(i + 1);
        if (low >= 0xDC00 && low <= 0xDFFF) {
          codePoint = 0x10000 + ((codePoint - 0xD800) << 10) + (low - 0xDC00);
          i++;
        }
      }
      if (codePoint <= 0x7F) {
        bytes.push(codePoint);
      } else if (codePoint <= 0x7FF) {
        bytes.push(0xC0 | (codePoint >>> 6));
        bytes.push(0x80 | (codePoint & 0x3F));
      } else if (codePoint <= 0xFFFF) {
        bytes.push(0xE0 | (codePoint >>> 12));
        bytes.push(0x80 | ((codePoint >>> 6) & 0x3F));
        bytes.push(0x80 | (codePoint & 0x3F));
      } else {
        bytes.push(0xF0 | (codePoint >>> 18));
        bytes.push(0x80 | ((codePoint >>> 12) & 0x3F));
        bytes.push(0x80 | ((codePoint >>> 6) & 0x3F));
        bytes.push(0x80 | (codePoint & 0x3F));
      }
    }
    return new Uint8Array(bytes);
  }

  private static decode(value: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < value.length;) {
      const first: number = value[i];
      let codePoint: number;
      let length: number;
      if (first <= 0x7F) {
        codePoint = first;
        length = 1;
      } else if ((first & 0xE0) === 0xC0) {
        SecureBackupCodec.requireContinuation(value, i, 2);
        codePoint = ((first & 0x1F) << 6) | (value[i + 1] & 0x3F);
        length = 2;
      } else if ((first & 0xF0) === 0xE0) {
        SecureBackupCodec.requireContinuation(value, i, 3);
        codePoint = ((first & 0x0F) << 12) |
          ((value[i + 1] & 0x3F) << 6) |
          (value[i + 2] & 0x3F);
        length = 3;
      } else if ((first & 0xF8) === 0xF0) {
        SecureBackupCodec.requireContinuation(value, i, 4);
        codePoint = ((first & 0x07) << 18) |
          ((value[i + 1] & 0x3F) << 12) |
          ((value[i + 2] & 0x3F) << 6) |
          (value[i + 3] & 0x3F);
        length = 4;
      } else {
        throw new Error('Invalid UTF-8');
      }
      if (codePoint <= 0xFFFF) {
        result += String.fromCharCode(codePoint);
      } else {
        const adjusted: number = codePoint - 0x10000;
        result += String.fromCharCode(0xD800 + (adjusted >>> 10));
        result += String.fromCharCode(0xDC00 + (adjusted & 0x3FF));
      }
      i += length;
    }
    return result;
  }

  private static requireContinuation(value: Uint8Array, offset: number, length: number): void {
    if (offset + length > value.length) {
      throw new Error('Invalid UTF-8');
    }
    for (let i: number = 1; i < length; i++) {
      if ((value[offset + i] & 0xC0) !== 0x80) {
        throw new Error('Invalid UTF-8');
      }
    }
  }

  private static toBase64(value: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < value.length; i += 3) {
      const first: number = value[i];
      const hasSecond: boolean = i + 1 < value.length;
      const hasThird: boolean = i + 2 < value.length;
      const second: number = hasSecond ? value[i + 1] : 0;
      const third: number = hasThird ? value[i + 2] : 0;
      const packed: number = (first << 16) | (second << 8) | third;
      result += SecureBackupCodec.BASE64_ALPHABET.charAt((packed >>> 18) & 0x3F);
      result += SecureBackupCodec.BASE64_ALPHABET.charAt((packed >>> 12) & 0x3F);
      result += hasSecond ? SecureBackupCodec.BASE64_ALPHABET.charAt((packed >>> 6) & 0x3F) : '=';
      result += hasThird ? SecureBackupCodec.BASE64_ALPHABET.charAt(packed & 0x3F) : '=';
    }
    return result;
  }

  private static fromBase64(value: string): Uint8Array {
    if (value.length === 0 || value.length % 4 !== 0) {
      throw new Error('Invalid Base64');
    }
    const bytes: number[] = [];
    for (let i: number = 0; i < value.length; i += 4) {
      const a: number = SecureBackupCodec.base64Index(value.charAt(i));
      const b: number = SecureBackupCodec.base64Index(value.charAt(i + 1));
      const thirdChar: string = value.charAt(i + 2);
      const fourthChar: string = value.charAt(i + 3);
      const c: number = thirdChar === '=' ? 0 : SecureBackupCodec.base64Index(thirdChar);
      const d: number = fourthChar === '=' ? 0 : SecureBackupCodec.base64Index(fourthChar);
      const packed: number = (a << 18) | (b << 12) | (c << 6) | d;
      bytes.push((packed >>> 16) & 0xFF);
      if (thirdChar !== '=') {
        bytes.push((packed >>> 8) & 0xFF);
      }
      if (fourthChar !== '=') {
        bytes.push(packed & 0xFF);
      }
    }
    return new Uint8Array(bytes);
  }

  private static base64Index(value: string): number {
    const index: number = SecureBackupCodec.BASE64_ALPHABET.indexOf(value);
    if (index < 0) {
      throw new Error('Invalid Base64');
    }
    return index;
  }
}
