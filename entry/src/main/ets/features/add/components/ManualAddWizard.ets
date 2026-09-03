import { AppConfig } from '../../../common/config/AppConfig';
import { Motion } from '../../../common/motion/Motion';
import { PageLayout } from '../../../common/theme/Metrics';
import { Colors } from '../../../common/theme/Theme';
import { ManualAddFlow, ManualAddStep } from '../model/ManualAddFlow';
import { LabeledSegmentedControl } from '../../../components/LabeledSegmentedControl';

/**
 * 手动添加账号的三步引导。
 * 组件只负责收集与确认输入，账号持久化由调用方统一处理。
 */
@Component
export struct ManualAddWizard {
  @Prop statusBarHeight: number = 0;
  onCancel: () => void = () => {};
  onSubmit: (
    service: string,
    account: string,
    secret: string,
    algorithm: string,
    digits: number,
    period: number
  ) => void = (
    _service: string,
    _account: string,
    _secret: string,
    _algorithm: string,
    _digits: number,
    _period: number
  ) => {};

  @State currentStep: ManualAddStep = ManualAddStep.SERVICE;
  @State serviceName: string = '';
  @State accountName: string = '';
  @State secret: string = '';
  @State algorithmIndex: number = 0;
  @State digitsIndex: number = 0;
  @State periodIndex: number = 1;
  @StorageProp('themeMode') private _themeMode: number = 0;
  private algorithmOptions: string[] = ['SHA-1', 'SHA-256', 'SHA-512'];
  private algorithmValues: string[] = ['SHA1', 'SHA256', 'SHA512'];
  private digitsOptions: string[] = ['6 位', '8 位'];
  private digitsValues: number[] = [6, 8];
  private periodOptions: string[] = ['15 秒', '30 秒', '60 秒'];
  private periodValues: number[] = [15, 30, 60];

  build() {
    Column() {
      this.buildHeader()
      this.buildProgress()

      Scroll() {
        Column() {
          Text(this.stepTitle())
            .fontSize(PageLayout.MANUAL_STEP_TITLE_SIZE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Colors.textPrimary)
            .width('100%')
          Text(this.stepDescription())
            .fontSize(14)
            .fontColor(Colors.textSecondary)
            .lineHeight(21)
            .width('100%')
            .margin({ top: 6 })

          if (this.currentStep === ManualAddStep.SERVICE) {
            this.buildServiceStep()
          } else if (this.currentStep === ManualAddStep.SECRET) {
            this.buildSecretStep()
          } else {
            this.buildConfirmStep()
          }

          Button(this.currentStep === ManualAddStep.CONFIRM ? '确认添加' : '继续')
            .type(ButtonType.Capsule)
            .width('100%')
            .height(50)
            .backgroundColor(this.canContinue() ? Colors.brand : Colors.disabled)
            .fontColor(Colors.onColor)
            .fontWeight(FontWeight.Medium)
            .enabled(this.canContinue())
            .margin({ top: 20 })
            .onClick(() => this.handlePrimaryAction())

          if (this.currentStep !== ManualAddStep.SERVICE) {
            Button('上一步')
              .type(ButtonType.Normal)
              .width('100%')
              .height(44)
              .fontSize(14)
              .fontColor(Colors.hint)
              .backgroundColor(Colors.transparent)
              .margin({ top: 4 })
              .onClick(() => this.goBack())
          }

          Blank().layoutWeight(1)
          Column().height(PageLayout.CONTENT_BOTTOM_INSET)
        }
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .alignItems(HorizontalAlign.Start)
        .padding({
          left: PageLayout.CONTENT_HORIZONTAL_INSET,
          right: PageLayout.CONTENT_HORIZONTAL_INSET,
          top: 18
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
  }

  @Builder
  private buildHeader() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(PageLayout.MANUAL_HEADER_ICON_SIZE)
          .fontColor([Colors.textPrimary])
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => this.goBack())
      .accessibilityText(this.currentStep === ManualAddStep.SERVICE ? '返回添加方式' : '返回上一步')

      Text('手动添加')
        .fontSize(PageLayout.MANUAL_HEADER_TITLE_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Text(`${this.currentStep + 1}/3`)
        .fontSize(PageLayout.MANUAL_HEADER_STEP_SIZE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textSecondary)
        .width(44)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    // 总高度同时包含安全区，确保导航内容始终获得完整的可用高度。
    .height(this.statusBarHeight + PageLayout.MANUAL_HEADER_CONTENT_HEIGHT)
    .padding({
      left: PageLayout.HEADER_HORIZONTAL_INSET,
      right: PageLayout.HEADER_HORIZONTAL_INSET,
      top: this.statusBarHeight
    })
  }

  @Builder
  private buildProgress() {
    Row({ space: 6 }) {
      this.buildProgressSegment(ManualAddStep.SERVICE)
      this.buildProgressSegment(ManualAddStep.SECRET)
      this.buildProgressSegment(ManualAddStep.CONFIRM)
    }
    .width('100%')
    .padding({
      left: PageLayout.HEADER_HORIZONTAL_INSET,
      right: PageLayout.HEADER_HORIZONTAL_INSET
    })
    .margin({ top: 10 })
  }

  @Builder
  private buildProgressSegment(step: ManualAddStep) {
    Column()
      .height(4)
      .layoutWeight(1)
      .borderRadius(2)
      .backgroundColor(this.currentStep >= step ? Colors.brand : Colors.divider)
  }

  @Builder
  private buildServiceStep() {
    Column({ space: 16 }) {
      this.buildTextField('服务名称', '如 Google、GitHub、Microsoft', true)
      this.buildTextField('账号名称', '如 astra@example.com', false)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Colors.card)
    .borderRadius(18)
    .border({ width: 1, color: Colors.border })
    .margin({ top: 20 })
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: Motion.MANUAL_STEP_DURATION, curve: Curve.FastOutSlowIn })
        .combine(TransitionEffect.translate({ x: 12 }))
    )
  }

