import { describe, expect, it } from '@ohos/hypium';
import { OtpType } from '../main/ets/model/OtpType';
import {
  GoogleMigrationCodec,
  GoogleMigrationParameter
} from '../main/ets/features/migration/codec/GoogleMigrationCodec';

function sampleParameter(name: string, issuer: string, type: OtpType, counter: number): GoogleMigrationParameter {
  return {
    secret: 'JBSWY3DPEHPK3PXP',
    name: name,
    issuer: issuer,
    algorithm: 'SHA1',
    digits: 6,
    type: type,
    counter: counter
  };
}

export default function googleMigrationCodecTest() {
  describe('GoogleMigrationCodec', () => {
    it('decodes a single-page Google Authenticator migration URI', 0, () => {
      const uri: string = GoogleMigrationCodec.encodeUri({
        version: 1,
        batchSize: 1,
        batchIndex: 0,
        batchId: 42,
        parameters: [
          sampleParameter('astra@example.com', 'GitHub', OtpType.TOTP, 0),
          sampleParameter('vpn', 'Corp', OtpType.HOTP, 9)
        ]
      });
      const page = GoogleMigrationCodec.parse(uri);
      expect(page !== null).assertTrue();
      if (page !== null) {
        expect(page.batchSize).assertEqual(1);
        expect(page.batchIndex).assertEqual(0);
        expect(page.batchId).assertEqual(42);
        expect(page.parameters.length).assertEqual(2);
        expect(page.parameters[0].issuer).assertEqual('GitHub');
        expect(page.parameters[0].type).assertEqual(OtpType.TOTP);
        expect(page.parameters[1].type).assertEqual(OtpType.HOTP);
        expect(page.parameters[1].counter).assertEqual(9);
      }
    });

    it('rejects MD5 and oversized HOTP counters', 0, () => {
      const md5Uri: string = GoogleMigrationCodec.encodeUri({
        version: 1,
        batchSize: 1,
        batchIndex: 0,
        batchId: 1,
        parameters: [{
          secret: 'JBSWY3DPEHPK3PXP',
          name: 'bad',
          issuer: 'GitHub',
          algorithm: 'MD5',
          digits: 6,
          type: OtpType.TOTP,
          counter: 0
        }]
      });
      const md5Page = GoogleMigrationCodec.parse(md5Uri);
      expect(md5Page !== null).assertTrue();
      if (md5Page !== null) {
        expect(md5Page.parameters.length).assertEqual(0);
      }
    });

    it('returns null for a truncated or non-migration URI', 0, () => {
      expect(GoogleMigrationCodec.parse('otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP') === null).assertTrue();
      expect(GoogleMigrationCodec.parse('otpauth-migration://offline?data=@@@') === null).assertTrue();
    });
  });
}
