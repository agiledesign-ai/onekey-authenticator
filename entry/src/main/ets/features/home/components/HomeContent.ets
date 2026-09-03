import { SymbolGlyphModifier } from '@kit.ArkUI';
import { Colors } from '../../../common/theme/Theme';
import { Toast } from '../../../common/utils/ToastUtil';
import { AccountStore } from '../../../common/store/AccountStore';
import { AccountCard } from '../../account/components/AccountCard';
import { EmptyState } from '../../account/components/EmptyState';
import { AccountItem } from '../../../model/AccountItem';
import { PageLayout } from '../../../common/theme/Metrics';
import { OtpRefreshPolicy } from '../model/OtpRefreshPolicy';
import { AddAccountAction } from '../../add/model/AddAccountAction';
import { AddAccountScanner, ScanImportKind, ScanImportOutcome } from '../../add/service/AddAccountScanner';
import { CoachMark } from '../../onboarding/components/CoachMark';
import { AccountListPolicy } from '../../account/model/AccountListPolicy';
import { OtpEngine } from '../../otp/engine/OtpEngine';
import { OtpImportCandidate } from '../../migration/model/OtpImportCandidate';
import { OtpType } from '../../../model/OtpType';
import { CardUpdateService } from '../../card/service/CardUpdateService';

/**
 * 验证码首页内容：头部 + 账号列表/空状态。
 * 账号数据来自 AccountStore（@StorageLink），验证码由 OtpEngine 从 secretKey 动态生成。
 */
@Component
export struct HomeContent {
  @Prop statusBarHeight: number = 0;
  @Prop showAddHint: boolean = false;
  onAddHintConsumed: () => void = () => {};
  @StorageLink('accountList') @Watch('onAccountsChanged') accounts: AccountItem[] = [];
  @StorageLink('recentlyAddedAccountId') recentlyAddedAccountId: string = '';
  @StorageLink('otpForegroundRefreshToken') @Watch('onForegroundRefresh') foregroundRefreshToken: number = 0;
  @StorageLink('pendingCardAccountId') @Watch('onPendingCardAccount') pendingCardAccountId: string = '';
  @StorageLink('accountsReady') @Watch('onPendingCardAccount') private accountsReady: boolean = false;
  @StorageLink('faceUnlockContentVisible') @Watch('onPendingCardAccount')
  private faceUnlockContentVisible: boolean = true;
  @State codeMap: Map<string, string> = new Map<string, string>();
  @State remainingMap: Map<string, number> = new Map<string, number>();
  @State addMenuVisible: boolean = false;
  @State searchText: string = '';
  @State showHotpCounter: boolean = false;
  @State hotpCounterText: string = '0';
  private pendingHotp: OtpImportCandidate | null = null;
  private timerId: number = 0;
  private lastEpochSeconds: number = 0;
  private listScroller: Scroller = new Scroller();
  @StorageProp('themeMode') private _themeMode: number = 0;
  private scanMenuIcon: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.qrcode')).fontSize(20);
  private manualMenuIcon: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.square_and_pencil')).fontSize(20);

  aboutToAppear(): void {
    this.refreshCodes();
    this.onPendingCardAccount();
    this.timerId = setInterval(() => {
      this.tickCodes();
    }, 1000);
  }

  aboutToDisappear(): void {
    clearInterval(this.timerId);
  }

  /** 账号列表变化时重新计算验证码。 */
  onAccountsChanged(): void {
    this.refreshCodes();
    this.onPendingCardAccount();
  }

  /** 从后台恢复时立即生成当前周期的验证码。 */
  onForegroundRefresh(): void {
    this.refreshCodes();
  }

