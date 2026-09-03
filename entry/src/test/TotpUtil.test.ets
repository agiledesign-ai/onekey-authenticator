import { describe, expect, it } from '@ohos/hypium';
import { TotpUtil } from '../main/ets/common/utils/TotpUtil';

export default function totpUtilTest() {
  describe('TotpUtil', () => {
    it('supports RFC digits and period parameters', 0, () => {
      const secret: string = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
      const eightDigit = TotpUtil.generate(secret, new Date(59_000), 'SHA1', 8, 30);
      expect(eightDigit.code).assertEqual('94287082');
      expect(eightDigit.remainingSeconds).assertEqual(1);

      const sixtySecond = TotpUtil.generate(secret, new Date(59_000), 'SHA1', 6, 60);
      expect(sixtySecond.code).assertEqual('755224');
      expect(sixtySecond.remainingSeconds).assertEqual(1);
    });
  });
}
