import { PageLayout } from '../../../common/theme/Metrics';
import { Colors, Spacing } from '../../../common/theme/Theme';
import {
  SettingsDetailItem,
  SettingsDetailSection
} from '../model/SettingsDetailContent';
import { SettingsDetailRow } from './SettingsDetailRow';

/** 无外框的分组列表，通过留白和缩进分隔线建立层级。 */
@Component
export struct SettingsDetailListSection {
  @Prop section: SettingsDetailSection = { title: '', items: [] };
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column() {
      Text(this.section.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')
        .margin({ bottom: Spacing.s })

      ForEach(this.section.items, (item: SettingsDetailItem, index: number) => {
        SettingsDetailRow({ item: item })

        if (index < this.section.items.length - 1) {
          Divider()
            .color(Colors.divider)
            .strokeWidth(1)
            .margin({ left: PageLayout.DETAIL_ROW_ICON_SIZE + 14 })
        }
      }, (item: SettingsDetailItem, index: number) => `${this.section.title}-${item.title}-${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
