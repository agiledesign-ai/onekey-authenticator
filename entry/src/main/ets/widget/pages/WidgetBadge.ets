import { CardDisplayPolicy } from '../../features/card/model/CardDisplayPolicy';

@Component
export struct WidgetBadge {
  @Prop name: string = '';
  @Prop badgeColor: string = '#C4C4C4';
  @Prop badgeSize: number = 24;

  private symbol(): Resource {
    switch (CardDisplayPolicy.badgeIndex(this.name)) {
      case 0:
        return $r('sys.symbol.star_fill');
      case 1:
        return $r('sys.symbol.bell_fill');
      case 2:
        return $r('sys.symbol.house');
      case 3:
        return $r('sys.symbol.person');
      case 4:
        return $r('sys.symbol.lock_fill');
      case 5:
        return $r('sys.symbol.checkmark_shield_fill');
      case 6:
        return $r('sys.symbol.clock');
      default:
        return $r('sys.symbol.camera');
    }
  }

  private iconSize(): number {
    return Math.max(10, Math.round(this.badgeSize * 0.5));
  }

  private radius(): number {
    return Math.round(this.badgeSize * 0.3);
  }

  private fillColor(): string {
    return this.badgeColor.length > 0 ? this.badgeColor : CardDisplayPolicy.DEFAULT_BADGE_COLOR;
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.fillColor())
        .opacity(0.14)
      SymbolGlyph(this.symbol())
        .fontSize(this.iconSize())
        .fontColor([this.fillColor()])
    }
    .width(this.badgeSize)
    .height(this.badgeSize)
    .borderRadius(this.radius())
    .clip(true)
    .flexShrink(0)
  }
}
