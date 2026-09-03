import { Colors } from '../../../common/theme/Theme';

/**
 * 账号列表空状态。
 */
@Component
export struct EmptyState {
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column({ space: 16 }) {
      SymbolGlyph($r('sys.symbol.checkmark_shield_fill'))
        .fontSize(72)
        .fontColor([Colors.textTertiary])
      Text('还没有账号')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textPrimary)
      Text('点击右上角 + 添加你的第一个双因素认证账号')
        .fontSize(14)
        .fontColor(Colors.textSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: 24 })
  }
}