  /** 为所有账号计算当前验证码，HOTP 使用持久化计数器。 */
  private refreshCodes(): void {
    const now: Date = new Date();
    const epoch: number = Math.floor(now.getTime() / 1000);
    const map: Map<string, string> = new Map<string, string>();
    const remainingMap: Map<string, number> = new Map<string, number>();
    for (let i: number = 0; i < this.accounts.length; i++) {
      const account: AccountItem = this.accounts[i];
      try {
        const result = OtpEngine.generate(account, now);
        map.set(account.id, result.code);
        remainingMap.set(account.id, result.remainingSeconds);
      } catch (error) {
        map.set(account.id, this.fallbackCode(account));
        remainingMap.set(account.id, account.period);
      }
    }
    this.codeMap = map;
    this.remainingMap = remainingMap;
    this.lastEpochSeconds = epoch;
    CardUpdateService.sync(this.accounts);
  }

  /** 每秒只更新倒计时；HOTP 不进入时间步刷新。 */
  private tickCodes(): void {
    const now: Date = new Date();
    const epoch: number = Math.floor(now.getTime() / 1000);
    const nextCodes: Map<string, string> = new Map<string, string>();
    const nextRemaining: Map<string, number> = new Map<string, number>();
    let rolled: boolean = false;
    for (let i: number = 0; i < this.accounts.length; i++) {
      const account: AccountItem = this.accounts[i];
      if (!OtpRefreshPolicy.usesTimeStep(account.type)) {
        if (this.codeMap.has(account.id)) {
          nextCodes.set(account.id, this.codeMap.get(account.id) ?? this.fallbackCode(account));
        } else {
          nextCodes.set(account.id, this.fallbackCode(account));
        }
        nextRemaining.set(account.id, 0);
        continue;
      }
      const remaining: number = account.period - (epoch % account.period);
      if (OtpRefreshPolicy.shouldRefresh(
        this.codeMap.has(account.id),
        this.lastEpochSeconds,
        epoch,
        account.period
      )) {
        rolled = true;
        try {
          const result = OtpEngine.generate(account, now);
          nextCodes.set(account.id, result.code);
        } catch (error) {
          nextCodes.set(account.id, this.fallbackCode(account));
        }
      } else if (this.codeMap.has(account.id)) {
        nextCodes.set(account.id, this.codeMap.get(account.id) ?? this.fallbackCode(account));
      } else {
        nextCodes.set(account.id, this.fallbackCode(account));
      }
      nextRemaining.set(account.id, remaining);
    }
    this.codeMap = nextCodes;
    this.remainingMap = nextRemaining;
    this.lastEpochSeconds = epoch;
    if (rolled) {
      CardUpdateService.sync(this.accounts);
    }
  }

  private fallbackCode(account: AccountItem): string {
    return account.type === OtpType.STEAM ? '-----' : '------';
  }

