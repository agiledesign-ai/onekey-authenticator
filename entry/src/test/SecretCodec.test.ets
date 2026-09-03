import { describe, expect, it } from '@ohos/hypium';
import { SecretCodec } from '../main/ets/features/otp/codec/SecretCodec';

export default function secretCodecTest() {
  describe('SecretCodec', () => {
    it('rejects illegal Base32 instead of stripping characters', 0, () => {
      expect(SecretCodec.decodeBase32('JBSWY3DPEHPK3PXP').length > 0).assertTrue();
      expect(SecretCodec.decodeBase32('JBSW Y3DP').length).assertEqual(0);
      expect(SecretCodec.decodeBase32('JBSW-Y3DP').length).assertEqual(0);
      expect(SecretCodec.decodeBase32('').length).assertEqual(0);
    });

    it('round-trips Steam Base64 shared_secret into canonical Base32', 0, () => {
      const canonical: string = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
      const bytes: Uint8Array = SecretCodec.decodeBase32(canonical);
      const base64: string = SecretCodec.encodeBase64(bytes);
      expect(SecretCodec.canonicalizeSteamSecret(base64)).assertEqual(canonical);
      expect(SecretCodec.canonicalizeSteamSecret(canonical)).assertEqual(canonical);
    });
  });
}
