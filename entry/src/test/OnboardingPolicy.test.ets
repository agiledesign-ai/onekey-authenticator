import { describe, it, expect } from '@ohos/hypium';
import { OnboardingPolicy } from '../main/ets/features/onboarding/model/OnboardingPolicy';

export default function onboardingPolicyTest() {
  describe('OnboardingPolicy', () => {
    it('uses version ordering to decide whether onboarding is required', 0, () => {
      expect(OnboardingPolicy.shouldShow(0, 1)).assertTrue();
      expect(OnboardingPolicy.shouldShow(1, 1)).assertFalse();
      expect(OnboardingPolicy.shouldShow(2, 1)).assertFalse();
    });
  });
}
