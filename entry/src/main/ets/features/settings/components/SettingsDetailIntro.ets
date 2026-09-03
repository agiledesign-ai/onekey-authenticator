import { Colors, Spacing } from '../../../common/theme/Theme';

/** 二级页开场说明，用简短文字建立页面目的。 */
@Component
export struct SettingsDetailIntro {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop dangerous: boolean = false;
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column({ space: Spacing.s }) {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.dangerous ? Colors.warning : Colors.textPrimary)
        .width('100%')

      Text(this.description)
        .fontSize(15)
        .lineHeight(24)
        .fontColor(Colors.hint)
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
