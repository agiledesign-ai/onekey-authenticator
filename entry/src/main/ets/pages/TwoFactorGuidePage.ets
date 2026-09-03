import { Colors, Radius, Spacing } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailIntro } from '../features/settings/components/SettingsDetailIntro';

/** 介绍二次验证账号的扫码与手动添加流程。 */
@Entry
@Component
struct TwoFactorGuidePage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageProp('themeMode') private _themeMode: number = 0;

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
      SettingsDetailHeader({ title: '2FA 指南', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          SettingsDetailIntro({
            title: '添加双重验证',
            description: '先在目标服务的安全设置中开启双重验证，再使用2FA验证器扫描二维码或输入服务提供的密钥。'
          })

          this.buildScanGuide()
          this.buildManualGuide()
          this.buildSafetyNotice()

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

  @Builder
  private buildScanGuide() {
    Column({ space: Spacing.m }) {
      Text('扫描二维码')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')

      Image($r('app.media.two_factor_scan_guide'))
        .width('100%')
        .aspectRatio(1.5)
        .objectFit(ImageFit.Cover)
        .borderRadius(Radius.md)

      Row() {
        this.buildStep(1, '进入添加页')
        this.buildStep(2, '扫描服务二维码')
        this.buildStep(3, '确认账号已添加')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: PageLayout.DETAIL_SECTION_GAP })
  }

  @Builder
  private buildManualGuide() {
    Column({ space: Spacing.m }) {
      Text('手动输入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .width('100%')

      Image($r('app.media.two_factor_manual_guide'))
        .width('100%')
        .aspectRatio(1.5)
        .objectFit(ImageFit.Cover)
        .borderRadius(Radius.md)

      Row() {
        this.buildStep(1, '选择手动输入')
        this.buildStep(2, '填写账号与密钥')
        this.buildStep(3, '确认保存')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: PageLayout.DETAIL_SECTION_GAP })
  }

  @Builder
  private buildStep(index: number, title: string) {
    Column({ space: Spacing.s }) {
      Column() {
        Text(`${index}`)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.onColor)
      }
      .width(24)
      .height(24)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(Radius.full)
      .backgroundColor(Colors.brand)

      Text(title)
        .fontSize(12)
        .lineHeight(18)
        .fontColor(Colors.hint)
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildSafetyNotice() {
    Row({ space: Spacing.m }) {
      SymbolGlyph($r('sys.symbol.lock_shield'))
        .fontSize(26)
        .fontColor([Colors.brand])

      Text('二维码和密钥等同于账号凭据，请勿分享、截图后上传或保存到公开位置。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor(Colors.textPrimary)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding(Spacing.l)
    .borderRadius(Radius.md)
    .backgroundColor(Colors.brandLight)
    .margin({ top: PageLayout.DETAIL_SECTION_GAP })
  }
}
