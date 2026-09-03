import { Colors } from '../../../common/theme/Theme';
import { CodeText } from '../../../components/CodeText';
import { CountdownRing } from '../../../components/CountdownRing';
import { Toast } from '../../../common/utils/ToastUtil';
import { AccountStore } from '../../../common/store/AccountStore';
import { Motion } from '../../../common/motion/Motion';
import { PageLayout } from '../../../common/theme/Metrics';
import { ClipboardGuard } from '../../security/service/ClipboardGuard';
import { OtpType } from '../../../model/OtpType';

/**
 * 白色账号令牌：以不透明主题表面承载身份、验证码和真实倒计时进度。
 * 点击验证码右侧按钮安全复制；长按卡片进入账号管理页。
 */
@Component
export struct AccountCard {
  @Prop serviceName: string = '';
  @Prop accountName: string = '';
  @Prop code: string = '';
  @Prop remainingSeconds: number = 30;
  @Prop period: number = 30;
  @Prop badgeColor: string = '#4285F4';
  @Prop accountId: string = '';
  @Prop accountType: string = OtpType.TOTP;
  @Prop counter: number = 0;
  @Prop pinned: boolean = false;
  @Prop animateEntrance: boolean = false;
  onAdvanceHotp: () => void = () => {};
  onTogglePinned: () => void = () => {};
  @State entranceProgress: number = 1;
  @StorageProp('themeMode') private _themeMode: number = 0;

  aboutToAppear(): void {
    if (this.animateEntrance) {
      this.entranceProgress = 0;
    }
  }

  private playEntrance(): void {
    if (!this.animateEntrance) {
      return;
    }
    this.getUIContext().animateTo({
      duration: Motion.CARD_ENTRANCE_DURATION,
      delay: Motion.CARD_ENTRANCE_DELAY,
      curve: Curve.FastOutSlowIn,
      onFinish: () => AccountStore.consumeRecentlyAdded(this.accountId)
    }, () => {
      this.entranceProgress = 1;
    });
  }

  /** 依据服务名哈希稳定地挑选徽章插画图标，保证同一账号图标固定且各账号有区分度。 */
  private badgeSymbol(): Resource {
    const name: string = this.serviceName;
    let hash: number = 0;
    for (let i: number = 0; i < name.length; i++) {
      hash = hash + name.charCodeAt(i);
    }
    switch (hash % 8) {
      case 0: return $r('sys.symbol.star_fill');
      case 1: return $r('sys.symbol.bell_fill');
      case 2: return $r('sys.symbol.house');
      case 3: return $r('sys.symbol.person');
      case 4: return $r('sys.symbol.lock_fill');
      case 5: return $r('sys.symbol.checkmark_shield_fill');
      case 6: return $r('sys.symbol.clock');
      default: return $r('sys.symbol.camera');
    }
  }

  /** 越接近失效，验证码字重越高；HOTP 没有倒计时，保持常规字重。 */
  private codeWeight(): number {
    if (this.accountType === OtpType.HOTP) {
      return PageLayout.HOME_CODE_MIN_WEIGHT;
    }
    const remaining: number = Math.max(0, Math.min(this.period, this.remainingSeconds));
    const elapsedRatio: number = (this.period - remaining) / this.period;
    const weightRange: number = PageLayout.HOME_CODE_MAX_WEIGHT - PageLayout.HOME_CODE_MIN_WEIGHT;
    return PageLayout.HOME_CODE_MIN_WEIGHT + Math.round(elapsedRatio * weightRange);
  }

  private isExpiringSoon(): boolean {
    return this.accountType !== OtpType.HOTP && this.remainingSeconds <= 5;
  }

