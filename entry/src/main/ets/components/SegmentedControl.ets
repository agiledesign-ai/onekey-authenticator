import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { Motion } from '../common/motion/Motion';

/**
 * 通用分段选择器。
 */
@Component
export struct SegmentedControl {
  @Prop options: string[] = [];
  @Prop selectedIndex: number = 0;
  onSelect: (index: number) => void = (_index: number) => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.options.length > 0) {
        Column()
          .width(this.indicatorWidth())
          .height(32)
          .backgroundColor(Colors.card)
          .borderRadius(8)
          .shadow({
            radius: 8,
            color: Colors.shadow,
            offsetX: 0,
            offsetY: 2
          })
          .translate({ x: this.indicatorOffset() })
          .animation({ duration: Motion.SETTINGS_SEGMENT_DURATION, curve: Curve.FastOutSlowIn })
          // 滑块仅负责视觉反馈，不能拦截上层选项的点击事件。
          .hitTestBehavior(HitTestMode.None)
      }

      Row() {
        ForEach(this.options, (option: string, index: number) => {
          Column() {
            Text(option)
              .fontSize(13)
              .fontWeight(
                this.selectedIndex === index ?
                  PageLayout.SETTINGS_SEGMENT_SELECTED_WEIGHT : PageLayout.SETTINGS_SEGMENT_NORMAL_WEIGHT,
                { enableVariableFontWeight: true }
              )
              .fontColor(this.selectedIndex === index ? Colors.brand : Colors.hint)
              .animation({ duration: Motion.SETTINGS_SEGMENT_DURATION, curve: Curve.FastOutSlowIn })
          }
          .layoutWeight(1)
          .height(32)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .hitTestBehavior(HitTestMode.Block)
          .onClick(() => this.onSelect(index))
        }, (option: string) => option)
      }
      .width('100%')
      .height(32)
    }
    .width('100%')
    .height(40)
    .backgroundColor(Colors.chipBg)
    .borderRadius(12)
    .padding(4)
  }

  private indicatorWidth(): string {
    return `${100 / this.options.length}%`;
  }

  private indicatorOffset(): string {
    return `${this.selectedIndex * 100}%`;
  }
}
