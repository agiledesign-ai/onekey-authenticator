import { Toast } from '../common/utils/ToastUtil';
import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsActionRow } from '../features/settings/components/SettingsActionRow';
import { SettingsRoutes } from '../features/settings/model/SettingsDetailPolicy';
import { CloudFeaturePolicy } from '../features/cloud/model/CloudFeaturePolicy';
import { FaceAuthResult, FaceUnlockPolicy } from '../features/security/model/FaceUnlockPolicy';
import { FaceAuthService } from '../features/security/service/FaceAuthService';
import { FaceUnlockRuntime } from '../features/security/service/FaceUnlockRuntime';

/** 人脸解锁与数据备份的设置二级页。 */
@Entry
@Component
struct SecurityBackupPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @StorageLink('faceUnlockEnabled') private faceUnlockEnabled: boolean = false;
  @State private faceUnlockBusy: boolean = false;
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
      SettingsDetailHeader({ title: '安全与备份', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column() {
          this.buildSectionLabel('安全', true)
          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text('人脸解锁')
                .fontSize(PageLayout.SETTINGS_ROW_TITLE_SIZE)
                .fontWeight(PageLayout.SETTINGS_ROW_TITLE_WEIGHT, { enableVariableFontWeight: true })
                .fontColor(Colors.textPrimary)
              Text('启动或返回应用时验证人脸')
                .fontSize(PageLayout.SETTINGS_ROW_BODY_SIZE)
                .fontColor(Colors.textSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (this.faceUnlockBusy) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(Colors.brand)
            } else {
              Toggle({ type: ToggleType.Switch, isOn: this.faceUnlockEnabled })
                .selectedColor(Colors.brand)
                .enabled(!this.faceUnlockBusy)
                .onChange((enabled: boolean) => this.changeFaceUnlock(enabled))
            }
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 16, bottom: 16 })
          .alignItems(VerticalAlign.Center)
          .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
          .backgroundColor(Colors.card)
          .border({ width: 1, color: Colors.border })

          this.buildSectionLabel('数据与备份')
          Column() {
            if (CloudFeaturePolicy.isEnabled()) {
              SettingsActionRow({
                icon: $r('sys.symbol.icloud'),
                title: '华为云空间',
                desc: '登录后可自动同步或手动推送、获取',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.CLOUD_SPACE); }
              })
              this.buildDivider()
            }
            SettingsActionRow({
              icon: $r('sys.symbol.arrow_up_circle'),
              title: '导出数据',
              desc: '勾选账号后导出 JSON',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.openDetail(SettingsRoutes.EXPORT); }
            })
            this.buildDivider()
            SettingsActionRow({
              icon: $r('sys.symbol.arrow_down_circle'),
              title: '导入数据',
              desc: '从备份恢复账号',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.openDetail(SettingsRoutes.IMPORT); }
            })
            this.buildDivider()
            SettingsActionRow({
              icon: $r('sys.symbol.square_grid_2x2'),
              title: '服务卡片',
              desc: '选择令牌并添加到桌面',
              iconBg: Colors.brandLight,
              iconColor: Colors.brand,
              onTap: () => { this.openDetail(SettingsRoutes.CARD_CONFIG); }
            })
          }
          .width('100%')
          .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
          .clip(true)
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

  private async openDetail(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch {
      Toast.error('页面打开失败');
    }
  }

  /** 开启前必须立即完成人脸验证，失败时不保存开关。 */
  private async changeFaceUnlock(enabled: boolean): Promise<void> {
    if (this.faceUnlockBusy) {
      return;
    }
    if (!enabled) {
      FaceUnlockRuntime.disable();
      Toast.success('人脸解锁已关闭');
      return;
    }

    this.faceUnlockBusy = true;
    const availability: FaceAuthResult = FaceAuthService.checkAvailability();
    if (availability !== FaceAuthResult.SUCCESS) {
      this.faceUnlockBusy = false;
      Toast.error(FaceUnlockPolicy.messageFor(availability));
      return;
    }

    const result: FaceAuthResult = await FaceAuthService.authenticate();
    if (FaceUnlockPolicy.canEnable(result)) {
      FaceUnlockRuntime.enable();
      Toast.success('人脸解锁已开启');
    } else {
      Toast.error(FaceUnlockPolicy.messageFor(result));
    }
    this.faceUnlockBusy = false;
  }
}
