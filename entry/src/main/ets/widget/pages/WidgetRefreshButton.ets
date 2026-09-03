import {
  WIDGET_BUTTON_RADIUS,
  WIDGET_BUTTON_SIZE,
  WIDGET_REFRESH_ICON_SIZE
} from './WidgetMetrics';

@Component
export struct WidgetRefreshButton {
  onRefresh: () => void = () => {};
  @Prop refreshEnabled: boolean = true;

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
        .fontSize(WIDGET_REFRESH_ICON_SIZE)
        .fontWeight(FontWeight.Regular)
        .fontColor([$r('app.color.widget_refresh_icon')])
    }
    .width(WIDGET_BUTTON_SIZE)
    .height(WIDGET_BUTTON_SIZE)
    .backgroundColor($r('app.color.widget_refresh_background'))
    .borderRadius(WIDGET_BUTTON_RADIUS)
    .padding(0)
    .flexShrink(0)
    .enabled(this.refreshEnabled)
    .hitTestBehavior(HitTestMode.Block)
    .onClick(() => {
      this.onRefresh();
    })
  }
}
