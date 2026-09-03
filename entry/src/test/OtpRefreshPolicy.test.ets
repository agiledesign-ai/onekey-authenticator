import { describe, expect, it } from '@ohos/hypium';
import { OtpRefreshPolicy } from '../main/ets/features/home/model/OtpRefreshPolicy';
import { OtpType } from '../main/ets/model/OtpType';

export default function otpRefreshPolicyTest() {
  describe('OtpRefreshPolicy', () => {
    it('refreshes when no verification code is cached', 0, () => {
      expect(OtpRefreshPolicy.shouldRefresh(false, 59, 59, 30)).assertEqual(true);
    });

    it('keeps the cached code within the same time step', 0, () => {
      expect(OtpRefreshPolicy.shouldRefresh(true, 61, 89, 30)).assertEqual(false);
    });

    it('refreshes after one or more missed time-step boundaries', 0, () => {
      expect(OtpRefreshPolicy.shouldRefresh(true, 59, 65, 30)).assertEqual(true);
      expect(OtpRefreshPolicy.shouldRefresh(true, 59, 125, 30)).assertEqual(true);
    });

    it('keeps HOTP off the time-step refresh path', 0, () => {
      expect(OtpRefreshPolicy.usesTimeStep(OtpType.TOTP)).assertEqual(true);
      expect(OtpRefreshPolicy.usesTimeStep(OtpType.STEAM)).assertEqual(true);
      expect(OtpRefreshPolicy.usesTimeStep(OtpType.HOTP)).assertEqual(false);
    });
  });
}
