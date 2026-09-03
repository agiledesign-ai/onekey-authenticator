import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { Colors } from '../common/theme/Theme';
import { WindowUtil } from '../common/utils/WindowUtil';
import { AccountStore } from '../common/store/AccountStore';
import { GroupStore } from '../common/store/GroupStore';
import { HomeContent } from '../features/home/components/HomeContent';
import { SettingsTabContent } from '../features/settings/components/SettingsTabContent';
import { LaunchIntro } from '../features/onboarding/components/LaunchIntro';
import {
  OnboardingPreferencesStorage,
  OnboardingStore
} from '../features/onboarding/store/OnboardingStore';
import { AppConfig } from '../common/config/AppConfig';
import { Motion } from '../common/motion/Motion';
import { ThemeManager } from '../common/theme/ThemeManager';
import { PageLayout } from '../common/theme/Metrics';
import { Toast } from '../common/utils/ToastUtil';
import { FaceAuthResult, FaceUnlockPolicy } from '../features/security/model/FaceUnlockPolicy';
import { FaceAuthService } from '../features/security/service/FaceAuthService';
import { FaceUnlockRuntime } from '../features/security/service/FaceUnlockRuntime';
import { SettingsRoutes } from '../features/settings/model/SettingsDetailPolicy';

const ONBOARDING_NONE: number = 0;
const ONBOARDING_INTRO: number = 1;
const ONBOARDING_COACH: number = 2;

