import { describe, expect, it } from '@ohos/hypium';
import { AccountItem } from '../main/ets/model/AccountItem';
import {
  BackupCryptoProvider,
  SecureBackupCodec
} from '../main/ets/features/security/backup/SecureBackupCodec';
import { OtpType } from '../main/ets/model/OtpType';

/** Darwin 单元测试环境不执行系统加密 API，此实现只用于验证备份封装和错误路径。 */
class TestBackupCryptoProvider implements BackupCryptoProvider {
  randomBytes(length: number): Uint8Array {
    const result: Uint8Array = new Uint8Array(length);
    for (let i: number = 0; i < length; i++) {
      result[i] = (i * 17 + 11) & 0xFF;
    }
    return result;
  }

  deriveKey(password: string, salt: Uint8Array, _iterations: number): Uint8Array {
    const result: Uint8Array = new Uint8Array(32);
    for (let i: number = 0; i < result.length; i++) {
      result[i] = (password.charCodeAt(i % password.length) + salt[i % salt.length] + i) & 0xFF;
    }
    return result;
  }

  encrypt(plainText: Uint8Array, key: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array {
    const result: Uint8Array = new Uint8Array(plainText.length + 4);
    for (let i: number = 0; i < plainText.length; i++) {
      result[i] = plainText[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    const checksum: number = this.checksum(plainText, key, iv, aad);
    result[result.length - 4] = (checksum >>> 24) & 0xFF;
    result[result.length - 3] = (checksum >>> 16) & 0xFF;
    result[result.length - 2] = (checksum >>> 8) & 0xFF;
    result[result.length - 1] = checksum & 0xFF;
    return result;
  }

  decrypt(encrypted: Uint8Array, key: Uint8Array, iv: Uint8Array, aad: Uint8Array): Uint8Array {
    if (encrypted.length <= 4) {
      throw new Error('Invalid test payload');
    }
    const plainText: Uint8Array = new Uint8Array(encrypted.length - 4);
    for (let i: number = 0; i < plainText.length; i++) {
      plainText[i] = encrypted[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    const expected: number = this.checksum(plainText, key, iv, aad);
    const actual: number = ((encrypted[encrypted.length - 4] << 24) |
      (encrypted[encrypted.length - 3] << 16) |
      (encrypted[encrypted.length - 2] << 8) |
      encrypted[encrypted.length - 1]) >>> 0;
    if (expected !== actual) {
      throw new Error('Invalid test authentication tag');
    }
    return plainText;
  }

  private checksum(data: Uint8Array, key: Uint8Array, iv: Uint8Array, aad: Uint8Array): number {
    let value: number = 2166136261;
    const all: Uint8Array[] = [data, key, iv, aad];
    for (let partIndex: number = 0; partIndex < all.length; partIndex++) {
      const part: Uint8Array = all[partIndex];
      for (let i: number = 0; i < part.length; i++) {
        value = Math.imul(value ^ part[i], 16777619) >>> 0;
      }
    }
    return value;
  }
}

export default function secureBackupCodecTest() {
  describe('SecureBackupCodec', () => {
    it('round trips account data with the correct password', 0, async () => {
      const cryptoProvider: BackupCryptoProvider = new TestBackupCryptoProvider();
      const account: AccountItem = {
        id: 'account-1',
        type: OtpType.TOTP,
        serviceName: '企业邮箱',
        accountName: 'astra@example.com',
        badgeColor: '#4285F4',
        secretKey: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1', digits: 6, period: 30, counter: 0, groupId: '', pinned: false,
        sortIndex: 1, createdAt: 1, updatedAt: 1, schemaVersion: 3
      };

      const encoded: string = await SecureBackupCodec.encrypt(
        [account],
        'correct horse battery staple',
        cryptoProvider
      );
      const decoded: AccountItem[] = await SecureBackupCodec.decrypt(
        encoded,
        'correct horse battery staple',
        cryptoProvider
      );

      expect(encoded.indexOf(account.secretKey)).assertEqual(-1);
      expect(decoded.length).assertEqual(1);
      expect(decoded[0].serviceName).assertEqual('企业邮箱');
      expect(decoded[0].secretKey).assertEqual(account.secretKey);
    });

    it('rejects a wrong password and modified ciphertext', 0, async () => {
      const cryptoProvider: BackupCryptoProvider = new TestBackupCryptoProvider();
      const account: AccountItem = {
        id: 'account-2',
        type: OtpType.TOTP,
        serviceName: 'Example',
        accountName: 'demo',
        badgeColor: '#0A59F7',
        secretKey: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1', digits: 6, period: 30, counter: 0, groupId: '', pinned: false,
        sortIndex: 1, createdAt: 1, updatedAt: 1, schemaVersion: 3
      };
      const encoded: string = await SecureBackupCodec.encrypt([account], 'backup-password', cryptoProvider);
      let wrongPasswordRejected: boolean = false;
      let tamperRejected: boolean = false;

      try {
        await SecureBackupCodec.decrypt(encoded, 'wrong-password', cryptoProvider);
      } catch {
        wrongPasswordRejected = true;
      }
      const lastChar: string = encoded.charAt(encoded.length - 1);
      const replacement: string = lastChar === 'A' ? 'B' : 'A';
      try {
        await SecureBackupCodec.decrypt(
          encoded.substring(0, encoded.length - 1) + replacement,
          'backup-password',
          cryptoProvider
        );
      } catch {
        tamperRejected = true;
      }

      expect(wrongPasswordRejected).assertTrue();
      expect(tamperRejected).assertTrue();
    });
  });
}
