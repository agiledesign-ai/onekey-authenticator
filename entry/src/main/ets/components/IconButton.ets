import { Colors } from '../common/theme/Theme';

/**
 * 圆形图标按钮。用于头部等小操作入口。
 */
@Component
export struct IconButton {
  @Prop icon: Resource = $r('sys.symbol.xmark');
  @Prop diameter: number = 40;
  @Prop bg: string = Colors.chipBg;
  @Prop iconColor: string = Colors.textPrimary;
  onTap: () => void = () => {};
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(this.diameter / 2)
        .fontColor([this.iconColor])
    }
    .width(this.diameter)
    .height(this.diameter)
    .borderRadius(this.diameter / 2)
    .backgroundColor(this.bg)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => this.onTap())
  }
}