/**
 * 应用首页（@Entry）。底部保留验证码与设置，添加从右上角加号进入。
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State statusBarHeight: number = 0;
  @State onboardingStage: number = ONBOARDING_NONE;
  @StorageLink('faceUnlockContentVisible') private faceUnlockContentVisible: boolean = true;
  @StorageLink('faceUnlockAuthRequestToken') @Watch('onFaceAuthRequest')
  private faceAuthRequestToken: number = 0;
  @StorageLink('pendingCardConfigFormId') @Watch('onPendingCardConfig')
  private pendingCardConfigFormId: string = '';
  @StorageLink('pendingCardDimension') private pendingCardDimension: string = '';
  @StorageLink('homeTabRequestToken') @Watch('onHomeTabRequest')
  private homeTabRequestToken: number = 0;
  @State private faceAuthInProgress: boolean = false;
  @State private faceAuthMessage: string = '';
  private tabsController: HdsTabsController = new HdsTabsController();
  private onboardingStore: OnboardingStore = new OnboardingStore(
    new OnboardingPreferencesStorage(),
    AppConfig.ONBOARDING_VERSION
  );

  aboutToAppear(): void {
    if (FaceUnlockRuntime.isEnabled()) {
      this.authenticateFace();
    } else if (this.loadAccounts()) {
      this.startOnboardingIfNeeded();
      this.openPendingCardConfig();
    }
    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      HdsTabs({ controller: this.tabsController }) {
        TabContent() {
          HomeContent({
            statusBarHeight: this.statusBarHeight,
            showAddHint: this.onboardingStage === ONBOARDING_COACH,
            onAddHintConsumed: () => this.completeOnboarding()
          })
        }
        .tabBar(this.buildTabBar(0, $r('sys.symbol.lock'), '验证码'))

        TabContent() {
          SettingsTabContent({ statusBarHeight: this.statusBarHeight })
        }
        .tabBar(this.buildTabBar(1, $r('sys.symbol.gearshape'), '设置'))
      }
      .barPosition(BarPosition.End)
      .scrollable(false)
      .barOverlap(true)
      .barFloatingStyle({
        barBottomMargin: this.floatingBarBottomMargin(),
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          // EXQUISITE 级别会在栏底部渲染一块白色高光，改用 SMOOTH 规避。
          materialLevel: hdsMaterial.MaterialLevel.SMOOTH
        }
      })
      .animationDuration(Motion.TAB_DURATION)
      .onSelected((index: number) => {
        this.currentIndex = index;
      })
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .width('100%')
      .height('100%')

      if (this.onboardingStage === ONBOARDING_INTRO) {
        LaunchIntro({ onFinished: () => this.showCoach() })
          .zIndex(3)
      }

      if (!this.faceUnlockContentVisible) {
        this.buildFaceLockCover()
      }
    }
    .backgroundColor(Colors.page)
    .width('100%')
    .height('100%')
  }

  @Builder
  private buildFaceLockCover() {
    Column({ space: 18 }) {
      SymbolGlyph($r('sys.symbol.lock_fill'))
        .fontSize(56)
        .fontColor([Colors.brand])
      Text('2FA验证器 已锁定')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.textPrimary)
      Text(this.faceAuthMessage.length > 0 ? this.faceAuthMessage : '请完成人脸识别')
        .fontSize(14)
        .fontColor(Colors.textSecondary)
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })

      if (this.faceAuthInProgress) {
        LoadingProgress()
          .width(30)
          .height(30)
          .color(Colors.brand)
      } else {
        Button('重新识别')
          .fontColor(Colors.onColor)
          .backgroundColor(Colors.brand)
          .onClick(() => this.authenticateFace())
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Colors.page)
    .width('100%')
    .height('100%')
    .zIndex(20)
  }

  private onFaceAuthRequest(): void {
    if (FaceUnlockRuntime.isEnabled() && !this.faceUnlockContentVisible) {
      this.authenticateFace();
    }
  }

  private async authenticateFace(): Promise<void> {
    if (this.faceAuthInProgress || !FaceUnlockRuntime.isEnabled()) {
      return;
    }
    this.faceAuthInProgress = true;
    this.faceAuthMessage = '';
    try {
      const availability: FaceAuthResult = FaceAuthService.checkAvailability();
      if (availability !== FaceAuthResult.SUCCESS) {
        this.faceAuthMessage = FaceUnlockPolicy.messageFor(availability);
        return;
      }

      const result: FaceAuthResult = await FaceAuthService.authenticate();
      if (result !== FaceAuthResult.SUCCESS) {
        this.faceAuthMessage = FaceUnlockPolicy.messageFor(result);
        return;
      }
      FaceUnlockRuntime.unlock();
      if (!this.loadAccounts()) {
        return;
      }
      AppStorage.setOrCreate('otpForegroundRefreshToken', Date.now());
      this.startOnboardingIfNeeded();
      this.openPendingCardConfig();
    } finally {
      this.faceAuthInProgress = false;
    }
  }

  private loadAccounts(): boolean {
    try {
      AccountStore.init();
      GroupStore.init();
      return true;
    } catch {
      this.faceAuthMessage = '无法打开安全存储，请重试';
      Toast.error(this.faceAuthMessage);
      return false;
    }
  }

  private startOnboardingIfNeeded(): void {
    if (this.onboardingStore.shouldShow()) {
      this.onboardingStage = ONBOARDING_INTRO;
      WindowUtil.setStatusBarContentColor('#FFFFFF');
    }
  }

  private showCoach(): void {
    if (this.onboardingStage !== ONBOARDING_INTRO) {
      return;
    }
    this.onboardingStage = ONBOARDING_COACH;
    this.restoreStatusBarColor();
  }

  private onPendingCardConfig(): void {
    if (this.faceUnlockContentVisible) {
      this.openPendingCardConfig();
    }
  }

  /** 卡片定位深链到达时切回“验证码”页签，由 HomeContent 完成滚动定位。 */
  private onHomeTabRequest(): void {
    if (this.homeTabRequestToken > 0 && this.currentIndex !== 0) {
      this.currentIndex = 0;
      this.tabsController.changeIndex(0);
    }
  }

  private openPendingCardConfig(): void {
    const formId: string = this.pendingCardConfigFormId;
    if (formId.length === 0) {
      return;
    }
    const dimension: string = this.pendingCardDimension;
    AppStorage.setOrCreate('pendingCardConfigFormId', '');
    AppStorage.setOrCreate('pendingCardDimension', '');
    try {
      this.getUIContext().getRouter().pushUrl({
        url: SettingsRoutes.CARD_CONFIG,
        params: {
          formId: formId,
          dimension: dimension
        }
      });
    } catch {
      Toast.error('无法打开卡片配置');
    }
  }

  private completeOnboarding(): void {
    if (this.onboardingStage === ONBOARDING_NONE) {
      return;
    }
    this.onboardingStore.complete();
    this.onboardingStage = ONBOARDING_NONE;
  }

  private restoreStatusBarColor(): void {
    WindowUtil.setStatusBarContentColor(ThemeManager.isDark() ? '#FFFFFF' : '#000000');
  }

  private navigationLiftVp(): number {
    return this.getUIContext().px2vp(PageLayout.NAV_BAR_LIFT_PX);
  }

  private floatingBarBottomMargin(): number {
    return PageLayout.NAV_BAR_BASE_BOTTOM_MARGIN + this.navigationLiftVp();
  }

  @Builder
  buildTabBar(index: number, icon: Resource, label: string) {
    Column({ space: PageLayout.TAB_ICON_LABEL_GAP }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.currentIndex === index ? Colors.brand : Colors.hint])
      Text(label)
        .fontSize(11)
        .fontWeight(
          this.currentIndex === index ? PageLayout.TAB_SELECTED_WEIGHT : PageLayout.TAB_NORMAL_WEIGHT,
          { enableVariableFontWeight: true }
        )
        .fontColor(this.currentIndex === index ? Colors.brand : Colors.hint)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
