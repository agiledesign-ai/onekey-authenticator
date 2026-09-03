import { WIDGET_CARD_RADIUS, WIDGET_LOADING_SIZE } from './WidgetMetrics';

@Component
export struct WidgetLoadingOverlay {
  @Prop overlayOpacity: number = 1;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      LoadingProgress()
        .width(WIDGET_LOADING_SIZE)
        .height(WIDGET_LOADING_SIZE)
        .color($r('app.color.widget_code'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.widget_loading_overlay'))
    .borderRadius(WIDGET_CARD_RADIUS)
    .opacity(this.overlayOpacity)
  }
}
