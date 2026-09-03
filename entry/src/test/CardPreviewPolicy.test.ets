import { describe, expect, it } from '@ohos/hypium';
import { CardPreviewPolicy } from '../main/ets/features/card/model/CardPreviewPolicy';

export default function cardPreviewPolicyTest() {
  describe('CardPreviewPolicy', () => {
    it('always allows opening the system form manager like the reference app', 0, () => {
      expect(CardPreviewPolicy.canOpenFormManager(0)).assertEqual(true);
      expect(CardPreviewPolicy.canOpenFormManager(3)).assertEqual(true);
    });

    it('hides unused slots and only keeps 暂无令牌 for a completely empty card', 0, () => {
      expect(CardPreviewPolicy.slotVisible('', 0, 0)).assertEqual(true);
      expect(CardPreviewPolicy.slotVisible('', 1, 0)).assertEqual(false);
      expect(CardPreviewPolicy.slotVisible('GitHub', 0, 1)).assertEqual(true);
      expect(CardPreviewPolicy.slotVisible('', 1, 1)).assertEqual(false);
    });

    it('advances preview sizes in a loop for swipe and autoplay', 0, () => {
      expect(CardPreviewPolicy.PREVIEW_COUNT).assertEqual(3);
      expect(CardPreviewPolicy.nextPreviewIndex(0)).assertEqual(1);
      expect(CardPreviewPolicy.nextPreviewIndex(1)).assertEqual(2);
      expect(CardPreviewPolicy.nextPreviewIndex(2)).assertEqual(0);
      expect(CardPreviewPolicy.previewStageHeightVp()).assertEqual(176);
      expect(CardPreviewPolicy.AUTO_PLAY_INTERVAL_MS).assertEqual(4000);
    });

    it('uses a getting-started empty card instead of 暂无令牌', 0, () => {
      expect(CardPreviewPolicy.emptyTitle()).assertEqual('开始');
      expect(CardPreviewPolicy.emptyCompactHint()).assertEqual('添加一个账户');
      expect(CardPreviewPolicy.emptySteps().length).assertEqual(3);
      expect(CardPreviewPolicy.emptySteps()[0]).assertEqual('打开应用');
      expect(CardPreviewPolicy.emptySteps()[1]).assertEqual('至少添加一个账户');
      expect(CardPreviewPolicy.emptySteps()[2]).assertEqual('点击卡片选择账户');
    });

    it('hides leftover grid dividers when the neighboring slot is empty', 0, () => {
      expect(CardPreviewPolicy.showSmallDivider(0)).assertEqual(false);
      expect(CardPreviewPolicy.showSmallDivider(2)).assertEqual(true);
      expect(CardPreviewPolicy.showMediumVertical(1)).assertEqual(false);
      expect(CardPreviewPolicy.showMediumVertical(2)).assertEqual(true);
      expect(CardPreviewPolicy.showMediumLeftDivider(1)).assertEqual(false);
      expect(CardPreviewPolicy.showMediumLeftDivider(3)).assertEqual(true);
      expect(CardPreviewPolicy.showMediumRightDivider(2)).assertEqual(false);
      expect(CardPreviewPolicy.showMediumRightDivider(4)).assertEqual(true);
    });
  });
}
