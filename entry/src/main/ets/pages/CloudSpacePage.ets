import { common } from '@kit.AbilityKit';
import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsActionRow } from '../features/settings/components/SettingsActionRow';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { CloudSettingsStore } from '../features/cloud/store/CloudSettingsStore';
import { CloudSyncRuntime } from '../features/cloud/service/CloudSyncRuntime';
import { CloudCommandResult } from '../features/cloud/model/CloudSyncState';
import { CloudAutoSyncPolicy } from '../features/cloud/model/CloudAutoSyncPolicy';

/** 华为云空间：账号、自动同步、手动推送/获取与状态。 */
@Entry
@Component
struct CloudSpacePage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageLink('huaweiLoggedIn') private loggedIn: boolean = false;
  @StorageLink('huaweiNickname') private nickname: string = '';
  @StorageLink('cloudAutoSyncEnabled') private autoSync: boolean = false;
  @StorageLink('cloudSyncStatus') private syncStatus: string = '尚未同步';
  @StorageLink('cloudLastSyncTime') private lastSyncTime: number = 0;
  @StorageLink('cloudSyncing') private syncing: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;
  @State systemAccountName: string = '';
  @State switchEpoch: number = 0;

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
    this.restoreAccount();
  }

  build() {
    Column() {
      SettingsDetailHeader({ title: '华为云空间', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          this.buildSectionLabel('华为账号', true)
          if (this.loggedIn) {
            Column() {
              SettingsActionRow({
                icon: $r('sys.symbol.person'),
                title: this.nickname.length > 0 ? this.nickname : '华为账号',
                desc: '退出后自动同步会关闭，两边的数据都不会删除',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.confirmLogout(); }
              })
            }
            .width('100%')
            .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
            .clip(true)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })
          } else {
            Column() {
              SettingsActionRow({
                icon: $r('sys.symbol.person'),
                title: this.systemAccountName.length > 0 ? this.systemAccountName : '登录华为账号',
                desc: '授权后即可同步',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.login(); }
              })
            }
            .width('100%')
            .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
            .clip(true)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })
          }

          this.buildSectionLabel('同步设置')
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('云空间自动同步')
                .fontSize(PageLayout.SETTINGS_ROW_TITLE_SIZE)
                .fontWeight(PageLayout.SETTINGS_ROW_TITLE_WEIGHT, { enableVariableFontWeight: true })
                .fontColor(Colors.textPrimary)
              Text(this.loggedIn ? '开启后，增删改会跟随到云空间' : '请先登录后再开启')
                .fontSize(PageLayout.SETTINGS_ROW_BODY_SIZE)
                .fontColor(Colors.textSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.syncing) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Colors.brand)
            } else {
              ForEach([CloudAutoSyncPolicy.switchKey(this.loggedIn && this.autoSync, this.switchEpoch)],
                (_token: string) => {
                  Toggle({ type: ToggleType.Switch, isOn: this.loggedIn && this.autoSync })
                    .selectedColor(Colors.brand)
                    .enabled(CloudAutoSyncPolicy.canOperateSwitch(this.loggedIn, this.syncing))
                    .onChange((enabled: boolean) => this.changeAutoSync(enabled))
                }, (_token: string) => _token)
            }
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 16, bottom: 16 })
          .alignItems(VerticalAlign.Center)
          .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
          .backgroundColor(Colors.card)
          .border({ width: 1, color: Colors.border })
          .onClick(() => this.hintLoginIfNeeded())

          this.buildSectionLabel('同步操作')
          Column() {
            SettingsActionRow({
              icon: $r('sys.symbol.arrow_up_circle'),
              title: '手动推送',
              desc: this.loggedIn ? '把账号和分组推到云空间' : '请先登录',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.push(); }
            })
            this.buildDivider()
            SettingsActionRow({
              icon: $r('sys.symbol.arrow_down_circle'),
              title: '手动获取',
              desc: this.loggedIn ? '从云空间合并过来，不删多出来的账号' : '请先登录',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.pull(); }
            })
            this.buildDivider()
            SettingsActionRow({
              icon: $r('sys.symbol.icloud'),
              title: '云空间管理',
              desc: '在系统设置中为本应用开启云同步',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.openManager(); }
            })
          }
          .width('100%')
          .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
          .clip(true)
          .backgroundColor(Colors.card)
          .border({ width: 1, color: Colors.border })

          this.buildSectionLabel('同步记录')
          Column() {
            this.buildStatusRow('当前状态', this.syncStatus)
            this.buildDivider()
            this.buildStatusRow('最后同步时间', CloudSettingsStore.formatLastSyncTime(this.lastSyncTime))
            if (CloudSettingsStore.shouldShowCloudDisabledHint(this.syncStatus)) {
              Text('请点击「云空间管理」或前往「设置 → 华为账号 → 云空间」，找到2FA验证器并开启云同步。')
                .fontSize(12)
                .fontColor(Colors.textSecondary)
                .lineHeight(18)
                .width('100%')
                .padding({ left: 14, right: 14, top: 8, bottom: 12 })
            }
          }
          .width('100%')
          .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
          .backgroundColor(Colors.card)
          .border({ width: 1, color: Colors.border })

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
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  buildSectionLabel(title: string, first: boolean = false) {
    Text(title)
      .fontSize(PageLayout.SETTINGS_SECTION_SIZE)
      .fontWeight(PageLayout.SETTINGS_SECTION_WEIGHT, { enableVariableFontWeight: true })
      .fontColor(Colors.textSecondary)
      .margin({ top: first ? 0 : 14, bottom: 7, left: 4 })
  }

  @Builder
  buildDivider() {
    Divider()
      .color(Colors.divider)
      .strokeWidth(1)
      .margin({ left: 63, right: 14 })
  }

  @Builder
  buildStatusRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(PageLayout.SETTINGS_ROW_TITLE_SIZE)
        .fontWeight(PageLayout.SETTINGS_ROW_TITLE_WEIGHT, { enableVariableFontWeight: true })
        .fontColor(Colors.textPrimary)
        .width(126)
      if (this.syncing && label === '当前状态') {
        LoadingProgress()
          .width(18)
          .height(18)
          .color(Colors.brand)
          .margin({ right: 6 })
      }
      Text(value)
        .fontSize(PageLayout.SETTINGS_ROW_BODY_SIZE)
        .fontColor(Colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 16, bottom: 16 })
    .alignItems(VerticalAlign.Center)
  }

  private async restoreAccount(): Promise<void> {
    const result: CloudCommandResult = await CloudSyncRuntime.restoreAccount();
    if (!result.success) {
      this.systemAccountName = await CloudSyncRuntime.probeSystemAccountName();
    }
  }

  private async login(): Promise<void> {
    const host = this.getUIContext().getHostContext();
    if (!host) {
      Toast.error('无法拉起华为账号登录');
      return;
    }
    const result: CloudCommandResult = await CloudSyncRuntime.login(host as common.UIAbilityContext);
    if (result.success) {
      Toast.success(result.status);
    } else {
      Toast.error(result.status);
    }
  }

  private confirmLogout(): void {
    this.getUIContext().showAlertDialog({
      title: '确认退出登录',
      message: '退出后，云空间自动同步将同时关闭。两边的数据都不会删除。',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出',
        fontColor: Colors.warning,
        action: () => {
          this.logout();
        }
      }
    });
  }

  private async logout(): Promise<void> {
    await CloudSyncRuntime.logout();
    Toast.success('已退出登录');
  }

  private hintLoginIfNeeded(): void {
    if (!this.loggedIn) {
      Toast.error('请先登录');
    }
  }

  private rejectAutoSyncOn(): void {
    this.autoSync = false;
    this.switchEpoch = CloudAutoSyncPolicy.nextEpoch(this.switchEpoch, true);
    Toast.error('请先登录');
  }

  private async changeAutoSync(enabled: boolean): Promise<void> {
    if (this.syncing) {
      this.switchEpoch = CloudAutoSyncPolicy.nextEpoch(this.switchEpoch, true);
      Toast.show('正在同步，请稍候');
      return;
    }
    if (CloudAutoSyncPolicy.shouldRejectEnable(this.loggedIn, enabled)) {
      this.rejectAutoSyncOn();
      return;
    }
    if (!enabled) {
      const result: CloudCommandResult = await CloudSyncRuntime.disableAutoSync();
      Toast.show(result.status);
      return;
    }
    const result: CloudCommandResult = await CloudSyncRuntime.enableAutoSync();
    if (result.success) {
      Toast.success(result.status);
    } else {
      this.autoSync = false;
      this.switchEpoch = CloudAutoSyncPolicy.nextEpoch(this.switchEpoch, true);
      Toast.error(result.status);
    }
  }

  private async push(): Promise<void> {
    if (this.syncing) {
      Toast.show('正在同步，请稍候');
      return;
    }
    const result: CloudCommandResult = await CloudSyncRuntime.push();
    if (result.success) {
      Toast.success(result.status);
    } else {
      Toast.error(result.status);
    }
  }

  private async pull(): Promise<void> {
    if (this.syncing) {
      Toast.show('正在同步，请稍候');
      return;
    }
    const result: CloudCommandResult = await CloudSyncRuntime.pull();
    if (result.success) {
      Toast.success(result.status);
    } else {
      Toast.error(result.status);
    }
  }

  private async openManager(): Promise<void> {
    const opened: boolean = await CloudSyncRuntime.openCloudSpaceSettings();
    if (!opened) {
      Toast.show('请在系统设置中打开华为账号 > 云空间');
    }
  }
}
