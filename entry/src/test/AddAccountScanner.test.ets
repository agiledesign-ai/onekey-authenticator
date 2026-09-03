import { describe, expect, it } from '@ohos/hypium';
import { GoogleMigrationCodec } from '../main/ets/features/migration/codec/GoogleMigrationCodec';
import { OtpType } from '../main/ets/model/OtpType';
import { AccountStore, AccountStorage, LegacyAccountSource } from '../main/ets/common/store/AccountStore';
import { AccountItem } from '../main/ets/model/AccountItem';
import { AddAccountScanner, ScanImportKind } from '../main/ets/features/add/service/AddAccountScanner';
import { MigrationSessionStore } from '../main/ets/features/migration/service/MigrationSessionStore';

class MemoryAccountStorage implements AccountStorage {
  accounts: AccountItem[] = [];

  loadAll(): AccountItem[] {
    return this.accounts.slice();
  }

  save(account: AccountItem): void {
    const index: number = this.accounts.findIndex((item: AccountItem) => item.id === account.id);
    if (index >= 0) {
      this.accounts[index] = account;
    } else {
      this.accounts.push(account);
    }
  }

  remove(id: string): void {
    this.accounts = this.accounts.filter((item: AccountItem) => item.id !== id);
  }

  clear(): void {
    this.accounts = [];
  }
}

class EmptyLegacySource implements LegacyAccountSource {
  readLegacyJson(): string {
    return '';
  }

  markMigrated(): void {}
}

export default function addAccountScannerTest() {
  describe('AddAccountScanner', () => {
    it('imports TOTP, HOTP and Steam URIs and asks for a missing HOTP counter', 0, () => {
      AccountStore.init(new MemoryAccountStorage(), new EmptyLegacySource());
      const totp = AddAccountScanner.handleValue(
        'otpauth://totp/GitHub:astra?secret=JBSWY3DPEHPK3PXP'
      );
      expect(totp.kind).assertEqual(ScanImportKind.SAVED);

      const hotp = AddAccountScanner.handleValue(
        'otpauth://hotp/VPN:astra?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&counter=3'
      );
      expect(hotp.kind).assertEqual(ScanImportKind.SAVED);

      const needsCounter = AddAccountScanner.handleValue(
        'otpauth://hotp/VPN:other?secret=MFRGGZDFMZTWQ2LK'
      );
      expect(needsCounter.kind).assertEqual(ScanImportKind.NEEDS_COUNTER);

      const steam = AddAccountScanner.handleValue(
        'otpauth://steam/Steam:player?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
      );
      expect(steam.kind).assertEqual(ScanImportKind.SAVED);
    });

    it('imports a single-page Google migration payload', 0, () => {
      AccountStore.init(new MemoryAccountStorage(), new EmptyLegacySource());
      MigrationSessionStore.clear();
      const uri: string = GoogleMigrationCodec.encodeUri({
        version: 1,
        batchSize: 1,
        batchIndex: 0,
        batchId: 11,
        parameters: [{
          secret: 'JBSWY3DPEHPK3PXP',
          name: 'astra@example.com',
          issuer: 'GitHub',
          algorithm: 'SHA1',
          digits: 6,
          type: OtpType.TOTP,
          counter: 0
        }]
      });
      const result = AddAccountScanner.handleValue(uri);
      expect(result.kind).assertEqual(ScanImportKind.MIGRATION_DONE);
      expect(AccountStore.list().length).assertEqual(1);
    });
  });
}
