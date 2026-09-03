import { describe, expect, it } from '@ohos/hypium';
import { ClipboardPolicy } from '../main/ets/features/security/model/SecurityPolicy';

export default function securityPolicyTest() {
  describe('SecurityPolicy', () => {
    it('expires copied codes at the earlier security deadline', 0, () => {
      expect(ClipboardPolicy.expiresAt(10_000, 24)).assertEqual(34_000);
      expect(ClipboardPolicy.expiresAt(10_000, 45)).assertEqual(40_000);
      expect(ClipboardPolicy.stillOwnsClipboard(7, 7)).assertTrue();
      expect(ClipboardPolicy.stillOwnsClipboard(7, 8)).assertFalse();
    });

  });
}
