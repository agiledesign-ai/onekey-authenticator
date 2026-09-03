import { describe, expect, it } from '@ohos/hypium';
import { ManualAddFlow, ManualAddStep } from '../main/ets/features/add/model/ManualAddFlow';

export default function manualAddFlowTest() {
  describe('ManualAddFlow', () => {
    it('only advances when the current step is complete', 0, () => {
      expect(ManualAddFlow.canContinue(ManualAddStep.SERVICE, '', '')).assertFalse();
      expect(ManualAddFlow.canContinue(ManualAddStep.SERVICE, 'GitHub', '')).assertTrue();
      expect(ManualAddFlow.next(ManualAddStep.SERVICE, '', '')).assertEqual(ManualAddStep.SERVICE);
      expect(ManualAddFlow.next(ManualAddStep.SERVICE, 'GitHub', '')).assertEqual(ManualAddStep.SECRET);

      expect(ManualAddFlow.canContinue(ManualAddStep.SECRET, 'GitHub', 'INVALID-KEY')).assertFalse();
      expect(ManualAddFlow.canContinue(ManualAddStep.SECRET, 'GitHub', 'JBSWY3DPEHPK3PXP')).assertTrue();
      expect(ManualAddFlow.next(ManualAddStep.SECRET, 'GitHub', 'JBSWY3DPEHPK3PXP'))
        .assertEqual(ManualAddStep.CONFIRM);
      expect(ManualAddFlow.previous(ManualAddStep.CONFIRM)).assertEqual(ManualAddStep.SECRET);
      expect(ManualAddFlow.previous(ManualAddStep.SECRET)).assertEqual(ManualAddStep.SERVICE);
    });

    it('masks the secret on the confirmation step', 0, () => {
      expect(ManualAddFlow.maskSecret('jbswy3dpehpk3pxp')).assertEqual('JBSW •••• 3PXP');
      expect(ManualAddFlow.maskSecret('abcd2345')).assertEqual('AB •••• 45');
    });
  });
}
