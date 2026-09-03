import { describe, expect, it } from '@ohos/hypium';
import {
  FaceAuthResult,
  FaceUnlockPolicy
} from '../main/ets/features/security/model/FaceUnlockPolicy';

export default function faceUnlockPolicyTest() {
  describe('FaceUnlockPolicy', () => {
    it('keeps content visible when face unlock is disabled by default', 0, () => {
      expect(FaceUnlockPolicy.isContentVisible(false, false)).assertTrue();
      expect(FaceUnlockPolicy.shouldLockOnForeground(false)).assertFalse();
    });

    it('persists face unlock only after successful face authentication', 0, () => {
      expect(FaceUnlockPolicy.canEnable(FaceAuthResult.SUCCESS)).assertTrue();
      expect(FaceUnlockPolicy.canEnable(FaceAuthResult.CANCELED)).assertFalse();
      expect(FaceUnlockPolicy.canEnable(FaceAuthResult.NOT_ENROLLED)).assertFalse();
      expect(FaceUnlockPolicy.canEnable(FaceAuthResult.UNSUPPORTED)).assertFalse();
      expect(FaceUnlockPolicy.canEnable(FaceAuthResult.FAILED)).assertFalse();
    });

    it('keeps enabled sessions locked until face authentication succeeds', 0, () => {
      expect(FaceUnlockPolicy.shouldLockOnForeground(true)).assertTrue();
      expect(FaceUnlockPolicy.isContentVisible(true, false)).assertFalse();
      expect(FaceUnlockPolicy.isContentVisible(true, true)).assertTrue();
    });

    it('provides precise guidance without offering a fallback method', 0, () => {
      expect(FaceUnlockPolicy.messageFor(FaceAuthResult.NOT_ENROLLED))
        .assertEqual('请先在系统设置中录入人脸');
      expect(FaceUnlockPolicy.messageFor(FaceAuthResult.UNSUPPORTED))
        .assertEqual('当前设备不支持人脸解锁');
      expect(FaceUnlockPolicy.messageFor(FaceAuthResult.LOCKED))
        .assertEqual('人脸识别已被系统锁定，请稍后重试');
    });
  });
}
