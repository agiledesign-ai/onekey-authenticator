import { WidgetLoadingOverlay } from './WidgetLoadingOverlay';
import { WidgetSmallBody } from './WidgetBodies';
import { WIDGET_CARD_RADIUS, WIDGET_REFRESH_DELAY } from './WidgetMetrics';

let S_STORAGE: LocalStorage = new LocalStorage();

@Entry(S_STORAGE)
@Component
struct WidgetSmallCard {
  @LocalStorageProp('t1Name') t1Name: string = '暂无令牌';
  @LocalStorageProp('t1Remark') t1Remark: string = '';
  @LocalStorageProp('t1Code') t1Code: string = '';
  @LocalStorageProp('t1Color') t1Color: string = '#C4C4C4';
  @LocalStorageProp('t2Name') t2Name: string = '';
  @LocalStorageProp('t2Remark') t2Remark: string = '';
  @LocalStorageProp('t2Code') t2Code: string = '';
  @LocalStorageProp('t2Color') t2Color: string = '#C4C4C4';
  @State private isRefreshing: boolean = false;
  @State private loadingOpacity: number = 0;

  private refresh(): void {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    animateTo({
      duration: WIDGET_REFRESH_DELAY,
      curve: Curve.Linear,
      onFinish: (): void => {
        postCardAction(this, {
          action: 'message',
          params: {
            msgTest: `refresh:${Date.now()}`
          }
        });
        this.loadingOpacity = 0;
        this.isRefreshing = false;
      }
    }, (): void => {
      this.loadingOpacity = 1;
    });
  }

  private openApp(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {}
    });
  }

  build() {
    Stack() {
      WidgetSmallBody({
        t1Name: this.t1Name,
        t1Remark: this.t1Remark,
        t1Code: this.t1Code,
        t1Color: this.t1Color,
        t2Name: this.t2Name,
        t2Remark: this.t2Remark,
        t2Code: this.t2Code,
        t2Color: this.t2Color,
        refreshEnabled: !this.isRefreshing,
        onOpen: (): void => {
          this.openApp();
        },
        onRefresh: (): void => {
          this.refresh();
        }
      })

      if (this.isRefreshing) {
        WidgetLoadingOverlay({ overlayOpacity: this.loadingOpacity })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.widget_card_background'))
    .borderRadius(WIDGET_CARD_RADIUS)
    .clip(true)
  }
}
