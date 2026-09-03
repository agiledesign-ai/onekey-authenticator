import { describe, expect, it } from '@ohos/hypium';
import { FeedbackMailPolicy } from '../main/ets/features/settings/model/FeedbackMailPolicy';

export default function feedbackMailPolicyTest() {
  describe('FeedbackMailPolicy', () => {
    it('builds a mailto URI from trimmed feedback', 0, () => {
      const uri: string = FeedbackMailPolicy.mailtoUri('  希望支持分组排序\n谢谢  ');

      expect(uri).assertEqual(
        'mailto:halolion@petalmail.com?subject=' + encodeURIComponent('2FA验证器建议反馈') +
          '&body=' + encodeURIComponent('希望支持分组排序\n谢谢')
      );
    });

    it('uses an instructional body when feedback is blank', 0, () => {
      expect(FeedbackMailPolicy.body('   ')).assertEqual('请在这里描述你的建议或问题：');
    });

    it('provides an actionable failure message', 0, () => {
      expect(FeedbackMailPolicy.failureMessage())
        .assertEqual('请发送邮件至 halolion@petalmail.com');
    });
  });
}
