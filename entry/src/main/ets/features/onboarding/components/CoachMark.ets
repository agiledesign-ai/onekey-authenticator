import { Colors } from '../../../common/theme/Theme';
import { Motion } from '../../../common/motion/Motion';

/** 底部“+”的首次使用提示。组件保持紧凑尺寸，不遮挡其他页签。 */
@Component
export struct CoachMark {
  onOpenAdd: () => void = () => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontSize(18)
        .fontColor([$r('sys.color.font_primary')])
      Text('点击 + 添加第一个账号')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
    }
    .height(52)
    .padding({ left: 18, right: 18 })
    .borderRadius(26)
    .backgroundColor(Colors.brandMaterial)
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: Colors.shadow, offsetX: 0, offsetY: 4 })
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: Motion.COACH_DURATION, curve: Curve.FastOutSlowIn })
        .combine(TransitionEffect.translate({ y: 12 }))
    )
    .onClick(() => this.onOpenAdd())
    .accessibilityText('点击添加第一个账号')
  }
}
