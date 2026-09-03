import { Want } from '@kit.AbilityKit';
import { formInfo, formProvider } from '@kit.FormKit';
import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';
import { AccountStore } from '../common/store/AccountStore';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { SettingsDetailHeader } from '../features/settings/components/SettingsDetailHeader';
import { SettingsDetailActionBar } from '../features/settings/components/SettingsDetailActionBar';
import { AccountListPolicy } from '../features/account/model/AccountListPolicy';
import { CardOtpSlot, CardOtpView } from '../features/card/model/CardOtpView';
import { CardPreviewPolicy } from '../features/card/model/CardPreviewPolicy';
import { CardTokenPolicy } from '../features/card/model/CardTokenPolicy';
import { CardUpdateService } from '../features/card/service/CardUpdateService';
import { AccountItem } from '../model/AccountItem';
import { WidgetMediumBody, WidgetMinimumBody, WidgetSmallBody } from '../widget/pages/WidgetBodies';
import { WIDGET_CARD_RADIUS } from '../widget/pages/WidgetMetrics';

const PREVIEW_SIZES: string[] = ['1*2', '2*2', '2*4'];

/** 服务卡片：选择令牌并打开系统卡片管理器。 */
@Entry
@Component
struct CardConfigPage {
  @State statusBarHeight: number = 0;
  @State bottomInset: number = 0;
  @State accounts: AccountItem[] = [];
  @State selectedIds: string[] = [];
  @State previewSlots: CardOtpSlot[] = [];
  @State previewIndex: number = 0;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private previewTimer: number = -1;
  private previewSwiper: SwiperController = new SwiperController();

  aboutToAppear(): void {
    this.accounts = AccountListPolicy.filter(AccountStore.list(), '');
    this.selectedIds = CardUpdateService.tokenIds();
    this.refreshPreview();
    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
      WindowUtil.getBottomAvoidHeightPx(context).then((px: number) => {
        this.bottomInset = this.getUIContext().px2vp(px);
      });
    }
    this.previewTimer = setInterval(() => {
      this.refreshPreview();
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.previewTimer >= 0) {
      clearInterval(this.previewTimer);
      this.previewTimer = -1;
    }
  }

