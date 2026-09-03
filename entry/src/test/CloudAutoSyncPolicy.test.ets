import { describe, expect, it } from '@ohos/hypium';
import { CloudAutoSyncPolicy } from '../main/ets/features/cloud/model/CloudAutoSyncPolicy';

export default function cloudAutoSyncPolicyTest() {
  describe('CloudAutoSyncPolicy', () => {
    it('keeps the auto-sync switch off until the Huawei ID is in use', 0, () => {
      expect(CloudAutoSyncPolicy.canOperateSwitch(false, false)).assertEqual(false);
      expect(CloudAutoSyncPolicy.canOperateSwitch(false, true)).assertEqual(false);
      expect(CloudAutoSyncPolicy.canOperateSwitch(true, true)).assertEqual(false);
      expect(CloudAutoSyncPolicy.canOperateSwitch(true, false)).assertEqual(true);
    });

    it('rejects turning auto-sync on when the Huawei ID is not in use', 0, () => {
      expect(CloudAutoSyncPolicy.shouldRejectEnable(false, true)).assertEqual(true);
      expect(CloudAutoSyncPolicy.shouldRejectEnable(true, true)).assertEqual(false);
      expect(CloudAutoSyncPolicy.shouldRejectEnable(false, false)).assertEqual(false);
    });

    it('remounts the switch after a rejected turn-on so it cannot stay visually on', 0, () => {
      expect(CloudAutoSyncPolicy.nextEpoch(3, true)).assertEqual(4);
      expect(CloudAutoSyncPolicy.nextEpoch(3, false)).assertEqual(3);
      expect(CloudAutoSyncPolicy.switchKey(false, 4)).assertEqual('cloud-auto-sync-0-4');
    });
  });
}
