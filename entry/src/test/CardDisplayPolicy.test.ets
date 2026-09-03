import { describe, expect, it } from '@ohos/hypium';
import { CardDisplayPolicy } from '../main/ets/features/card/model/CardDisplayPolicy';
import { CardFormData } from '../main/ets/features/card/model/CardOtpView';

export default function cardDisplayPolicyTest() {
  describe('CardDisplayPolicy', () => {
    it('groups 6 and 8 digit codes and leaves Steam codes untouched', 0, () => {
      expect(CardDisplayPolicy.formatCode('026230')).assertEqual('026 230');
      expect(CardDisplayPolicy.formatCode('198729')).assertEqual('198 729');
      expect(CardDisplayPolicy.formatCode('026 230')).assertEqual('026 230');
      expect(CardDisplayPolicy.formatCode('12345678')).assertEqual('1234 5678');
      expect(CardDisplayPolicy.formatCode('12345')).assertEqual('12345');
      expect(CardDisplayPolicy.formatCode('')).assertEqual('');
    });

    it('keeps issuer and account as separate lines and hides a duplicate account', 0, () => {
      expect(CardDisplayPolicy.issuerLine('GitHub', 'user@x.com')).assertEqual('GitHub');
      expect(CardDisplayPolicy.issuerLine('', 'user@x.com')).assertEqual('user@x.com');
      expect(CardDisplayPolicy.issuerLine('', '')).assertEqual(CardFormData.EMPTY_NAME);
      expect(CardDisplayPolicy.accountLine('GitHub', 'user@x.com')).assertEqual('user@x.com');
      expect(CardDisplayPolicy.accountLine('agilndesign@gmail.com', 'agilndesign@gmail.com')).assertEqual('');
      expect(CardDisplayPolicy.accountLine('GitHub', '  ')).assertEqual('');
    });

    it('counts only real tokens so empty slots can collapse', 0, () => {
      expect(CardDisplayPolicy.occupiedCount([CardFormData.EMPTY_NAME, ''])).assertEqual(0);
      expect(CardDisplayPolicy.occupiedCount(['GitHub', ''])).assertEqual(1);
      expect(CardDisplayPolicy.occupiedCount(['GitHub', 'Google', '', ''])).assertEqual(2);
      expect(CardDisplayPolicy.isEmpty([CardFormData.EMPTY_NAME, ''])).assertEqual(true);
      expect(CardDisplayPolicy.isEmpty(['GitHub', ''])).assertEqual(false);
    });

    it('picks a stable issuer badge so the same service keeps the same icon', 0, () => {
      expect(CardDisplayPolicy.badgeIndex('GitHub')).assertEqual(3);
      expect(CardDisplayPolicy.badgeIndex('GitHub')).assertEqual(CardDisplayPolicy.badgeIndex('GitHub'));
      expect(CardDisplayPolicy.badgeIndex('')).assertEqual(4);
      expect(CardDisplayPolicy.badgeIndex(CardFormData.EMPTY_NAME)).assertEqual(4);
      expect(CardDisplayPolicy.DEFAULT_BADGE_COLOR).assertEqual('#C4C4C4');
    });

    it('picks a roomy layout per size and does not keep a card title', 0, () => {
      expect(CardDisplayPolicy.showAppTitle()).assertEqual(false);
      expect(CardDisplayPolicy.layoutMode('1*2', 1)).assertEqual('compact');
      expect(CardDisplayPolicy.layoutMode('2*2', 0)).assertEqual('hero');
      expect(CardDisplayPolicy.layoutMode('2*2', 1)).assertEqual('hero');
      expect(CardDisplayPolicy.layoutMode('2*2', 2)).assertEqual('stack');
      expect(CardDisplayPolicy.layoutMode('2*4', 1)).assertEqual('hero');
      expect(CardDisplayPolicy.layoutMode('2*4', 2)).assertEqual('row');
      expect(CardDisplayPolicy.layoutMode('2*4', 3)).assertEqual('grid');
      expect(CardDisplayPolicy.layoutMode('2*4', 4)).assertEqual('grid');
    });
  });
}