  build() {
    Column() {
      SettingsDetailHeader({ title: '服务卡片', statusBarHeight: this.statusBarHeight })

      Scroll() {
        Column({ space: 20 }) {
          this.buildHero()
          this.buildTokenSection()
        }
        .width('100%')
        .padding({
          left: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          right: PageLayout.DETAIL_CONTENT_HORIZONTAL_INSET,
          top: 8,
          bottom: 24
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      SettingsDetailActionBar({
        label: '添加至桌面',
        helper: CardPreviewPolicy.formManagerHelper(this.accounts.length),
        actionEnabled: CardPreviewPolicy.canOpenFormManager(this.accounts.length),
        bottomInset: this.bottomInset,
        onTap: () => this.openSystemFormManager()
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  @Builder
  private buildHero() {
    Column({ space: 10 }) {
      Text('令牌卡片')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
        .letterSpacing(-0.4)
      Text(CardPreviewPolicy.caption(CardTokenPolicy.maxSlots(PREVIEW_SIZES[this.previewIndex])))
        .fontSize(14)
        .fontColor(Colors.textSecondary)

      Swiper(this.previewSwiper) {
        this.buildPreviewPage(0)
        this.buildPreviewPage(1)
        this.buildPreviewPage(2)
      }
      .index(this.previewIndex)
      .autoPlay(true)
      .interval(CardPreviewPolicy.AUTO_PLAY_INTERVAL_MS)
      .loop(true)
      .duration(400)
      .curve(Curve.EaseOut)
      .indicator(false)
      .disableSwipe(false)
      .cachedCount(2)
      .onChange((index: number) => {
        this.previewIndex = index;
      })
      .width('100%')
      .height(CardPreviewPolicy.previewStageHeightVp())

      Row({ space: 6 }) {
        this.buildPreviewDot(0)
        this.buildPreviewDot(1)
        this.buildPreviewDot(2)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 4 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildPreviewDot(index: number) {
    Row()
      .width(this.previewIndex === index ? 16 : 6)
      .height(6)
      .borderRadius(3)
      .backgroundColor(this.previewIndex === index ? Colors.brand : Colors.disabled)
      .onClick(() => {
        this.previewIndex = index;
        this.previewSwiper.changeIndex(index, true);
      })
  }

  @Builder
  private buildPreviewPage(index: number) {
    Column() {
      this.buildPreviewCard(index)
    }
    .width('100%')
    .height(CardPreviewPolicy.previewStageHeightVp())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildPreviewCard(index: number) {
    Stack() {
      if (index === 0) {
        WidgetMinimumBody({
          name: this.previewSlotName(0),
          remark: this.slotAt(0).remark,
          code: this.slotAt(0).code,
          badgeColor: this.slotAt(0).badgeColor,
          refreshEnabled: false
        })
      } else if (index === 1) {
        WidgetSmallBody({
          t1Name: this.previewSlotName(0),
          t1Remark: this.slotAt(0).remark,
          t1Code: this.slotAt(0).code,
          t1Color: this.slotAt(0).badgeColor,
          t2Name: this.previewSlotName(1),
          t2Remark: this.slotAt(1).remark,
          t2Code: this.slotAt(1).code,
          t2Color: this.slotAt(1).badgeColor,
          refreshEnabled: false
        })
      } else {
        WidgetMediumBody({
          t1Name: this.previewSlotName(0),
          t1Remark: this.slotAt(0).remark,
          t1Code: this.slotAt(0).code,
          t1Color: this.slotAt(0).badgeColor,
          t2Name: this.previewSlotName(1),
          t2Remark: this.slotAt(1).remark,
          t2Code: this.slotAt(1).code,
          t2Color: this.slotAt(1).badgeColor,
          t3Name: this.previewSlotName(2),
          t3Remark: this.slotAt(2).remark,
          t3Code: this.slotAt(2).code,
          t3Color: this.slotAt(2).badgeColor,
          t4Name: this.previewSlotName(3),
          t4Remark: this.slotAt(3).remark,
          t4Code: this.slotAt(3).code,
          t4Color: this.slotAt(3).badgeColor,
          refreshEnabled: false
        })
      }
    }
    .width(CardPreviewPolicy.previewWidthVp(index) > 0 ?
      CardPreviewPolicy.previewWidthVp(index) : '100%')
    .height(CardPreviewPolicy.previewHeightVp(index))
    .backgroundColor($r('app.color.widget_card_background'))
    .borderRadius(WIDGET_CARD_RADIUS)
    .clip(true)
    .hitTestBehavior(HitTestMode.None)
    .shadow({ radius: 20, color: Colors.shadow, offsetX: 0, offsetY: 8 })
  }

  @Builder
  private buildTokenSection() {
    Column({ space: 10 }) {
      Row() {
        Text('显示的令牌')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.textSecondary)
          .layoutWeight(1)
        Text(`${this.selectedIds.length}/${CardTokenPolicy.LIMIT}`)
          .fontSize(13)
          .fontColor(Colors.brand)
      }
      .width('100%')

      Text(CardPreviewPolicy.selectionHint(this.selectedIds.length))
        .fontSize(13)
        .lineHeight(18)
        .fontColor(Colors.textSecondary)
        .width('100%')

      if (this.accounts.length === 0) {
        Text(CardPreviewPolicy.emptyListHint())
          .fontSize(14)
          .fontColor(Colors.textSecondary)
          .width('100%')
          .padding({ top: 12, bottom: 12 })
      } else {
        Column() {
          ForEach(this.accounts, (item: AccountItem, index: number) => {
            this.buildAccountRow(item, index < this.accounts.length - 1)
          }, (item: AccountItem) => item.id)
        }
        .width('100%')
        .borderRadius(PageLayout.SETTINGS_PANEL_RADIUS)
        .clip(true)
        .backgroundColor(Colors.card)
        .border({ width: 1, color: Colors.border })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildAccountRow(account: AccountItem, showDivider: boolean) {
    Column() {
      Row({ space: 12 }) {
        this.buildOrderBadge(account.id)

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

        Checkbox()
          .select(this.selectedIds.indexOf(account.id) >= 0)
          .selectedColor(Colors.brand)
          .width(20)
          .height(20)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      .onClick(() => this.toggle(account.id))

      if (showDivider) {
        Divider()
          .color(Colors.divider)
          .strokeWidth(1)
          .margin({ left: 50, right: 14 })
      }
    }
    .width('100%')
  }

  @Builder
  private buildOrderBadge(accountId: string) {
    Stack() {
      Circle()
        .width(24)
        .height(24)
        .fill(this.orderOf(accountId) > 0 ? Colors.brand : Colors.chipBg)
      if (this.orderOf(accountId) > 0) {
        Text(`${this.orderOf(accountId)}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.onColor)
      }
    }
    .width(24)
    .height(24)
  }

  private filledCount(): number {
    return this.previewSlots.length;
  }

  private previewSlotName(index: number): string {
    return CardPreviewPolicy.displayName(this.slotAt(index).name, this.filledCount(), index);
  }

  private slotAt(index: number): CardOtpSlot {
    if (index < this.previewSlots.length) {
      return this.previewSlots[index];
    }
    return {
      accountId: '',
      name: '',
      remark: '',
      code: '',
      badgeColor: '#C4C4C4',
      remaining: 0,
      period: 30,
      progress: 0,
      type: ''
    };
  }

  private orderOf(accountId: string): number {
    return this.selectedIds.indexOf(accountId) + 1;
  }

  private toggle(accountId: string): void {
    const allowed: string[] = [];
    for (let i: number = 0; i < this.accounts.length; i++) {
      allowed.push(this.accounts[i].id);
    }
    this.selectedIds = CardTokenPolicy.toggle(accountId, this.selectedIds, allowed);
    CardUpdateService.setTokenIds(this.selectedIds, AccountStore.list());
    this.refreshPreview();
  }

  private refreshPreview(): void {
    const selected: AccountItem[] = CardTokenPolicy.resolveAccounts(this.accounts, this.selectedIds);
    this.previewSlots = CardOtpView.fromAccounts(selected);
  }

  private openSystemFormManager(): void {
    CardUpdateService.sync(AccountStore.list());
    const want: Want = {
          bundleName: 'com.agiledesign.onekeyauthenticator.opensource',
      abilityName: 'EntryFormAbility',
      parameters: {
        'ohos.extra.param.key.form_dimension': formInfo.FormDimension.Dimension_2_4,
        'ohos.extra.param.key.form_name': 'widget_privacy_medium',
        'ohos.extra.param.key.module_name': 'entry'
      }
    };
    try {
      formProvider.openFormManager(want);
    } catch {
      Toast.error('当前设备无法打开服务卡片管理器');
    }
  }
}
