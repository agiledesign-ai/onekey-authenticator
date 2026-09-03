import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';

/**
 * 通用动作行：图标 + 标题 + 描述 + 右箭头，整行可点。
 * 合并原 buildAddEntryCard / buildSettingsActionRow 两处重复实现。
 */
@Component
export struct SettingRow {
  @Prop icon: Resource = $r('sys.symbol.xmark');
  @Prop title: string = '';
  @Prop desc: string = '';
  @Prop iconSize: number = 20;
  @Prop iconBg: string = Colors.chipBg;
  @Prop iconColor: string = Colors.textPrimary;
  @Prop grouped: boolean = false;
  onTap: () => void = () => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: 14 }) {
      Column() {
        SymbolGlyph(this.icon)
          .fontSize(this.iconSize)
          .fontColor([this.iconColor])
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.iconBg)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 3 }) {
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.desc.length > 0) {
          Text(this.desc)
            .fontSize(12)
            .fontColor(Colors.textSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([Colors.textTertiary])
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: PageLayout.ROW_VERTICAL_PADDING,
      bottom: PageLayout.ROW_VERTICAL_PADDING
    })
    .backgroundColor(this.grouped ? Colors.transparent : Colors.card)
    .borderRadius(this.grouped ? 0 : 16)
    .border({ width: this.grouped ? 0 : 1, color: Colors.border })
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onTap())
  }
}
