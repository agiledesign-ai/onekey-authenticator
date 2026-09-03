import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';

/**
 * 验证码等宽分组文本（6 位为 3+3，8 位为 4+4）。
 */
@Component
export struct CodeText {
  @Prop code: string = '';
  @Prop caution: boolean = false;
  @Prop fontSize: number = PageLayout.HOME_CODE_SIZE;
  @Prop fontWeight: number = PageLayout.HOME_CODE_MIN_WEIGHT;
  @StorageProp('themeMode') private _themeMode: number = 0;

  private groupSize(): number {
    if (this.code.length === 5) {
      return 5;
    }
    return this.code.length <= 6 ? 3 : Math.ceil(this.code.length / 2);
  }

  build() {
    Row({ space: 6 }) {
      Text(this.code.length >= this.groupSize() ? this.code.substring(0, this.groupSize()) : this.code)
        .fontSize(this.fontSize)
        .fontWeight(this.fontWeight, { enableVariableFontWeight: true })
        .fontColor(this.caution ? Colors.caution : Colors.textPrimary)
        .letterSpacing(3)
      Text(this.code.length > this.groupSize() ? this.code.substring(this.groupSize()) : '')
        .fontSize(this.fontSize)
        .fontWeight(this.fontWeight, { enableVariableFontWeight: true })
        .fontColor(this.caution ? Colors.caution : Colors.textPrimary)
        .letterSpacing(3)
    }
    .alignItems(VerticalAlign.Center)
  }
}
