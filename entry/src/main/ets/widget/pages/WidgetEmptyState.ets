import { CardPreviewPolicy } from '../../features/card/model/CardPreviewPolicy';

@Component
export struct WidgetEmptyState {
  @Prop compact: boolean = false;
  onOpen: () => void = () => {};

  @Builder
  private StepRow(label: string) {
    Row({ space: 8 }) {
      Column()
        .width(6)
        .height(6)
        .borderRadius(3)
        .backgroundColor($r('app.color.widget_empty_dot'))
        .flexShrink(0)

      Text(label)
        .fontSize(this.compact ? 11 : 13)
        .fontColor($r('app.color.widget_empty_body'))
        .lineHeight(this.compact ? 16 : 20)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ minWidth: 0 })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      SymbolGlyph($r('sys.symbol.key'))
        .fontSize(this.compact ? 40 : 78)
        .fontColor([$r('app.color.widget_empty_mark')])
        .rotate({ angle: 18 })
        .margin({ top: this.compact ? -2 : 6, right: this.compact ? 0 : 8 })

      Column({ space: this.compact ? 6 : 10 }) {
        Text(CardPreviewPolicy.emptyTitle())
          .fontSize(this.compact ? 18 : 24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.widget_empty_title'))
          .letterSpacing(-0.3)

        if (this.compact) {
          this.StepRow(CardPreviewPolicy.emptyCompactHint())
        } else {
          this.StepRow(CardPreviewPolicy.emptySteps()[0])
          this.StepRow(CardPreviewPolicy.emptySteps()[1])
          this.StepRow(CardPreviewPolicy.emptySteps()[2])
        }
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(this.compact ? FlexAlign.Center : FlexAlign.Start)
      .padding({
        left: this.compact ? 12 : 16,
        right: this.compact ? 36 : 52,
        top: this.compact ? 8 : 16,
        bottom: this.compact ? 8 : 14
      })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 145,
      colors: [
        [$r('app.color.widget_empty_start'), 0.0],
        [$r('app.color.widget_empty_end'), 1.0]
      ]
    })
    .onClick(() => {
      this.onOpen();
    })
  }
}
