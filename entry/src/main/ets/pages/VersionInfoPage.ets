import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailIntro } from '../features/settings/components/SettingsDetailIntro';
import { SettingsDetailListSection } from '../features/settings/components/SettingsDetailListSection';
import {
  SettingsDetailContent,
  SettingsDetailSection
} from '../features/settings/model/SettingsDetailContent';

/** 当前安装版本的简明信息页。 */
@Entry
@Component
struct VersionInfoPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private sections: SettingsDetailSection[] = SettingsDetailContent.versionSections();

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
      WindowUtil.getBottomAvoidHeightPx(context).then((px: number) => {
        this.bottomInset = this.getUIContext().px2vp(px);
      });
    }
  }

  build() {
    Column() {
      SettingsDetailHeader({ title: '版本信息', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          SettingsDetailIntro({
            title: '版本信息',
            description: '查看当前安装版本与运行方式。'
          })

          ForEach(this.sections, (section: SettingsDetailSection) => {
            SettingsDetailListSection({ section: section })
              .margin({ top: PageLayout.DETAIL_SECTION_GAP })
          }, (section: SettingsDetailSection) => section.title)

          Column()
            .height(this.bottomInset + 28)
        }
        .width('100%')
        .padding({
          left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          top: 18
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
