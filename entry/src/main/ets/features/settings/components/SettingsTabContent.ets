import { Toast } from '../../../common/utils/ToastUtil';
import { Colors, ThemeManager } from '../../../common/theme/Theme';
import { SegmentedControl } from '../../../components/SegmentedControl';
import { PageLayout } from '../../../common/theme/Metrics';
import { SettingsRoutes } from '../model/SettingsDetailPolicy';
import { SettingsActionRow } from './SettingsActionRow';

/**
 * 设置页签：外观主题 / 安全与备份入口 / 关于。
 */
@Component
export struct SettingsTabContent {
  @Prop statusBarHeight: number = 0;
  @Prop showBack: boolean = false;
  @StorageProp('themeMode') private themeMode: number = ThemeManager.SYSTEM;
  private themeOptions: string[] = ['浅色', '深色', '跟随系统'];

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: ['100%', this.statusBarHeight + 172],
          radius: 250,
          colors: [[Colors.homeAmbient, 0], [Colors.transparent, 1]]
        })

      Column() {
        Column() {
          Row({ space: 12 }) {
            if (this.showBack) {
              Button({ type: ButtonType.Circle }) {
                SymbolGlyph($r('sys.symbol.chevron_backward'))
                  .fontSize(22)
                  .fontColor([Colors.textPrimary])
              }
              .width(40)
              .height(40)
              .backgroundColor(Colors.chipBg)
              .hitTestBehavior(HitTestMode.Block)
              .onClick(() => { this.backToHome(); })
              .accessibilityText('返回')
            }

            Text('设置')
              .fontSize(PageLayout.SETTINGS_TITLE_SIZE)
              .fontWeight(PageLayout.SETTINGS_TITLE_WEIGHT, { enableVariableFontWeight: true })
              .fontColor(Colors.textPrimary)
              .letterSpacing(-0.6)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: PageLayout.HEADER_HORIZONTAL_INSET,
          right: PageLayout.HEADER_HORIZONTAL_INSET,
          top: this.statusBarHeight + 14,
          bottom: 14
        })

        Scroll() {
          Column({ space: 0 }) {
            Column({ space: 11 }) {
              Text('外观主题')
                .fontSize(PageLayout.SETTINGS_ROW_TITLE_SIZE)
                .fontWeight(PageLayout.SETTINGS_ROW_TITLE_WEIGHT, { enableVariableFontWeight: true })
                .fontColor(Colors.textPrimary)

              SegmentedControl({
                options: this.themeOptions,
                selectedIndex: this.themeMode,
                onSelect: (i: number) => {
                  ThemeManager.setMode(i);
                  Toast.show(`已切换至${this.themeOptions[i]}模式`);
                }
              })
            }
            .width('100%')
            .padding({ left: 14, right: 14, top: 13, bottom: 13 })
            .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })
            .shadow({ radius: 12, color: Colors.shadow, offsetX: 0, offsetY: 4 })

            Column() {
              SettingsActionRow({
                icon: $r('sys.symbol.checkmark_shield_fill'),
                title: '安全与备份',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.SECURITY_BACKUP); }
              })
            }
            .width('100%')
            .margin({ top: 14 })
            .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
            .clip(true)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })
            .shadow({ radius: 12, color: Colors.shadow, offsetX: 0, offsetY: 4 })

            this.buildSectionLabel('关于与安全')
            Column() {
              SettingsActionRow({
                icon: $r('sys.symbol.qrcode'),
                title: '2FA 指南',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.TWO_FACTOR_GUIDE); }
              })
              this.buildDivider()
              SettingsActionRow({
                icon: $r('sys.symbol.envelope'),
                title: '建议反馈',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.FEEDBACK); }
              })
              this.buildDivider()
              SettingsActionRow({
                icon: $r('sys.symbol.info_circle'),
                title: '关于应用',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.ABOUT); }
              })
              this.buildDivider()
              SettingsActionRow({
                icon: $r('sys.symbol.doc_text'),
                title: '隐私政策',
                iconBg: Colors.brandLight,
                iconColor: Colors.brand,
                onTap: () => { this.openDetail(SettingsRoutes.PRIVACY); }
              })
              this.buildDivider()
              SettingsActionRow({
                icon: $r('sys.symbol.trash'),
                title: '清空所有账号',
                iconBg: Colors.chipBg,
                iconColor: Colors.warning,
                onTap: () => { this.openDetail(SettingsRoutes.CLEAR); }
              })
            }
            .width('100%')
            .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
            .clip(true)
            .backgroundColor(Colors.card)
            .border({ width: 1, color: Colors.border })
            .shadow({ radius: 12, color: Colors.shadow, offsetX: 0, offsetY: 4 })

            Column().height(PageLayout.CONTENT_BOTTOM_INSET)
          }
          .width('100%')
          .constraintSize({ minHeight: '100%' })
          .padding({
            left: PageLayout.CONTENT_HORIZONTAL_INSET,
            right: PageLayout.CONTENT_HORIZONTAL_INSET
          })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
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
  buildSectionLabel(title: string) {
    Text(title)
      .fontSize(PageLayout.SETTINGS_SECTION_SIZE)
      .fontWeight(PageLayout.SETTINGS_SECTION_WEIGHT, { enableVariableFontWeight: true })
      .fontColor(Colors.textSecondary)
      .margin({ top: 14, bottom: 7, left: 4 })
  }

  @Builder
  buildDivider() {
    Divider()
      .color(Colors.divider)
      .strokeWidth(1)
      .margin({ left: 63, right: 14 })
  }

  /** 页面路由只能在点击后调用，失败时给出明确反馈。 */
  private async openDetail(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch {
      Toast.error('页面打开失败');
    }
  }

  private backToHome(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch {
      Toast.error('返回失败');
    }
  }
}
