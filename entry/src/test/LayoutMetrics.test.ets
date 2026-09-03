import { describe, expect, it } from '@ohos/hypium';
import { PageLayout } from '../main/ets/common/theme/Metrics';

export default function layoutMetricsTest() {
  describe('PageLayout', () => {
    it('keeps content compact while reserving the floating bar area', 0, () => {
      expect(PageLayout.HEADER_HORIZONTAL_INSET).assertEqual(20);
      expect(PageLayout.CONTENT_HORIZONTAL_INSET).assertEqual(16);
      expect(PageLayout.ACTION_GROUP_TOP).assertEqual(16);
      expect(PageLayout.CONTENT_BOTTOM_INSET).assertEqual(132);
      expect(PageLayout.FIRST_SECTION_TOP).assertEqual(8);
      expect(PageLayout.SECTION_TOP).assertEqual(16);
      expect(PageLayout.SECTION_BOTTOM).assertEqual(8);
      expect(PageLayout.FIRST_SECTION_TOP < PageLayout.SECTION_TOP).assertTrue();
      expect(PageLayout.ROW_VERTICAL_PADDING).assertEqual(12);
    });

    it('keeps the add hint ring clear of the tab label', 0, () => {
      const availableSize: number = PageLayout.TAB_ICON_STACK_HEIGHT + PageLayout.TAB_ICON_LABEL_GAP * 2;
      expect(PageLayout.ADD_HINT_RING_SIZE <= availableSize).assertTrue();
    });

    it('lifts the floating navigation by the requested physical distance', 0, () => {
      expect(PageLayout.NAV_BAR_BASE_BOTTOM_MARGIN).assertEqual(16);
      expect(PageLayout.NAV_BAR_LIFT_PX).assertEqual(30);
      expect(PageLayout.COACH_BASE_BOTTOM_MARGIN).assertEqual(108);
    });

    it('keeps the manual add hierarchy balanced', 0, () => {
      expect(PageLayout.MANUAL_HEADER_CONTENT_HEIGHT).assertEqual(56);
      expect(PageLayout.MANUAL_HEADER_TITLE_SIZE).assertEqual(20);
      expect(PageLayout.MANUAL_HEADER_ICON_SIZE).assertEqual(24);
      expect(PageLayout.MANUAL_HEADER_STEP_SIZE).assertEqual(14);
      expect(PageLayout.MANUAL_STEP_TITLE_SIZE).assertEqual(22);
    });

    it('uses a spacious native-list rhythm for settings details', 0, () => {
      expect(PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET).assertEqual(24);
      expect(PageLayout.DETAIL_SECTION_GAP).assertEqual(32);
      expect(PageLayout.DETAIL_ROW_ICON_SIZE).assertEqual(28);
      expect(PageLayout.DETAIL_ROW_TITLE_SIZE).assertEqual(16);
      expect(PageLayout.DETAIL_ROW_BODY_SIZE).assertEqual(14);
    });
  });
}