  private visibleAccounts(): AccountItem[] {
    return AccountListPolicy.filter(this.accounts, this.searchText);
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column()
        .width('100%')
        .height('100%')
        .radialGradient({
          center: ['0%', this.statusBarHeight + 188],
          radius: 260,
          colors: [[Colors.homeAmbient, 0], [Colors.transparent, 1]]
        })

      Column() {
        Row() {
          Column({ space: 4 }) {
            Text('2FA验证器')
              .fontSize(PageLayout.HOME_TITLE_SIZE)
              .fontWeight(PageLayout.HOME_TITLE_WEIGHT, { enableVariableFontWeight: true })
              .fontColor(Colors.textPrimary)
              .letterSpacing(-0.6)

            if (this.accounts.length > 0) {
              Text(`${this.accounts.length} 个动态验证码 · 长按账号可管理`)
                .fontSize(PageLayout.HOME_SUMMARY_SIZE)
                .fontWeight(PageLayout.HOME_SUMMARY_WEIGHT, { enableVariableFontWeight: true })
                .fontColor(Colors.textSecondary)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Row({ space: 8 }) {
            Button({ type: ButtonType.Circle }) {
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(22)
                .fontColor([Colors.brand])
            }
            .width(40)
            .height(40)
            .backgroundColor(Colors.chipBg)
            .border({
              width: this.showAddHint ? 2 : 0,
              color: Colors.brand
            })
            .bindMenu(this.addMenuVisible, this.addAccountMenu, {
              placement: Placement.BottomRight,
              offset: { x: 0, y: 8 },
              onDisappear: () => {
                this.addMenuVisible = false;
              }
            })
            .onClick(() => this.onAddButtonClick())
            .accessibilityText('添加账号')
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding({
          left: PageLayout.HEADER_HORIZONTAL_INSET,
          right: PageLayout.HEADER_HORIZONTAL_INSET,
          top: this.statusBarHeight + 14,
          bottom: 12
        })

        if (this.accounts.length > 0) {
          TextInput({ text: $$this.searchText, placeholder: '搜索服务或账号' })
            .height(40)
            .fontSize(14)
            .fontColor(Colors.textPrimary)
            .placeholderColor(Colors.hint)
            .backgroundColor(Colors.chipBg)
            .borderRadius(12)
            .padding({ left: 12, right: 12 })
            .margin({
              left: PageLayout.CONTENT_HORIZONTAL_INSET,
              right: PageLayout.CONTENT_HORIZONTAL_INSET,
              bottom: 12
            })
            .accessibilityText('搜索服务或账号')
        }

        if (this.accounts.length === 0) {
          EmptyState()
        } else if (this.visibleAccounts().length === 0) {
          Text('没有匹配的账号')
            .fontSize(15)
            .fontColor(Colors.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 48 })
            .layoutWeight(1)
        } else {
          List({ scroller: this.listScroller, space: PageLayout.HOME_CARD_GAP }) {
            ForEach(this.visibleAccounts(), (account: AccountItem) => {
              ListItem() {
                AccountCard({
                  serviceName: account.serviceName,
                  accountName: account.accountName,
                  code: this.codeMap.get(account.id) ?? this.fallbackCode(account),
                  remainingSeconds: this.remainingMap.get(account.id) ?? account.period,
                  period: account.period,
                  badgeColor: account.badgeColor,
                  accountId: account.id,
                  accountType: account.type,
                  counter: account.counter,
                  pinned: account.pinned,
                  animateEntrance: this.recentlyAddedAccountId === account.id,
                  onAdvanceHotp: () => this.advanceHotp(account.id),
                  onTogglePinned: () => this.togglePinned(account.id)
                })
              }
            }, (account: AccountItem) => account.id)
          }
          .listDirection(Axis.Vertical)
          .width('100%')
          .padding({
            left: PageLayout.CONTENT_HORIZONTAL_INSET,
            right: PageLayout.CONTENT_HORIZONTAL_INSET,
            bottom: PageLayout.CONTENT_BOTTOM_INSET
          })
          .scrollBar(BarState.Off)
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')

      if (this.showAddHint) {
        CoachMark({ onOpenAdd: () => this.onAddButtonClick() })
          .margin({ top: this.statusBarHeight + 66, right: PageLayout.HEADER_HORIZONTAL_INSET })
      }

      if (this.showHotpCounter) {
        Column({ space: 12 }) {
          Text('确认 HOTP 起始计数器')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.textPrimary)
          TextInput({ text: $$this.hotpCounterText, placeholder: '例如 0' })
            .height(44)
            .type(InputType.Number)
            .backgroundColor(Colors.chipBg)
            .borderRadius(12)
          Button('添加账号')
            .width('100%')
            .height(44)
            .backgroundColor(Colors.brand)
            .fontColor(Colors.onColor)
            .onClick(() => this.confirmHotpCounter())
          Button('取消')
            .width('100%')
            .height(40)
            .backgroundColor(Colors.transparent)
            .fontColor(Colors.textSecondary)
            .onClick(() => {
              this.showHotpCounter = false;
              this.pendingHotp = null;
            })
        }
        .width('80%')
        .padding(18)
        .borderRadius(16)
        .backgroundColor(Colors.card)
        .margin({ top: this.statusBarHeight + 120 })
        .shadow({ radius: 16, color: Colors.shadow, offsetX: 0, offsetY: 6 })
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 180,
      colors: [[Colors.homePageStart, 0], [Colors.homePageEnd, 1]]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private onAddButtonClick(): void {
    if (this.showAddHint) {
      this.onAddHintConsumed();
    }
    this.addMenuVisible = true;
  }

  @Builder
  private addAccountMenu() {
    Menu() {
      MenuItem({
        symbolStartIcon: this.scanMenuIcon,
        content: '扫码添加'
      })
        .onClick(() => {
          this.selectAddAction(AddAccountAction.SCAN);
        })
      MenuItem({
        symbolStartIcon: this.manualMenuIcon,
        content: '手动输入密钥'
      })
        .onClick(() => {
          this.selectAddAction(AddAccountAction.MANUAL);
        })
    }
    .radius(12)
    .width(200)
  }

  private selectAddAction(action: number): void {
    this.addMenuVisible = false;
    const mapped: number = AddAccountAction.fromMenuIndex(action);
    if (mapped === AddAccountAction.SCAN) {
      this.startScan();
      return;
    }
    if (mapped === AddAccountAction.MANUAL) {
      this.openPage('pages/ManualAddPage');
    }
  }

  private async startScan(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      Toast.show('无法获取上下文');
      return;
    }
    const outcome: ScanImportOutcome = await AddAccountScanner.start(context);
    this.applyScanOutcome(outcome);
  }

  private applyScanOutcome(outcome: ScanImportOutcome): void {
    if (outcome.kind === ScanImportKind.CANCELLED) {
      return;
    }
    if (outcome.kind === ScanImportKind.NEEDS_COUNTER && outcome.candidate !== null) {
      this.pendingHotp = outcome.candidate;
      this.hotpCounterText = '0';
      this.showHotpCounter = true;
      return;
    }
    if (outcome.kind === ScanImportKind.MIGRATION_PROGRESS) {
      Toast.show(outcome.message);
      this.startScan();
      return;
    }
    if (outcome.message.length > 0) {
      if (outcome.kind === ScanImportKind.ERROR) {
        Toast.error(outcome.message);
      } else {
        Toast.success(outcome.message);
      }
    }
  }

  private confirmHotpCounter(): void {
    if (this.pendingHotp === null) {
      this.showHotpCounter = false;
      return;
    }
    const outcome: ScanImportOutcome = AddAccountScanner.confirmHotpCandidate(
      this.pendingHotp,
      this.hotpCounterText
    );
    this.showHotpCounter = false;
    this.pendingHotp = null;
    this.applyScanOutcome(outcome);
  }

  private onPendingCardAccount(): void {
    const accountId: string = this.pendingCardAccountId;
    if (accountId.length === 0 || !this.accountsReady || !this.faceUnlockContentVisible) {
      return;
    }
    AppStorage.setOrCreate('pendingCardAccountId', '');
    this.searchText = '';
    const accounts: AccountItem[] = AccountListPolicy.filter(this.accounts, '');
    let index: number = -1;
    for (let i: number = 0; i < accounts.length; i++) {
      if (accounts[i].id === accountId) {
        index = i;
        break;
      }
    }
    if (index < 0) {
      Toast.show('账号已移除');
      return;
    }
    setTimeout(() => {
      this.listScroller.scrollToIndex(index);
    }, 0);
  }

  private advanceHotp(accountId: string): void {
    if (!AccountStore.advanceHotp(accountId)) {
      Toast.error('无法生成下一枚验证码');
    }
  }

  private togglePinned(accountId: string): void {
    for (let i: number = 0; i < this.accounts.length; i++) {
      if (this.accounts[i].id === accountId) {
        if (!AccountStore.setPinned(accountId, !this.accounts[i].pinned)) {
          Toast.error('无法更新置顶状态');
        }
        return;
      }
    }
  }

  private async openPage(url: string): Promise<void> {
    try {
      await this.getUIContext().getRouter().pushUrl({ url: url });
    } catch {
      Toast.error('页面打开失败');
    }
  }
}
