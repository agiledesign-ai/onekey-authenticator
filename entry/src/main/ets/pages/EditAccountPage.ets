import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AccountStore } from '../common/store/AccountStore';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { AccountItem, getBadgeColor } from '../model/AccountItem';
import { OtpType } from '../model/OtpType';
import { LabeledSegmentedControl } from '../components/LabeledSegmentedControl';

interface EditAccountParams {
  accountId: string;
}

/** 编辑账号显示信息；密钥仅原样保留，不在页面中明文回显。 */
@Entry
@Component
struct EditAccountPage {
  @State statusBarHeight: number = 0;
  @State serviceName: string = '';
  @State accountName: string = '';
  @State accountId: string = '';
  @State loaded: boolean = false;
  @State algorithmIndex: number = 0;
  @State digitsIndex: number = 0;
  @State periodIndex: number = 1;
  @State pinned: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private original: AccountItem | null = null;
  private algorithmOptions: string[] = ['SHA-1', 'SHA-256', 'SHA-512'];
  private algorithmValues: string[] = ['SHA1', 'SHA256', 'SHA512'];
  private digitsOptions: string[] = ['6 位', '8 位'];
  private digitsValues: number[] = [6, 8];
  private periodOptions: string[] = ['15 秒', '30 秒', '60 秒'];
  private periodValues: number[] = [15, 30, 60];

  aboutToAppear(): void {
    const params: EditAccountParams = this.getUIContext().getRouter().getParams() as EditAccountParams;
    this.accountId = params.accountId;
    this.original = AccountStore.get(this.accountId);
    if (this.original !== null) {
      this.serviceName = this.original.serviceName;
      this.accountName = this.original.accountName;
      this.algorithmIndex = Math.max(0, this.algorithmValues.indexOf(this.original.algorithm));
      this.digitsIndex = Math.max(0, this.digitsValues.indexOf(this.original.digits));
      this.periodIndex = Math.max(0, this.periodValues.indexOf(this.original.period));
      this.pinned = this.original.pinned;
      this.loaded = true;
    }

    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
    }
  }

  build() {
    Column() {
      SettingsDetailHeader({ title: '管理账号', statusBarHeight: this.statusBarHeight })

      if (this.loaded) {
        Scroll() {
          Column({ space: 18 }) {
            this.buildField('服务名称', '如 GitHub', true)
            this.buildField('账号名称', '如 astra@example.com', false)
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('置顶账号')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Colors.textPrimary)
                Text('置顶后显示在列表最上方')
                  .fontSize(12)
                  .fontColor(Colors.textSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.pinned })
                .selectedColor(Colors.brand)
                .onChange((enabled: boolean) => {
                  this.pinned = enabled;
                })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 12, bottom: 12 })
            .borderRadius(14)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })

            if (this.original !== null && this.original.type === OtpType.TOTP) {
              LabeledSegmentedControl({
                label: '算法',
                options: this.algorithmOptions,
                selectedIndex: this.algorithmIndex
              })
              LabeledSegmentedControl({
                label: '验证码位数',
                options: this.digitsOptions,
                selectedIndex: this.digitsIndex
              })
              LabeledSegmentedControl({
                label: '刷新周期',
                options: this.periodOptions,
                selectedIndex: this.periodIndex
              })
            } else if (this.original !== null && this.original.type === OtpType.HOTP) {
              LabeledSegmentedControl({
                label: '算法',
                options: this.algorithmOptions,
                selectedIndex: this.algorithmIndex
              })
              LabeledSegmentedControl({
                label: '验证码位数',
                options: this.digitsOptions,
                selectedIndex: this.digitsIndex
              })
            }

            Row({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.lock_fill'))
                .fontSize(18)
                .fontColor([Colors.success])
              Text('验证密钥已保存在系统安全存储中，此处不会明文显示。')
                .fontSize(13)
                .lineHeight(19)
                .fontColor(Colors.textSecondary)
                .layoutWeight(1)
            }
            .width('100%')
            .padding(14)
            .backgroundColor(Colors.card)
            .borderRadius(14)
            .border({ width: 1, color: Colors.border })

            Button('保存修改')
              .width('100%')
              .height(50)
              .enabled(this.canSave())
              .fontColor(Colors.onColor)
              .backgroundColor(this.canSave() ? Colors.brand : Colors.disabled)
              .onClick(() => this.save())

            Button('删除账号')
              .width('100%')
              .height(48)
              .fontColor(Colors.warning)
              .backgroundColor(Colors.transparent)
              .border({ width: 1, color: Colors.warning })
              .onClick(() => this.confirmDelete())
          }
          .width('100%')
          .padding({
            left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
            right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
            top: PageLayout.FIRST_SECTION_TOP,
            bottom: 40
          })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      } else {
        Column({ space: 12 }) {
          Text('账号不存在或已被删除')
            .fontSize(17)
            .fontColor(Colors.textPrimary)
          Button('返回')
            .onClick(() => this.getUIContext().getRouter().back())
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  private buildField(label: string, placeholder: string, serviceField: boolean) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.hint)
      if (serviceField) {
        TextInput({ text: $$this.serviceName, placeholder: placeholder })
          .height(50)
          .fontColor(Colors.textPrimary)
          .placeholderColor(Colors.hint)
          .backgroundColor(Colors.chipBg)
          .borderRadius(12)
      } else {
        TextInput({ text: $$this.accountName, placeholder: placeholder })
          .height(50)
          .fontColor(Colors.textPrimary)
          .placeholderColor(Colors.hint)
          .backgroundColor(Colors.chipBg)
          .borderRadius(12)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private canSave(): boolean {
    return this.serviceName.trim().length > 0 && this.original !== null;
  }

  private save(): void {
    if (!this.canSave() || this.original === null) {
      return;
    }
    const updated: AccountItem = {
      id: this.original.id,
      type: this.original.type,
      serviceName: this.serviceName,
      accountName: this.accountName,
      badgeColor: getBadgeColor(this.serviceName.trim()),
      secretKey: this.original.secretKey,
      algorithm: this.original.type === OtpType.STEAM ? this.original.algorithm : this.algorithmValues[this.algorithmIndex],
      digits: this.original.type === OtpType.STEAM ? this.original.digits : this.digitsValues[this.digitsIndex],
      period: this.original.type === OtpType.TOTP ? this.periodValues[this.periodIndex] : this.original.period,
      counter: this.original.counter,
      groupId: this.original.groupId,
      pinned: this.pinned,
      sortIndex: this.original.sortIndex,
      createdAt: this.original.createdAt,
      updatedAt: this.original.updatedAt,
      schemaVersion: this.original.schemaVersion
    };
    if (!AccountStore.update(updated)) {
      Toast.error('保存失败，请检查账号信息');
      return;
    }
    Toast.success('账号信息已更新');
    this.getUIContext().getRouter().back();
  }

  private async confirmDelete(): Promise<void> {
    if (this.original === null) {
      return;
    }
    const result = await this.getUIContext().getPromptAction().showDialog({
      title: '删除账号',
      message: `确定删除「${this.original.serviceName}」吗？删除后无法恢复。`,
      buttons: [
        { text: '取消', color: Colors.hint },
        { text: '删除', color: Colors.warning }
      ]
    });
    if (result.index === 1) {
      AccountStore.remove(this.original.id);
      Toast.success('账号已删除');
      this.getUIContext().getRouter().back();
    }
  }
}
