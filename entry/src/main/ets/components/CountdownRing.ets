import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';

/**
 * 倒计时圆环：使用原生 Ring Progress 准确表达剩余周期。
 */
@Component
export struct CountdownRing {
  @Prop seconds: number = 30;
  @Prop total: number = 30;
  @Prop diameter: number = 38;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Stack() {
      Progress({ value: this.seconds, total: this.total, type: ProgressType.Ring })
        .width(this.diameter)
        .height(this.diameter)
        .color(this.seconds <= 5 ? Colors.caution : Colors.brand)
        .style({ strokeWidth: 3, shadow: true })
        .animation({ duration: 450, curve: Curve.EaseOut })
      Text(this.seconds.toString())
        .fontSize(12)
        .fontWeight(PageLayout.HOME_COUNTDOWN_WEIGHT, { enableVariableFontWeight: true })
        .fontColor(this.seconds <= 5 ? Colors.caution : Colors.textSecondary)
    }
    .width(this.diameter)
    .height(this.diameter)
  }
}
