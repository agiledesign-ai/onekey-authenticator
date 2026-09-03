import { describe, expect, it } from '@ohos/hypium';
import { OtpType } from '../main/ets/model/OtpType';
import { OtpUriCodec, OtpUriStatus } from '../main/ets/features/migration/codec/OtpUriCodec';

export default function otpUriCodecTest() {
  describe('OtpUriCodec', () => {
    it('parses TOTP URI defaults and percent-encoded labels', 0, () => {
      const parsed = OtpUriCodec.parse('otpauth://totp/GitHub%3Aastra%40example.com?secret=JBSWY3DPEHPK3PXP');
      expect(parsed.status).assertEqual(OtpUriStatus.OK);
      expect(parsed.candidate !== null).assertTrue();
      if (parsed.candidate !== null) {
        expect(parsed.candidate.type).assertEqual(OtpType.TOTP);
        expect(parsed.candidate.serviceName).assertEqual('GitHub');
        expect(parsed.candidate.accountName).assertEqual('astra@example.com');
        expect(parsed.candidate.algorithm).assertEqual('SHA1');
        expect(parsed.candidate.digits).assertEqual(6);
        expect(parsed.candidate.period).assertEqual(30);
      }
    });

    it('keeps HOTP counter when present and asks for it when missing', 0, () => {
      const withCounter = OtpUriCodec.parse(
        'otpauth://hotp/VPN:astra?secret=JBSWY3DPEHPK3PXP&counter=7&digits=8&algorithm=SHA256'
      );
      expect(withCounter.status).assertEqual(OtpUriStatus.OK);
      expect(withCounter.candidate !== null).assertTrue();
      if (withCounter.candidate !== null) {
        expect(withCounter.candidate.type).assertEqual(OtpType.HOTP);
        expect(withCounter.candidate.counter).assertEqual(7);
        expect(withCounter.candidate.digits).assertEqual(8);
        expect(withCounter.candidate.algorithm).assertEqual('SHA256');
      }

      const missing = OtpUriCodec.parse('otpauth://hotp/VPN:astra?secret=JBSWY3DPEHPK3PXP');
      expect(missing.status).assertEqual(OtpUriStatus.NEEDS_COUNTER);
      expect(missing.candidate !== null).assertTrue();
    });

    it('parses Steam URI into a five-digit SHA-1 credential', 0, () => {
      const parsed = OtpUriCodec.parse('otpauth://steam/Steam:player?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
      expect(parsed.status).assertEqual(OtpUriStatus.OK);
      expect(parsed.candidate !== null).assertTrue();
      if (parsed.candidate !== null) {
        expect(parsed.candidate.type).assertEqual(OtpType.STEAM);
        expect(parsed.candidate.digits).assertEqual(5);
        expect(parsed.candidate.algorithm).assertEqual('SHA1');
        expect(parsed.candidate.period).assertEqual(30);
      }
    });

    it('rejects unsupported algorithms and missing secrets', 0, () => {
      expect(OtpUriCodec.parse('otpauth://totp/GitHub?secret=JBSWY3DPEHPK3PXP&algorithm=MD5').status)
        .assertEqual(OtpUriStatus.INVALID);
      expect(OtpUriCodec.parse('otpauth://totp/GitHub').status).assertEqual(OtpUriStatus.INVALID);
      expect(OtpUriCodec.parse('otpauth-migration://offline?data=abc').status).assertEqual(OtpUriStatus.INVALID);
    });
  });
}
