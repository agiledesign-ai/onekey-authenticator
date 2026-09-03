import { Colors, Spacing } from '../../../common/theme/Theme';

/** 操作完成后的紧凑反馈，仅在有结果时出现。 */
@Component
export struct SettingsDetailStatusRow {
  @Prop message: string = '';
  @Prop success: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: Spacing.m }) {
      SymbolGlyph(this.success ? $r('sys.symbol.checkmark_shield_fill') : $r('sys.symbol.info_circle'))
        .fontSize(21)
        .fontColor([this.success ? Colors.success : Colors.warning])

      Text(this.message)
        .fontSize(14)
        .lineHeight(20)
        .fontColor(Colors.textPrimary)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .borderRadius(14)
    .backgroundColor(Colors.chipBg)
    .alignItems(VerticalAlign.Center)
  }
}
