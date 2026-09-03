import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AppConfig } from '../common/config/AppConfig';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailRow } from '../features/settings/components/SettingsDetailRow';
import {
  SettingsDetailContent,
  SettingsDetailItem,
  SettingsDetailSection
} from '../features/settings/model/SettingsDetailContent';

/** 关于页：紧凑身份区与能力/原则分组，避免大卡片留白。 */
@Entry
@Component
struct AboutAppPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private sections: SettingsDetailSection[] = SettingsDetailContent.aboutSections();

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
      SettingsDetailHeader({
        title: '关于应用',
        statusBarHeight: this.statusBarHeight,
        transparent: true
      })

      Scroll() {
        Column() {
          this.buildIdentity()

          ForEach(this.sections, (section: SettingsDetailSection) => {
            this.buildSection(section)
          }, (section: SettingsDetailSection) => section.title)

          Column().height(this.bottomInset + 28)
        }
        .width('100%')
        .padding({
          left: PageLayout.CONTENT_HORIZONTAL_INSET,
          right: PageLayout.CONTENT_HORIZONTAL_INSET
        })
      }
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[Colors.homePageStart, 0], [Colors.homePageEnd, 1]]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  buildIdentity() {
    Column({ space: 8 }) {
      Image($r('app.media.startIcon'))
        .width(64)
        .height(64)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)
        .shadow({ radius: 16, color: Colors.shadow, offsetX: 0, offsetY: 6 })

      Text(SettingsDetailContent.aboutName())
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)

      Text(SettingsDetailContent.aboutTagline())
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.brand)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(8)
        .backgroundColor(Colors.brandLight)

      Text(AppConfig.APP_VERSION_LABEL)
        .fontSize(12)
        .fontColor(Colors.textTertiary)
    }
    .width('100%')
    .padding({ top: 4, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildSection(section: SettingsDetailSection) {
    Column() {
      Text(section.title)
        .fontSize(PageLayout.SETTINGS_SECTION_SIZE)
        .fontWeight(PageLayout.SETTINGS_SECTION_WEIGHT, { enableVariableFontWeight: true })
        .fontColor(Colors.textSecondary)
        .margin({ bottom: 7, left: 4 })

      Column() {
        ForEach(section.items, (item: SettingsDetailItem, index: number) => {
          SettingsDetailRow({ item: item })

          if (index < section.items.length - 1) {
            Divider()
              .color(Colors.divider)
              .strokeWidth(1)
              .margin({ left: PageLayout.DETAIL_ROW_ICON_SIZE + 14 })
          }
        }, (item: SettingsDetailItem, index: number) => `${section.title}-${item.title}-${index}`)
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
      .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
      .clip(true)
      .backgroundColor(Colors.card)
      .border({ width: 1, color: Colors.border })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 16 })
  }
}
