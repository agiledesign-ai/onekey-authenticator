import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AccountStore } from '../common/store/AccountStore';
import { Log } from '../common/utils/LogUtil';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailListSection } from '../features/settings/components/SettingsDetailListSection';
import { SettingsDetailStatusRow } from '../features/settings/components/SettingsDetailStatusRow';
import { SettingsDetailActionBar } from '../features/settings/components/SettingsDetailActionBar';
import {
  SettingsDetailContent,
  SettingsDetailSection
} from '../features/settings/model/SettingsDetailContent';
import {
  SettingsDetailKind,
  SettingsDetailPolicy
} from '../features/settings/model/SettingsDetailPolicy';

/** 清空账号风险说明与二次确认页。 */
@Entry
@Component
struct ClearAccountsPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @State accountCount: number = 0;
  @State busy: boolean = false;
  @State resultMessage: string = '';
  @State resultSuccess: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private sections: SettingsDetailSection[] = SettingsDetailContent.clearSections();
  private confirming: boolean = false;

  aboutToAppear(): void {
    this.accountCount = AccountStore.list().length;
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
      SettingsDetailHeader({ title: '清空所有账号', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          Text('清空后无法在应用内撤销。请先保存备份，并确认你持有各个服务的恢复码。')
            .fontSize(15)
            .lineHeight(23)
            .fontColor(Colors.textSecondary)
            .width('100%')

          if (this.resultMessage.length > 0) {
            SettingsDetailStatusRow({
              message: this.resultMessage,
              success: this.resultSuccess
            })
              .margin({ top: 16 })
          }

          ForEach(this.sections, (section: SettingsDetailSection) => {
            SettingsDetailListSection({ section: section })
              .margin({ top: 22 })
          }, (section: SettingsDetailSection) => section.title)

          if (this.accountCount > 0) {
            Text(`本机现有 ${this.accountCount} 个账号，确认后将永久删除。`)
              .fontSize(14)
              .lineHeight(21)
              .fontColor(Colors.warning)
              .width('100%')
              .margin({ top: 18 })
          }
        }
        .width('100%')
        .padding({
          left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          top: 18,
          bottom: 20
        })
      }
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      SettingsDetailActionBar({
        label: '清空所有账号',
        helper: this.accountCount > 0 ? '' : '当前没有可清空的账号',
        actionEnabled: SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.CLEAR, this.accountCount),
        busy: this.busy,
        dangerous: true,
        bottomInset: this.bottomInset,
        onTap: () => { this.confirmClear(); }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  private async confirmClear(): Promise<void> {
    if (this.confirming || this.busy ||
      !SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.CLEAR, this.accountCount)) {
      return;
    }
    this.confirming = true;
    let confirmed: boolean = false;
    try {
      const result = await this.getUIContext().getPromptAction().showDialog({
        title: '确认清空所有账号',
        message: `将永久删除 ${this.accountCount} 个验证器账号。外部服务的双重验证不会自动关闭。若已开启云空间自动同步，这些账号也会从云空间删除。`,
        buttons: [
          { text: '取消', color: Colors.hint },
          { text: '确认清空', color: Colors.warning }
        ]
      });
      confirmed = SettingsDetailPolicy.shouldClearAccounts(result.index === 1, this.accountCount);
    } catch (err) {
      Log.e('ClearAccountsPage.confirmClear dialog failed: ' + JSON.stringify(err));
      this.resultSuccess = false;
      this.resultMessage = '无法打开确认窗口，请稍后重试。';
      Toast.error(this.resultMessage);
      this.confirming = false;
      return;
    }
    if (!confirmed) {
      this.confirming = false;
      return;
    }
    this.busy = true;
    try {
      AccountStore.clear();
      this.accountCount = AccountStore.list().length;
      this.resultSuccess = true;
      this.resultMessage = '所有验证器账号已从本机删除。';
      Toast.success('所有账号已清空');
    } catch (err) {
      Log.e('ClearAccountsPage.confirmClear storage failed: ' + JSON.stringify(err));
      this.resultSuccess = false;
      this.resultMessage = '无法清空账号，请稍后重试。';
      Toast.error(this.resultMessage);
    }
    this.busy = false;
    this.confirming = false;
  }
}
