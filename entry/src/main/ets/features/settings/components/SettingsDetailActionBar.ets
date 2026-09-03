import { PageLayout } from '../../../common/theme/Metrics';
import { Colors, Spacing } from '../../../common/theme/Theme';

/** 二级页固定操作区，由调用方传入系统底部避让高度。 */
@Component
export struct SettingsDetailActionBar {
  @Prop label: string = '';
  @Prop helper: string = '';
  @Prop actionEnabled: boolean = true;
  @Prop busy: boolean = false;
  @Prop dangerous: boolean = false;
  @Prop bottomInset: number = 0;
  onTap: () => void = () => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column({ space: Spacing.s }) {
      if (this.helper.length > 0) {
        Text(this.helper)
          .fontSize(12)
          .fontColor(Colors.textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      Button(this.busy ? '处理中…' : this.label)
        .type(ButtonType.Capsule)
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.onColor)
        .backgroundColor(
          this.actionEnabled && !this.busy ?
            (this.dangerous ? Colors.warning : Colors.brand) : Colors.disabled
        )
        .enabled(this.actionEnabled && !this.busy)
        .onClick(() => { this.onTap(); })
    }
    .width('100%')
    .padding({
      left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
      right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
      top: Spacing.m,
      bottom: this.bottomInset + Spacing.l
    })
    .backgroundColor(Colors.page)
    .border({ width: { top: 1 }, color: Colors.divider })
  }
}
