import { describe, expect, it } from '@ohos/hypium';
import { asset } from '@kit.AssetStoreKit';
import {
  AccountStorage,
  AccountImportSummary,
  AccountStore,
  LegacyAccountSource
} from '../main/ets/common/store/AccountStore';
import { AssetAccountStorage, AssetQuery } from '../main/ets/common/store/AssetAccountStorage';
import { AccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';

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

class MemoryLegacySource implements LegacyAccountSource {
  json: string;
  cleared: boolean = false;

  constructor(json: string) {
    this.json = json;
  }

  readLegacyJson(): string {
    return this.json;
  }

  markMigrated(): void {
    this.cleared = true;
    this.json = '';
  }
}

class RejectingAccountStorage implements AccountStorage {
  loadAll(): AccountItem[] {
    return [];
  }

  save(_account: AccountItem): void {
    throw new Error('write failed');
  }

  remove(_id: string): void {}

  clear(): void {}
}

class RejectSecondWriteStorage extends MemoryAccountStorage {
  private writeCount: number = 0;

  save(account: AccountItem): void {
    this.writeCount++;
    if (this.writeCount === 2) {
      throw new Error('second write failed');
    }
    super.save(account);
  }
}

class TestAssetQueryError extends Error {
  readonly code: number;

  constructor(code: number) {
    super('query failed');
    this.code = code;
  }
}

class ThrowOnUpdateStorage extends MemoryAccountStorage {
  throwNext: boolean = false;

  save(account: AccountItem): void {
    if (this.throwNext) {
      throw new Error('update failed');
    }
    super.save(account);
  }
}

function rejectingAssetQuery(code: number): AssetQuery {
  return (_query: asset.AssetMap): asset.AssetMap[] => {
    throw new TestAssetQueryError(code);
  };
}

function account(id: string, secret: string = 'JBSWY3DPEHPK3PXP'): AccountItem {
  return {
    id: id,
    type: OtpType.TOTP,
    serviceName: 'SecureKey',
    accountName: 'demo',
    badgeColor: '#0A59F7',
    secretKey: secret,
    algorithm: 'SHA1',
    digits: 6,
    period: 30,
    counter: 0,
    groupId: '',
    pinned: false,
    sortIndex: 1,
    createdAt: 1,
    updatedAt: 1,
    schemaVersion: 3
  };
}

export default function accountStoreTest() {
  describe('AssetAccountStorage', () => {
    it('lists asset attributes before reading each secret by alias', 0, () => {
      const alias: Uint8Array = new Uint8Array([1]);
      let queryCount: number = 0;
      let listReturnType: number = -1;
      let detailReturnType: number = -1;
      let detailUsesAlias: boolean = false;
      let detailErrorCode: number = 0;
      const query: AssetQuery = (request: asset.AssetMap): asset.AssetMap[] => {
        queryCount++;
        if (queryCount === 1) {
          listReturnType = request.get(asset.Tag.RETURN_TYPE) as number;
          const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
          attributes.set(asset.Tag.ALIAS, alias);
          return [attributes];
        }

        detailReturnType = request.get(asset.Tag.RETURN_TYPE) as number;
        detailUsesAlias = request.get(asset.Tag.ALIAS) === alias;
        throw new TestAssetQueryError(asset.ErrorCode.DATABASE_ERROR);
      };
      const storage: AssetAccountStorage = new AssetAccountStorage(query);

      try {
        storage.loadAll();
      } catch (error) {
        detailErrorCode = (error as TestAssetQueryError).code;
      }

      expect(queryCount).assertEqual(2);
      expect(listReturnType).assertEqual(asset.ReturnType.ATTRIBUTES);
      expect(detailReturnType).assertEqual(asset.ReturnType.ALL);
      expect(detailUsesAlias).assertTrue();
      expect(detailErrorCode).assertEqual(asset.ErrorCode.DATABASE_ERROR);
    });

    it('treats a missing asset query as an empty secure store', 0, () => {
      const storage: AssetAccountStorage = new AssetAccountStorage(
        rejectingAssetQuery(asset.ErrorCode.NOT_FOUND)
      );

      expect(storage.loadAll().length).assertEqual(0);
    });

    it('clears an empty asset store without querying remove by label', 0, () => {
      const storage: AssetAccountStorage = new AssetAccountStorage(
        rejectingAssetQuery(asset.ErrorCode.NOT_FOUND)
      );
      storage.clear();
      expect(storage.loadAll().length).assertEqual(0);
    });

    it('propagates non-empty-store asset query failures', 0, () => {
      const storage: AssetAccountStorage = new AssetAccountStorage(
        rejectingAssetQuery(asset.ErrorCode.DATABASE_ERROR)
      );
      let errorCode: number = 0;

      try {
        storage.loadAll();
      } catch (error) {
        errorCode = (error as TestAssetQueryError).code;
      }

      expect(errorCode).assertEqual(asset.ErrorCode.DATABASE_ERROR);
    });
  });

  describe('AccountStore', () => {
    it('persists add update and remove through secure storage', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));

      expect(AccountStore.add(account('account-1'))).assertTrue();
      expect(storage.accounts.length).assertEqual(1);
      const edited: AccountItem = account('account-1');
      edited.serviceName = 'Edited';
      expect(AccountStore.update(edited)).assertTrue();
      expect(storage.accounts[0].serviceName).assertEqual('Edited');
      AccountStore.remove('account-1');
      expect(storage.accounts.length).assertEqual(0);
    });

    it('rejects invalid and duplicate credentials', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));

      expect(AccountStore.add(account('valid'))).assertTrue();
      expect(AccountStore.add(account('duplicate', 'jbswy3dpehpk3pxp'))).assertFalse();
      expect(AccountStore.add(account('invalid', 'INVALID-KEY'))).assertFalse();
      expect(storage.accounts.length).assertEqual(1);
    });

    it('returns failure without changing app state when secure storage rejects an add', 0, () => {
      AccountStore.init(new RejectingAccountStorage(), new MemoryLegacySource(''));

      expect(AccountStore.add(account('rejected'))).assertFalse();
      expect(AccountStore.list().length).assertEqual(0);
      expect(AccountStore.recentlyAddedId()).assertEqual('');
    });

    it('removes legacy plaintext only after verified migration', 0, () => {
      const legacy: MemoryLegacySource = new MemoryLegacySource(JSON.stringify([account('legacy')]));
      const storage: MemoryAccountStorage = new MemoryAccountStorage();

      AccountStore.init(storage, legacy);

      expect(storage.accounts.length).assertEqual(1);
      expect(legacy.cleared).assertTrue();
      expect(AccountStore.list().length).assertEqual(1);
    });

    it('keeps legacy plaintext when secure migration fails', 0, () => {
      const legacy: MemoryLegacySource = new MemoryLegacySource(JSON.stringify([account('legacy')]));
      let failed: boolean = false;

      try {
        AccountStore.init(new RejectingAccountStorage(), legacy);
      } catch {
        failed = true;
      }

      expect(failed).assertTrue();
      expect(legacy.cleared).assertFalse();
    });

    it('marks and consumes the account that should animate in', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      const item: AccountItem = account('new-account');
      AccountStore.init(storage, new MemoryLegacySource(''));

      AccountStore.add(item);
      expect(AccountStore.recentlyAddedId()).assertEqual(item.id);
      AccountStore.consumeRecentlyAdded('another-account');
      expect(AccountStore.recentlyAddedId()).assertEqual(item.id);
      AccountStore.consumeRecentlyAdded(item.id);
      expect(AccountStore.recentlyAddedId()).assertEqual('');
    });

    it('imports valid accounts and reports duplicate and invalid records', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));
      AccountStore.add(account('existing'));

      const invalid: AccountItem = account('invalid', 'BAD-SECRET');
      const malformed: AccountItem = JSON.parse('{}') as AccountItem;
      const summary: AccountImportSummary = AccountStore.importAccounts([
        account('duplicate'),
        account('new', 'GEZDGNBVGY3TQOJQ'),
        invalid,
        malformed
      ]);

      expect(summary.imported).assertEqual(1);
      expect(summary.duplicates).assertEqual(1);
      expect(summary.invalid).assertEqual(2);
      expect(AccountStore.list().length).assertEqual(2);
    });

    it('rolls back the entire import when secure storage rejects a write', 0, () => {
      const storage: RejectSecondWriteStorage = new RejectSecondWriteStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));
      let failed: boolean = false;

      try {
        AccountStore.importAccounts([
          account('first', 'GEZDGNBVGY3TQOJQ'),
          account('second', 'MFRGGZDFMZTWQ2LK')
        ]);
      } catch {
        failed = true;
      }

      expect(failed).assertTrue();
      expect(storage.accounts.length).assertEqual(0);
      expect(AccountStore.list().length).assertEqual(0);
    });

    it('advances HOTP only after the new counter is saved', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));
      const hotp: AccountItem = account('hotp-1');
      hotp.type = OtpType.HOTP;
      hotp.period = 30;
      expect(AccountStore.add(hotp)).assertTrue();
      expect(AccountStore.advanceHotp('hotp-1')).assertTrue();
      const advanced: AccountItem | null = AccountStore.get('hotp-1');
      expect(advanced !== null).assertTrue();
      if (advanced !== null) {
        expect(advanced.counter).assertEqual(1);
      }
      expect(storage.accounts[0].counter).assertEqual(1);
    });

    it('leaves the HOTP counter unchanged when storage write fails', 0, () => {
      const storage: ThrowOnUpdateStorage = new ThrowOnUpdateStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));
      const hotp: AccountItem = account('hotp-2');
      hotp.type = OtpType.HOTP;
      expect(AccountStore.add(hotp)).assertTrue();
      storage.throwNext = true;
      expect(AccountStore.advanceHotp('hotp-2')).assertFalse();
      const unchanged: AccountItem | null = AccountStore.get('hotp-2');
      expect(unchanged !== null).assertTrue();
      if (unchanged !== null) {
        expect(unchanged.counter).assertEqual(0);
      }
    });

    it('pins an account without changing its secret', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));
      expect(AccountStore.add(account('pin-1'))).assertTrue();
      expect(AccountStore.setPinned('pin-1', true)).assertTrue();
      const pinned: AccountItem | null = AccountStore.get('pin-1');
      expect(pinned !== null).assertTrue();
      if (pinned !== null) {
        expect(pinned.pinned).assertTrue();
      }
    });

    it('previews an import without writing to secure storage', 0, () => {
      const storage: MemoryAccountStorage = new MemoryAccountStorage();
      AccountStore.init(storage, new MemoryLegacySource(''));

      const summary: AccountImportSummary = AccountStore.previewImport([
        account('first', 'GEZDGNBVGY3TQOJQ'),
        account('invalid', 'BAD-SECRET')
      ]);

      expect(summary.imported).assertEqual(1);
      expect(summary.invalid).assertEqual(1);
      expect(storage.accounts.length).assertEqual(0);
    });
  });
}
