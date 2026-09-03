import { describe, expect, it } from '@ohos/hypium';
import { CloudFeaturePolicy } from '../main/ets/features/cloud/model/CloudFeaturePolicy';

export default function cloudFeaturePolicyTest() {
  describe('CloudFeaturePolicy', () => {
    it('keeps cloud disabled in the public source build', 0, () => {
      expect(CloudFeaturePolicy.isEnabled()).assertFalse();
    });
  });
}