  /** 通过安全剪贴板复制，并保持成功、失败反馈一致。 */
  private copyCode(): void {
    const lifetime: number = this.accountType === OtpType.HOTP ? 30 : this.remainingSeconds;
    if (ClipboardGuard.copy(this.code, lifetime)) {
      Toast.success('验证码已复制，将在短时间内自动清除');
    } else {
      Toast.error('复制失败，请重试');
    }
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Row({ space: 11 }) {
          Stack() {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor(this.badgeColor)
              .opacity(0.14)
            SymbolGlyph(this.badgeSymbol())
              .fontSize(20)
              .fontColor([this.badgeColor])
          }
          .width(PageLayout.HOME_BADGE_SIZE)
          .height(PageLayout.HOME_BADGE_SIZE)
          .borderRadius(PageLayout.HOME_BADGE_RADIUS)
          .clip(true)

          Column({ space: 3 }) {
            Row({ space: 6 }) {
              Text(this.serviceName)
                .fontSize(PageLayout.HOME_SERVICE_SIZE)
                .fontWeight(PageLayout.HOME_SERVICE_WEIGHT, { enableVariableFontWeight: true })
                .fontColor(Colors.textPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              if (this.pinned) {
                SymbolGlyph($r('sys.symbol.pin_fill'))
                  .fontSize(16)
                  .fontColor([Colors.brand])
                  .onClick(() => this.onTogglePinned())
                  .accessibilityText('取消置顶')
              } else {
                SymbolGlyph($r('sys.symbol.pin'))
                  .fontSize(16)
                  .fontColor([Colors.textSecondary])
                  .onClick(() => this.onTogglePinned())
                  .accessibilityText('置顶账号')
              }
            }
            .width('100%')
            Text(this.accountType === OtpType.HOTP ?
              `${this.accountName} · 计数器 ${this.counter}` : this.accountName)
              .fontSize(PageLayout.HOME_ACCOUNT_SIZE)
              .fontWeight(PageLayout.HOME_ACCOUNT_WEIGHT, { enableVariableFontWeight: true })
              .fontColor(Colors.textSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .layoutWeight(1)

        if (this.accountType === OtpType.HOTP) {
          Button('下一枚')
            .height(32)
            .fontSize(12)
            .fontColor(Colors.brand)
            .backgroundColor(Colors.brandLight)
            .onClick(() => this.onAdvanceHotp())
            .accessibilityText('生成下一个验证码')
        } else {
          CountdownRing({
            seconds: this.remainingSeconds,
            total: this.period,
            diameter: PageLayout.HOME_COUNTDOWN_SIZE
          })
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 8 }) {
        CodeText({
          code: this.code,
          caution: this.isExpiringSoon(),
          fontSize: PageLayout.HOME_CODE_SIZE,
          fontWeight: this.codeWeight()
        })
          .layoutWeight(1)

        Column() {
          SymbolGlyph($r('sys.symbol.rectangle_on_rectangle'))
            .fontSize(20)
            .fontColor([Colors.brand])
        }
        .width(40)
        .height(40)
        .borderRadius(13)
        .backgroundColor(Colors.brandLight)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.copyCode())
        .accessibilityText('复制验证码')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 4 })
    }
    .width('100%')
    .height(PageLayout.HOME_CARD_HEIGHT)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .borderRadius(PageLayout.HOME_CARD_RADIUS)
    .backgroundColor(Colors.card)
    .shadow({ radius: 12, color: Colors.shadow, offsetX: 0, offsetY: 4 })
    .opacity(this.entranceProgress)
    .translate({ y: (1 - this.entranceProgress) * 14 })
    .onAppear(() => this.playEntrance())
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.getUIContext().getRouter().pushUrl({
            url: 'pages/EditAccountPage',
            params: { accountId: this.accountId }
          });
        })
    )
    .accessibilityText(
      this.accountType === OtpType.HOTP ?
        `${this.serviceName}，账号 ${this.accountName}，验证码 ${this.code}，计数器 ${this.counter}，长按管理` :
        `${this.serviceName}，账号 ${this.accountName}，验证码 ${this.code}，剩余 ${this.remainingSeconds} 秒，长按管理`
    )
  }
}
