import { describe, expect, it } from '@ohos/hypium';
import { HuaweiAccountLoginPolicy } from '../main/ets/features/cloud/model/HuaweiAccountLoginPolicy';

export default function huaweiAccountLoginPolicyTest() {
  describe('HuaweiAccountLoginPolicy', () => {
    it('restores the system Huawei ID without forcing another login page', 0, () => {
      expect(HuaweiAccountLoginPolicy.forceLogin('restore')).assertEqual(false);
      expect(HuaweiAccountLoginPolicy.forceAuthorization('restore')).assertEqual(false);
    });

    it('follows the working Huawei ID tap flow: cancel, force login, then profile', 0, () => {
      expect(HuaweiAccountLoginPolicy.cancelBeforeLogin()).assertEqual(true);
      expect(HuaweiAccountLoginPolicy.preferSilentOnTap()).assertEqual(false);
      expect(HuaweiAccountLoginPolicy.attachCsrfState()).assertEqual(true);
      expect(HuaweiAccountLoginPolicy.forceLogin('tap')).assertEqual(true);
      expect(HuaweiAccountLoginPolicy.forceAuthorization('tap')).assertEqual(true);
      expect(HuaweiAccountLoginPolicy.authorizationScopes()[0]).assertEqual('openid');
      expect(HuaweiAccountLoginPolicy.authorizationScopes()[1]).assertEqual('profile');
    });

    it('only forces the system login page when silent restore says no Huawei ID', 0, () => {
      expect(HuaweiAccountLoginPolicy.shouldForceLoginAfterSilentFailure(1001502001)).assertEqual(true);
      expect(HuaweiAccountLoginPolicy.shouldForceLoginAfterSilentFailure(1001500001)).assertEqual(false);
      expect(HuaweiAccountLoginPolicy.shouldForceLoginAfterSilentFailure(1001502003)).assertEqual(false);
    });

    it('keeps login errors short and does not mention Client ID', 0, () => {
      expect(HuaweiAccountLoginPolicy.messageFor(1001502003)).assertEqual('华为账号登录参数配置错误');
      expect(HuaweiAccountLoginPolicy.messageFor(1001502002)).assertEqual('应用尚未获得华为账号授权');
    });

    it('treats a silent Huawei ID login as signed in even without profile', 0, () => {
      expect(HuaweiAccountLoginPolicy.acceptSilentLoginWithoutProfile()).assertEqual(true);
    });
  });
}
