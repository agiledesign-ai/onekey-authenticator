import { Colors } from '../common/theme/Theme';
import { PageLayout } from '../common/theme/Metrics';

/** 分组小标题 */
@Component
export struct SectionHeader {
  @Prop title: string = '';
  @Prop topMargin: number = PageLayout.SECTION_TOP;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Text(this.title)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(Colors.textSecondary)
      .margin({ top: this.topMargin, bottom: PageLayout.SECTION_BOTTOM, left: 4 })
  }
}
