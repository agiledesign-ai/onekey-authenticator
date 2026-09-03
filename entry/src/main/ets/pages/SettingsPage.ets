import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsTabContent } from '../features/settings/components/SettingsTabContent';

/** 设置独立页。从验证码首页齿轮进入。 */
@Entry
@Component
struct SettingsPage {
  @State statusBarHeight: number = 0;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
    }
  }

  build() {
    Column() {
      SettingsTabContent({ statusBarHeight: this.statusBarHeight, showBack: true })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