  @Builder
  private buildTextField(label: string, placeholder: string, serviceField: boolean) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.hint)
      if (serviceField) {
        TextInput({ text: $$this.serviceName, placeholder: placeholder })
          .height(50)
          .fontSize(16)
          .fontColor(Colors.textPrimary)
          .placeholderColor(Colors.hint)
          .backgroundColor(Colors.chipBg)
          .borderRadius(12)
          .padding({ left: 14, right: 14 })
      } else {
        TextInput({ text: $$this.accountName, placeholder: placeholder })
          .height(50)
          .fontSize(16)
          .fontColor(Colors.textPrimary)
          .placeholderColor(Colors.hint)
          .backgroundColor(Colors.chipBg)
          .borderRadius(12)
          .padding({ left: 14, right: 14 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private buildSecretStep() {
    Column() {
      Row() {
        Text('BASE32')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.brand)
          .letterSpacing(1)
      }
      .height(28)
      .padding({ left: 10, right: 10 })
      .borderRadius(14)
      .backgroundColor(Colors.brandLight)

      Text('密钥')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.hint)
        .margin({ top: 18, bottom: 8 })

      TextInput({ text: $$this.secret, placeholder: '输入 Base32 格式密钥' })
        .height(52)
        .fontSize(16)
        .fontColor(Colors.textPrimary)
        .placeholderColor(Colors.hint)
        .backgroundColor(Colors.chipBg)
        .borderRadius(12)
        .padding({ left: 14, right: 14 })

      Text(this.secretHint())
        .fontSize(12)
        .fontColor(this.secret.length > 0 && !this.isSecretValid() ? Colors.warning : Colors.textTertiary)
        .lineHeight(18)
        .margin({ top: 10 })

      LabeledSegmentedControl({
        label: '算法',
        options: this.algorithmOptions,
        selectedIndex: this.algorithmIndex
      })
        .margin({ top: 16 })
      LabeledSegmentedControl({
        label: '位数',
        options: this.digitsOptions,
        selectedIndex: this.digitsIndex
      })
        .margin({ top: 16 })
      LabeledSegmentedControl({
        label: '周期',
        options: this.periodOptions,
        selectedIndex: this.periodIndex
      })
        .margin({ top: 16 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .backgroundColor(Colors.card)
    .borderRadius(18)
    .border({ width: 1, color: Colors.border })
    .margin({ top: 20 })
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: Motion.MANUAL_STEP_DURATION, curve: Curve.FastOutSlowIn })
        .combine(TransitionEffect.translate({ x: 12 }))
    )
  }

  @Builder
  private buildConfirmStep() {
    Column() {
      Column() {
        SymbolGlyph($r('sys.symbol.checkmark_shield_fill'))
          .fontSize(34)
          .fontColor([Colors.brand])
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor(Colors.brandLight)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 18 })

      this.buildSummaryRow('服务', this.serviceName.trim())
      Divider().color(Colors.divider).strokeWidth(1).margin({ top: 14, bottom: 14 })
      this.buildSummaryRow('账号', this.effectiveAccountName())
      Divider().color(Colors.divider).strokeWidth(1).margin({ top: 14, bottom: 14 })
      this.buildSummaryRow('密钥', ManualAddFlow.maskSecret(this.secret))
      Divider().color(Colors.divider).strokeWidth(1).margin({ top: 14, bottom: 14 })
      this.buildSummaryRow(
        '参数',
        `${this.algorithmOptions[this.algorithmIndex]} · ` +
          `${this.digitsOptions[this.digitsIndex]} · ${this.periodOptions[this.periodIndex]}`
      )
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(18)
    .backgroundColor(Colors.card)
    .borderRadius(18)
    .border({ width: 1, color: Colors.border })
    .margin({ top: 20 })
    .transition(
      TransitionEffect.OPACITY
        .animation({ duration: Motion.MANUAL_STEP_DURATION, curve: Curve.FastOutSlowIn })
        .combine(TransitionEffect.translate({ x: 12 }))
    )
  }

  @Builder
  private buildSummaryRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(Colors.textSecondary)
        .width(52)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.textPrimary)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  private stepTitle(): string {
    if (this.currentStep === ManualAddStep.SERVICE) {
      return '这是哪个账号？';
    }
    if (this.currentStep === ManualAddStep.SECRET) {
      return '输入验证密钥';
    }
    return '确认账号信息';
  }

  private stepDescription(): string {
    if (this.currentStep === ManualAddStep.SERVICE) {
      return '填写服务与账号名称，方便之后快速识别。';
    }
    if (this.currentStep === ManualAddStep.SECRET) {
      return '密钥仅保存在本机，用于生成动态验证码。';
    }
    return '确认无误后，账号会立即出现在验证码首页。';
  }

  private secretHint(): string {
    if (this.secret.length > 0 && !this.isSecretValid()) {
      return '格式不正确，请检查字符和长度';
    }
    return `仅支持 A-Z 与 2-7 字符，长度不少于 ${AppConfig.SECRET_MIN_LENGTH} 位`;
  }

  private effectiveAccountName(): string {
    const account: string = this.accountName.trim();
    return account.length > 0 ? account : `${this.serviceName.trim()} 账号`;
  }

  private isSecretValid(): boolean {
    return ManualAddFlow.canContinue(ManualAddStep.SECRET, this.serviceName, this.secret);
  }

  private canContinue(): boolean {
    return ManualAddFlow.canContinue(this.currentStep, this.serviceName, this.secret);
  }

  private handlePrimaryAction(): void {
    if (this.currentStep === ManualAddStep.CONFIRM) {
      this.onSubmit(
        this.serviceName,
        this.accountName,
        this.secret,
        this.algorithmValues[this.algorithmIndex],
        this.digitsValues[this.digitsIndex],
        this.periodValues[this.periodIndex]
      );
      return;
    }
    const nextStep: ManualAddStep = ManualAddFlow.next(
      this.currentStep,
      this.serviceName,
      this.secret
    );
    if (nextStep !== this.currentStep) {
      this.changeStep(nextStep);
    }
  }

  private goBack(): void {
    if (this.currentStep === ManualAddStep.SERVICE) {
      this.onCancel();
      return;
    }
    this.changeStep(ManualAddFlow.previous(this.currentStep));
  }

  /** 在同一动画事务中替换步骤，使离场与入场节奏保持一致。 */
  private changeStep(step: ManualAddStep): void {
    this.getUIContext().animateTo({
      duration: Motion.MANUAL_STEP_DURATION,
      curve: Curve.FastOutSlowIn
    }, () => {
      this.currentStep = step;
    });
  }
}
