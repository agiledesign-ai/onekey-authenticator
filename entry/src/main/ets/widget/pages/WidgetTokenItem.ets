import { CardDisplayPolicy } from '../../features/card/model/CardDisplayPolicy';
import { WidgetBadge } from './WidgetBadge';
import { WidgetRefreshButton } from './WidgetRefreshButton';
import {
  WIDGET_ACCOUNT_SIZE,
  WIDGET_BADGE_COMPACT,
  WIDGET_BADGE_HERO,
  WIDGET_BADGE_REGULAR,
  WIDGET_CODE_SIZE,
  WIDGET_COMPACT_CODE_SIZE,
  WIDGET_COMPACT_NAME_SIZE,
  WIDGET_HERO_CODE_SIZE,
  WIDGET_HERO_NAME_SIZE,
  WIDGET_NAME_SIZE,
  WIDGET_TEXT_GAP
} from './WidgetMetrics';

@Component
export struct WidgetTokenItem {
  @Prop name: string = '';
  @Prop remark: string = '';
  @Prop code: string = '';
  @Prop badgeColor: string = '#C4C4C4';
  @Prop mode: string = 'regular';
  @Prop showRefresh: boolean = false;
  @Prop refreshEnabled: boolean = true;
  onOpen: () => void = () => {};
  onRefresh: () => void = () => {};

  private issuer(): string {
    return CardDisplayPolicy.issuerLine(this.name, this.remark);
  }

  private account(): string {
    return CardDisplayPolicy.accountLine(this.name, this.remark);
  }

  private groupedCode(): string {
    return CardDisplayPolicy.formatCode(this.code);
  }

  private showAccount(): boolean {
    return this.mode !== 'compact' && this.account().length > 0;
  }

  private nameSize(): number {
    if (this.mode === 'compact') {
      return WIDGET_COMPACT_NAME_SIZE;
    }
    if (this.mode === 'hero') {
      return WIDGET_HERO_NAME_SIZE;
    }
    return WIDGET_NAME_SIZE;
  }

  private codeSize(): number {
    if (this.mode === 'compact') {
      return WIDGET_COMPACT_CODE_SIZE;
    }
    if (this.mode === 'hero') {
      return WIDGET_HERO_CODE_SIZE;
    }
    return WIDGET_CODE_SIZE;
  }

  private nameColor(): ResourceColor {
    return this.mode === 'compact' ?
      $r('app.color.widget_text_secondary') :
      $r('app.color.widget_text_primary');
  }

  private badgeSize(): number {
    if (this.mode === 'compact') {
      return WIDGET_BADGE_COMPACT;
    }
    if (this.mode === 'hero') {
      return WIDGET_BADGE_HERO;
    }
    return WIDGET_BADGE_REGULAR;
  }

  @Builder
  private IdentityBlock() {
    Column({ space: this.showAccount() ? 2 : 0 }) {
      Text(this.issuer())
        .fontSize(this.nameSize())
        .fontWeight(FontWeight.Medium)
        .fontColor(this.nameColor())
        .lineHeight(this.nameSize() + 3)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      if (this.showAccount()) {
        Text(this.account())
          .fontSize(WIDGET_ACCOUNT_SIZE)
          .fontColor($r('app.color.widget_text_secondary'))
          .lineHeight(WIDGET_ACCOUNT_SIZE + 3)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ minWidth: 0 })
    .width('100%')
  }

  @Builder
  private CodeBlock() {
    Text(this.groupedCode())
      .fontSize(this.codeSize())
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.widget_code'))
      .lineHeight(this.codeSize() + 2)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Clip })
      .letterSpacing(this.mode === 'hero' ? 1.2 : 0.6)
      .width('100%')
      .contentTransition(new NumericTextTransition({
        flipDirection: FlipDirection.UP,
        enableBlur: true
      }))
  }

  @Builder
  private RefreshSlot() {
    if (this.showRefresh) {
      WidgetRefreshButton({
        refreshEnabled: this.refreshEnabled,
        onRefresh: () => {
          this.onRefresh();
        }
      })
    }
  }

  @Builder
  private IssuerBadge() {
    WidgetBadge({
      name: this.issuer(),
      badgeColor: this.badgeColor,
      badgeSize: this.badgeSize()
    })
  }

  build() {
    if (this.mode === 'compact') {
      Row({ space: 8 }) {
        this.IssuerBadge()

        Column({ space: WIDGET_TEXT_GAP }) {
          this.IdentityBlock()
          this.CodeBlock()
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          this.onOpen();
        })

        this.RefreshSlot()
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Center)
    } else if (this.mode === 'hero') {
      Column() {
        Row({ space: 10 }) {
          this.IssuerBadge()

          Column() {
            this.IdentityBlock()
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .onClick(() => {
            this.onOpen();
          })

          this.RefreshSlot()
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Blank()
          .layoutWeight(1)
          .onClick(() => {
            this.onOpen();
          })

        Column() {
          this.CodeBlock()
        }
        .width('100%')
        .onClick(() => {
          this.onOpen();
        })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
    } else {
      Row({ space: 8 }) {
        Column() {
          Row({ space: 8 }) {
            this.IssuerBadge()
            Column() {
              this.IdentityBlock()
            }
            .layoutWeight(1)
            .constraintSize({ minWidth: 0 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Blank().layoutWeight(1)
          this.CodeBlock()
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .height('100%')
        .onClick(() => {
          this.onOpen();
        })

        Column() {
          this.RefreshSlot()
          Blank().layoutWeight(1)
        }
        .height('100%')
        .visibility(this.showRefresh ? Visibility.Visible : Visibility.None)
      }
      .width('100%')
      .height('100%')
      .alignItems(VerticalAlign.Top)
    }
  }
}
