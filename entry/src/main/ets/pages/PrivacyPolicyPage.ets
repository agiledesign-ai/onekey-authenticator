import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import {
  PrivacyArticle,
  PrivacyArticleSection,
  PrivacyParagraph,
  SettingsDetailContent
} from '../features/settings/model/SettingsDetailContent';

/** 隐私政策：条款式长文排版，布局参考开源验证器用户协议。 */
@Entry
@Component
struct PrivacyPolicyPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private article: PrivacyArticle = SettingsDetailContent.privacyArticle();

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
      SettingsDetailHeader({ title: '隐私政策', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          Text(this.article.title)
            .width('100%')
            .fontSize(22)
            .lineHeight(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .margin({ bottom: 4 })

          Text(this.article.updatedAt)
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(Colors.textSecondary)

          Text(this.article.effectiveAt)
            .width('100%')
            .fontSize(13)
            .lineHeight(20)
            .fontColor(Colors.textSecondary)

          Text(this.article.notice)
            .width('100%')
            .fontSize(14)
            .lineHeight(22)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .margin({ top: 18, bottom: 4 })
            .borderRadius(12)
            .backgroundColor(Colors.chipBg)
            .border({ width: 1, color: Colors.brand })

          ForEach(this.article.sections, (section: PrivacyArticleSection) => {
            Text(section.heading)
              .width('100%')
              .fontSize(17)
              .lineHeight(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.textPrimary)
              .margin({ top: 22, bottom: 4 })

            ForEach(section.paragraphs, (paragraph: PrivacyParagraph, index: number) => {
              Text(paragraph.text)
                .width('100%')
                .fontSize(14)
                .lineHeight(24)
                .fontWeight(paragraph.emphasized ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(Colors.textPrimary)
                .margin({ top: 6 })
            }, (paragraph: PrivacyParagraph, index: number) => `${section.heading}-${index}`)
          }, (section: PrivacyArticleSection) => section.heading)

          Column({ space: 14 }) {
            Divider()
              .color(Colors.divider)
            Text(this.article.footer)
              .width('100%')
              .fontSize(13)
              .lineHeight(20)
              .fontColor(Colors.textSecondary)
          }
          .width('100%')
          .margin({ top: 26 })

          Column().height(this.bottomInset + 28)
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
