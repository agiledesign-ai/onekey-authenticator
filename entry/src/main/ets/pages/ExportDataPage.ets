import { Colors, Spacing } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AccountStore } from '../common/store/AccountStore';
import { BackupUtil } from '../common/utils/BackupUtil';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailStatusRow } from '../features/settings/components/SettingsDetailStatusRow';
import { SettingsDetailActionBar } from '../features/settings/components/SettingsDetailActionBar';
import { ExportSelectionPolicy } from '../features/backup/model/ExportSelectionPolicy';
import { AccountItem } from '../model/AccountItem';

/** 导出备份操作页：勾选要写入 JSON 的账号。 */
@Entry
@Component
struct ExportDataPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @State accounts: AccountItem[] = [];
  @State selectedIds: string[] = [];
  @State busy: boolean = false;
  @State resultMessage: string = '';
  @State resultSuccess: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;

  aboutToAppear(): void {
    this.accounts = ExportSelectionPolicy.visibleAccounts(AccountStore.list());
    this.selectedIds = ExportSelectionPolicy.selectAll(this.accounts);
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
      SettingsDetailHeader({ title: '导出数据', statusBarHeight: this.statusBarHeight })

      Column() {
        Text('导出会生成明文 JSON 备份，请妥善保管，不要上传网盘或发给他人。')
          .fontSize(15)
          .lineHeight(22)
          .fontColor(Colors.textSecondary)
          .width('100%')

        this.buildSelectionHeader()

        if (this.accounts.length === 0) {
          Text('暂无账号')
            .fontSize(14)
            .fontColor(Colors.textSecondary)
            .width('100%')
            .margin({ top: 24 })
        } else {
          Scroll() {
            Column() {
              ForEach(this.accounts, (account: AccountItem) => {
                this.buildAccountRow(account)
              }, (account: AccountItem) => account.id)
            }
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .margin({ top: 10 })
        }

        if (this.resultMessage.length > 0) {
          SettingsDetailStatusRow({
            message: this.resultMessage,
            success: this.resultSuccess
          })
            .margin({ top: 16 })
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
        label: '导出备份',
        helper: this.exportHelper(),
        actionEnabled: this.canExport(),
        busy: this.busy,
        bottomInset: this.bottomInset,
        onTap: () => { this.exportAccounts(); }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  private buildSelectionHeader() {
    Row() {
      Text(`已选 ${this.selectedIds.length} / ${this.accounts.length}`)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textPrimary)

      Blank()

      Text(ExportSelectionPolicy.isAllSelected(this.selectedIds, this.accounts) ? '取消全选' : '全选')
        .fontSize(14)
        .fontColor(this.accounts.length > 0 ? Colors.brand : Colors.textSecondary)
        .onClick(() => this.toggleSelectAll())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .margin({ top: Spacing.l })
    .backgroundColor(Colors.card)
    .borderRadius(16)
    .border({ width: 1, color: Colors.border })
  }

  @Builder
  private buildAccountRow(account: AccountItem) {
    Row({ space: 12 }) {
      Checkbox()
        .select(this.selectedIds.indexOf(account.id) >= 0)
        .selectedColor(Colors.brand)
        .width(20)
        .height(20)
        .onChange((checked: boolean) => {
          this.selectedIds = ExportSelectionPolicy.setSelected(
            account.id, checked, this.selectedIds, this.accounts
          );
        })

      Column({ space: 2 }) {
        Text(account.serviceName)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(account.accountName)
          .fontSize(12)
          .fontColor(Colors.textSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .margin({ bottom: 8 })
    .backgroundColor(Colors.card)
    .borderRadius(12)
    .border({ width: 1, color: Colors.border })
    .onClick(() => {
      const checked: boolean = this.selectedIds.indexOf(account.id) < 0;
      this.selectedIds = ExportSelectionPolicy.setSelected(
        account.id, checked, this.selectedIds, this.accounts
      );
    })
  }

  private toggleSelectAll(): void {
    if (this.accounts.length === 0) {
      return;
    }
    this.selectedIds = ExportSelectionPolicy.isAllSelected(this.selectedIds, this.accounts) ?
      [] : ExportSelectionPolicy.selectAll(this.accounts);
  }

  private canExport(): boolean {
    return ExportSelectionPolicy.canExport(this.accounts.length, this.selectedIds.length);
  }

  private exportHelper(): string {
    return ExportSelectionPolicy.helper(this.accounts.length, this.selectedIds.length);
  }

  private async exportAccounts(): Promise<void> {
    if (this.busy ||
      !this.canExport()) {
      return;
    }
    this.busy = true;
    const selectedAccounts: AccountItem[] = ExportSelectionPolicy.pickAccounts(this.accounts, this.selectedIds);
    const result = await BackupUtil.exportAccounts(selectedAccounts);
    this.resultSuccess = result.success;
    this.resultMessage = result.message;
    this.busy = false;
    Toast.show(result.message);
  }
}
