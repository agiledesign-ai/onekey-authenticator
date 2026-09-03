import { common, Want } from '@kit.AbilityKit';
import { Colors, Radius, Spacing } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailActionBar } from '../features/settings/components/SettingsDetailActionBar';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailIntro } from '../features/settings/components/SettingsDetailIntro';
import { FeedbackMailPolicy } from '../features/settings/model/FeedbackMailPolicy';

/** 建议反馈页：将可选内容交给系统邮箱，由用户确认后发送。 */
@Entry
@Component
struct FeedbackPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @State feedbackContent: string = '';
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
      SettingsDetailHeader({ title: '建议反馈', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          SettingsDetailIntro({
            title: '告诉我们你的想法',
            description: '欢迎提交使用建议、问题反馈或功能想法。发送时会打开系统邮箱，由你确认邮件内容。'
          })

          this.buildRecipient()
          this.buildFeedbackInput()

          Column().height(Spacing.xl)
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

      SettingsDetailActionBar({
        label: '发送邮件反馈',
        bottomInset: this.bottomInset,
        onTap: () => { this.openFeedbackEmail(); }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  private buildRecipient() {
    Column({ space: Spacing.s }) {
      Text('收件邮箱')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textSecondary)
        .width('100%')

      Row({ space: Spacing.m }) {
        SymbolGlyph($r('sys.symbol.envelope'))
          .fontSize(22)
          .fontColor([Colors.brand])

        Text(FeedbackMailPolicy.recipient())
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textPrimary)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(Spacing.l)
      .borderRadius(Radius.md)
      .backgroundColor(Colors.card)
      .border({ width: 1, color: Colors.border })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: PageLayout.DETAIL_SECTION_GAP })
  }

  @Builder
  private buildFeedbackInput() {
    Column({ space: Spacing.s }) {
      Text('反馈内容（可选）')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textSecondary)
        .width('100%')

      TextArea({
        text: this.feedbackContent,
        placeholder: '请描述你的建议或遇到的问题'
      })
        .height(150)
        .width('100%')
        .fontSize(15)
        .fontColor(Colors.textPrimary)
        .placeholderColor(Colors.textSecondary)
        .backgroundColor(Colors.card)
        .borderRadius(Radius.md)
        .border({ width: 1, color: Colors.border })
        .padding(Spacing.l)
        .onChange((value: string) => {
          this.feedbackContent = value;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: PageLayout.DETAIL_SECTION_GAP })
  }

  /** 只负责拉起系统邮箱；反馈内容不会由应用自行上传。 */
  private async openFeedbackEmail(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.sendToData',
      uri: FeedbackMailPolicy.mailtoUri(this.feedbackContent)
    };
    try {
      await context.startAbility(want);
    } catch {
      Toast.error(FeedbackMailPolicy.failureMessage());
    }
  }
}
