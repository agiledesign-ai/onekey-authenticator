import { describe, expect, it } from '@ohos/hypium';
import { Motion } from '../main/ets/common/motion/Motion';

export default function motionTest() {
  describe('Motion', () => {
    it('keeps the first-launch intro short and tab motion consistent', 0, () => {
      expect(Motion.INTRO_TOTAL <= Motion.INTRO_MAX).assertTrue();
      expect(Motion.TAB_DURATION).assertEqual(Motion.COACH_DURATION);
    });

    it('keeps manual step transitions restrained', 0, () => {
      expect(Motion.MANUAL_STEP_DURATION).assertEqual(220);
    });
  });
}
