import { describe, expect, it } from '@ohos/hypium';
import { createAccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';
import { OtpEngine } from '../main/ets/features/otp/engine/OtpEngine';

const RFC_SECRET: string = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

export default function otpEngineTest() {
  describe('OtpEngine', () => {
    it('matches RFC 6238 SHA-1 TOTP vectors', 0, () => {
      const account = createAccountItem('totp-1', 'RFC', 'vector', RFC_SECRET, {
        type: OtpType.TOTP,
        digits: 8
      });
      const result = OtpEngine.generate(account, new Date(59_000));
      expect(result.code).assertEqual('94287082');
      expect(result.remainingSeconds).assertEqual(1);
    });

    it('matches RFC 4226 HOTP vectors and does not invent a countdown', 0, () => {
      const account = createAccountItem('hotp-1', 'RFC', 'vector', RFC_SECRET, {
        type: OtpType.HOTP,
        counter: 0
      });
      const zero = OtpEngine.generate(account);
      expect(zero.code).assertEqual('755224');
      expect(zero.remainingSeconds).assertEqual(0);
      expect(zero.counter).assertEqual(0);

      account.counter = 1;
      expect(OtpEngine.generate(account).code).assertEqual('287082');
    });

    it('generates a five-character Steam code from the time step', 0, () => {
      const account = createAccountItem('steam-1', 'Steam', 'vector', RFC_SECRET, {
        type: OtpType.STEAM
      });
      const result = OtpEngine.generate(account, new Date(59_000));
      expect(result.code).assertEqual('PV9M4');
      expect(result.code.length).assertEqual(5);
      expect(result.remainingSeconds).assertEqual(1);
    });
  });
}
