import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AccountStore } from '../common/store/AccountStore';
import { BackupPreviewResult, BackupResult, BackupUtil } from '../common/utils/BackupUtil';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailStatusRow } from '../features/settings/components/SettingsDetailStatusRow';
import { SettingsDetailActionBar } from '../features/settings/components/SettingsDetailActionBar';
import {
  SettingsDetailKind,
  SettingsDetailPolicy
} from '../features/settings/model/SettingsDetailPolicy';

/** 导入备份操作页。 */
@Entry
@Component
struct ImportDataPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @State accountCount: number = 0;
  @State busy: boolean = false;
  @State resultMessage: string = '';
  @State resultSuccess: boolean = false;
  @State backupPassword: string = '';
  @StorageProp('themeMode') private _themeMode: number = 0;

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
      SettingsDetailHeader({ title: '导入数据', statusBarHeight: this.statusBarHeight })

      Column() {
        Text('支持 .skvault、.json、.csv、.tsv、.txt、.otpauth、.maFile、.2fas。加密备份需要密码，明文文件可直接导入，重复账号会跳过。')
          .fontSize(15)
          .lineHeight(22)
          .fontColor(Colors.textSecondary)
          .width('100%')

        Column({ space: 8 }) {
          Text('备份密码')
            .fontSize(13)
            .fontColor(Colors.hint)
          TextInput({ text: $$this.backupPassword, placeholder: '仅 .skvault 需要，其他格式可留空' })
            .type(InputType.Password)
            .showPasswordIcon(true)
            .height(50)
            .fontColor(Colors.textPrimary)
            .placeholderColor(Colors.hint)
            .backgroundColor(Colors.chipBg)
            .borderRadius(12)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 20 })

        if (this.resultMessage.length > 0) {
          SettingsDetailStatusRow({
            message: this.resultMessage,
            success: this.resultSuccess
          })
            .margin({ top: 20 })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
        right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
        top: 18
      })

      SettingsDetailActionBar({
        label: '选择备份文件',
        helper: this.backupPassword.length > 0 && this.backupPassword.length < 8 ?
          '加密备份密码至少 8 位' : '',
        actionEnabled: SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.IMPORT, this.accountCount),
        busy: this.busy,
        bottomInset: this.bottomInset,
        onTap: () => { this.importAccounts(); }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  private async importAccounts(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    const password: string = this.backupPassword;
    const preview: BackupPreviewResult = await BackupUtil.previewImport(password);
    this.backupPassword = '';
    if (!preview.success) {
      this.finish(preview.success, preview.message);
      return;
    }
    if (preview.summary.imported === 0) {
      const message: string = preview.summary.duplicates > 0
        ? `没有可导入的新账号，已识别 ${preview.summary.duplicates} 个重复账号`
        : '文件中没有有效账号';
      this.finish(false, message);
      return;
    }

    try {
      const result = await this.getUIContext().getPromptAction().showDialog({
        title: '确认导入账号',
        message: `可导入 ${preview.summary.imported} 个，重复 ${preview.summary.duplicates} 个` +
          (preview.summary.invalid > 0 ? `，无效 ${preview.summary.invalid} 个` : '') +
          '。确认后将写入本机安全存储。',
        buttons: [
          { text: '取消', color: Colors.hint },
          { text: '确认导入', color: Colors.brand }
        ]
      });
      if (result.index !== 1) {
        this.finish(false, '已取消导入');
        return;
      }
      const importResult: BackupResult = BackupUtil.applyImport(preview.accounts);
      if (importResult.success) {
        this.accountCount = AccountStore.list().length;
      }
      this.finish(importResult.success, importResult.message);
    } catch {
      this.finish(false, '无法打开确认窗口，请稍后重试');
    }
  }

  private finish(success: boolean, message: string): void {
    this.resultSuccess = success;
    this.resultMessage = message;
    this.busy = false;
    Toast.show(message);
  }
}
