import { Colors } from '../common/theme/Theme';
import { SegmentedControl } from './SegmentedControl';

/**
 * 带标题的参数选择器，通过 @Link 直接更新调用页面的唯一选择状态。
 */
@Component
export struct LabeledSegmentedControl {
  @Prop label: string = '';
  @Prop options: string[] = [];
  @Link selectedIndex: number;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column({ space: 8 }) {
      Text(this.label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.hint)

      SegmentedControl({
        options: this.options,
        selectedIndex: this.selectedIndex,
        onSelect: (index: number) => {
          this.selectedIndex = index;
        }
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
