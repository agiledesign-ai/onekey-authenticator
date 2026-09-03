import { Colors } from '../../../common/theme/Theme';
import { PageLayout } from '../../../common/theme/Metrics';

/** 设置首页专用操作行；材质与分隔线由外层分组统一承载。 */
@Component
export struct SettingsActionRow {
  @Prop icon: Resource = $r('sys.symbol.xmark');
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop iconBg: string = Colors.chipBg;
  @Prop iconColor: string = Colors.textPrimary;
  onTap: () => void = () => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: 11 }) {
      Column() {
        SymbolGlyph(this.icon)
          .fontSize(20)
          .fontColor([this.iconColor])
      }
      .width(PageLayout.SETTINGS_ROW_ICON_SIZE)
      .height(PageLayout.SETTINGS_ROW_ICON_SIZE)
      .borderRadius(PageLayout.SETTINGS_ROW_ICON_RADIUS)
      .backgroundColor(this.iconBg)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(PageLayout.SETTINGS_ROW_TITLE_SIZE)
          .fontWeight(PageLayout.SETTINGS_ROW_TITLE_WEIGHT, { enableVariableFontWeight: true })
          .fontColor(this.iconColor === Colors.warning ? Colors.warning : Colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.desc.length > 0) {
          Text(this.desc)
            .fontSize(PageLayout.SETTINGS_ROW_BODY_SIZE)
            .fontWeight(PageLayout.SETTINGS_ROW_BODY_WEIGHT, { enableVariableFontWeight: true })
            .fontColor(Colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(15)
        .fontColor([Colors.textTertiary])
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: this.desc.length > 0 ? 10 : 13, bottom: this.desc.length > 0 ? 10 : 13 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onTap())
    .accessibilityText(this.desc.length > 0 ? `${this.title}，${this.desc}` : this.title)
  }
}
