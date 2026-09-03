import { Colors } from '../../../common/theme/Theme';
import { PageLayout } from '../../../common/theme/Metrics';
import { Toast } from '../../../common/utils/ToastUtil';

/** 设置二级页统一返回栏。 */
@Component
export struct SettingsDetailHeader {
  @Prop title: string = '';
  @Prop statusBarHeight: number = 0;
  @Prop transparent: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: 12 }) {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize(22)
          .fontColor([Colors.textPrimary])
      }
      .width(40)
      .height(40)
      .backgroundColor(Colors.chipBg)
      .hitTestBehavior(HitTestMode.Block)
      .onClick(() => { this.back(); })

      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({
      left: PageLayout.HEADER_HORIZONTAL_INSET,
      right: PageLayout.HEADER_HORIZONTAL_INSET,
      top: this.statusBarHeight + 10,
      bottom: 10
    })
    .backgroundColor(this.transparent ? Colors.transparent : Colors.page)
  }

  private back(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch {
      Toast.error('返回失败');
    }
  }
}
