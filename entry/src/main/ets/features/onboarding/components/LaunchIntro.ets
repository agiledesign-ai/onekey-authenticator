import { Colors } from '../../../common/theme/Theme';
import { Motion } from '../../../common/motion/Motion';

/** 首次安装品牌开场：圆形柔和替换为盾牌，可点击跳过。 */
@Component
export struct LaunchIntro {
  onFinished: () => void = () => {};
  @State private morphed: boolean = false;
  @State private symbolTrigger: number = -1;
  @State private titleVisible: boolean = false;
  @State private exiting: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private morphTimer: number = 0;
  private titleTimer: number = 0;
  private exitTimer: number = 0;
  private finishing: boolean = false;
  private completionSent: boolean = false;

  aboutToDisappear(): void {
    this.clearTimers();
  }

  private play(): void {
    this.morphTimer = setTimeout(() => {
      this.getUIContext().animateTo({
        duration: Motion.INTRO_MORPH_DURATION,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.morphed = true;
        this.symbolTrigger++;
      });
    }, Motion.INTRO_MORPH_DELAY);

    this.titleTimer = setTimeout(() => {
      this.getUIContext().animateTo({
        duration: Motion.INTRO_TITLE_DURATION,
        curve: Curve.EaseOut
      }, () => {
        this.titleVisible = true;
      });
    }, Motion.INTRO_TITLE_DELAY);

    this.exitTimer = setTimeout(() => this.finish(), Motion.INTRO_EXIT_AT);
  }

  private finish(): void {
    if (this.finishing || this.completionSent) {
      return;
    }
    this.finishing = true;
    this.clearTimers();
    this.getUIContext().animateTo({
      duration: Motion.INTRO_EXIT_DURATION,
      curve: Curve.EaseIn,
      onFinish: () => this.completeOnce()
    }, () => {
      this.exiting = true;
    });
  }

  private completeOnce(): void {
    if (this.completionSent) {
      return;
    }
    this.completionSent = true;
    this.onFinished();
  }

  private clearTimers(): void {
    clearTimeout(this.morphTimer);
    clearTimeout(this.titleTimer);
    clearTimeout(this.exitTimer);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Circle()
        .width(112)
        .height(112)
        .fill(Colors.onColor)
        .opacity(this.morphed ? 0 : 0.16)
        .scale({
          x: this.morphed ? 1.35 : 0.56,
          y: this.morphed ? 1.35 : 0.56
        })

      SymbolGlyph(this.morphed ? $r('sys.symbol.checkmark_shield_fill') : $r('sys.symbol.circle_fill'))
        .fontSize(88)
        .fontColor([Colors.onColor])
        .symbolEffect(
          new ReplaceSymbolEffect(EffectScope.WHOLE, ReplaceEffectType.CROSS_FADE),
          this.symbolTrigger
        )

      Column({ space: 6 }) {
        Text('2FA验证器')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.onColor)
        Text('安全，始终在本机')
          .fontSize(14)
          .fontColor(Colors.onColor)
          .opacity(0.82)
      }
      .opacity(this.titleVisible ? 1 : 0)
      .translate({ y: this.titleVisible ? 82 : 94 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.brand)
    .opacity(this.exiting ? 0 : 1)
    .scale({ x: this.exiting ? 1.04 : 1, y: this.exiting ? 1.04 : 1 })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .onAppear(() => this.play())
    .onClick(() => this.finish())
    .accessibilityText('点击跳过开场动画')
  }
}
