import { describe, expect, it } from '@ohos/hypium';
import { AddAccountAction } from '../main/ets/features/add/model/AddAccountAction';

export default function addAccountActionTest() {
  describe('AddAccountAction', () => {
    it('maps the action menu index to scan or manual entry', 0, () => {
      expect(AddAccountAction.fromMenuIndex(0)).assertEqual(AddAccountAction.SCAN);
      expect(AddAccountAction.fromMenuIndex(1)).assertEqual(AddAccountAction.MANUAL);
      expect(AddAccountAction.fromMenuIndex(2)).assertEqual(AddAccountAction.NONE);
      expect(AddAccountAction.fromMenuIndex(-1)).assertEqual(AddAccountAction.NONE);
    });
  });
}
