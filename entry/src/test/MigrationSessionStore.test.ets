import { describe, expect, it } from '@ohos/hypium';
import { OtpType } from '../main/ets/model/OtpType';
import { GoogleMigrationPage } from '../main/ets/features/migration/codec/GoogleMigrationCodec';
import {
  MigrationSessionStatus,
  MigrationSessionStore
} from '../main/ets/features/migration/service/MigrationSessionStore';

function page(batchId: number, batchSize: number, batchIndex: number, name: string): GoogleMigrationPage {
  return {
    version: 1,
    batchSize: batchSize,
    batchIndex: batchIndex,
    batchId: batchId,
    parameters: [{
      secret: 'JBSWY3DPEHPK3PXP',
      name: name,
      issuer: 'GitHub',
      algorithm: 'SHA1',
      digits: 6,
      type: OtpType.TOTP,
      counter: 0
    }]
  };
}

export default function migrationSessionStoreTest() {
  describe('MigrationSessionStore', () => {
    it('accepts out-of-order pages and ignores duplicates', 0, () => {
      MigrationSessionStore.clear();
      const second = MigrationSessionStore.addPage(page(7, 2, 1, 'second'), 1000);
      expect(second.status).assertEqual(MigrationSessionStatus.PROGRESS);
      expect(second.scanned).assertEqual(1);
      expect(second.total).assertEqual(2);

      const duplicate = MigrationSessionStore.addPage(page(7, 2, 1, 'second'), 1100);
      expect(duplicate.scanned).assertEqual(1);

      const first = MigrationSessionStore.addPage(page(7, 2, 0, 'first'), 1200);
      expect(first.status).assertEqual(MigrationSessionStatus.COMPLETE);
      expect(MigrationSessionStore.collectParameters().length).assertEqual(2);
    });

    it('rejects a mixed batch and a payload over 200 accounts', 0, () => {
      MigrationSessionStore.clear();
      MigrationSessionStore.addPage(page(1, 2, 0, 'a'), 1000);
      const mixed = MigrationSessionStore.addPage(page(2, 2, 1, 'b'), 1100);
      expect(mixed.status).assertEqual(MigrationSessionStatus.MIXED_BATCH);

      MigrationSessionStore.clear();
      const oversized: GoogleMigrationPage = page(3, 1, 0, 'a');
      const parameters = oversized.parameters;
      for (let i: number = 0; i < 201; i++) {
        parameters.push(page(3, 1, 0, `n${i}`).parameters[0]);
      }
      expect(MigrationSessionStore.addPage(oversized, 1000).status)
        .assertEqual(MigrationSessionStatus.TOO_LARGE);
    });

    it('expires after two minutes and clears on background unless a scan is in progress', 0, () => {
      MigrationSessionStore.clear();
      MigrationSessionStore.addPage(page(9, 2, 0, 'a'), 1000);
      const expired = MigrationSessionStore.addPage(page(9, 2, 1, 'b'), 1000 + 120_001);
      expect(expired.status).assertEqual(MigrationSessionStatus.EXPIRED);

      MigrationSessionStore.clear();
      MigrationSessionStore.addPage(page(8, 2, 0, 'a'), 1000);
      MigrationSessionStore.markScanInProgress();
      MigrationSessionStore.clearIfBackgrounded();
      expect(MigrationSessionStore.scannedCount()).assertEqual(1);
      MigrationSessionStore.markScanFinished();
      MigrationSessionStore.clearIfBackgrounded();
      expect(MigrationSessionStore.scannedCount()).assertEqual(0);
    });
  });
}
