import { CardDisplayPolicy } from '../../features/card/model/CardDisplayPolicy';
import { WidgetEmptyState } from './WidgetEmptyState';
import { WidgetTokenItem } from './WidgetTokenItem';
import {
  WIDGET_CARD_PADDING,
  WIDGET_COMPACT_PADDING,
  WIDGET_CONTENT_GAP
} from './WidgetMetrics';

@Component
export struct WidgetMinimumBody {
  @Prop name: string = '';
  @Prop remark: string = '';
  @Prop code: string = '';
  @Prop badgeColor: string = '#C4C4C4';
  @Prop refreshEnabled: boolean = true;
  onOpen: () => void = () => {};
  onRefresh: () => void = () => {};

  build() {
    if (CardDisplayPolicy.isEmpty([this.name])) {
      WidgetEmptyState({
        compact: true,
        onOpen: (): void => {
          this.onOpen();
        }
      })
    } else {
      WidgetTokenItem({
        name: this.name,
        remark: this.remark,
        code: this.code,
        badgeColor: this.badgeColor,
        mode: 'compact',
        showRefresh: true,
        refreshEnabled: this.refreshEnabled,
        onOpen: (): void => {
          this.onOpen();
        },
        onRefresh: (): void => {
          this.onRefresh();
        }
      })
        .width('100%')
        .height('100%')
        .padding({
          left: WIDGET_COMPACT_PADDING,
          right: WIDGET_COMPACT_PADDING,
          top: 8,
          bottom: 8
        })
    }
  }
}

@Component
export struct WidgetSmallBody {
  @Prop t1Name: string = '';
  @Prop t1Remark: string = '';
  @Prop t1Code: string = '';
  @Prop t1Color: string = '#C4C4C4';
  @Prop t2Name: string = '';
  @Prop t2Remark: string = '';
  @Prop t2Code: string = '';
  @Prop t2Color: string = '#C4C4C4';
  @Prop refreshEnabled: boolean = true;
  onOpen: () => void = () => {};
  onRefresh: () => void = () => {};

  private count(): number {
    return CardDisplayPolicy.occupiedCount([this.t1Name, this.t2Name]);
  }

  private isHero(): boolean {
    return CardDisplayPolicy.layoutMode('2*2', this.count()) === 'hero';
  }

  build() {
    if (CardDisplayPolicy.isEmpty([this.t1Name, this.t2Name])) {
      WidgetEmptyState({
        compact: false,
        onOpen: (): void => {
          this.onOpen();
        }
      })
    } else {
      Column() {
        WidgetTokenItem({
          name: this.t1Name,
          remark: this.t1Remark,
          code: this.t1Code,
          badgeColor: this.t1Color,
          mode: this.isHero() ? 'hero' : 'regular',
          showRefresh: true,
          refreshEnabled: this.refreshEnabled,
          onOpen: (): void => {
            this.onOpen();
          },
          onRefresh: (): void => {
            this.onRefresh();
          }
        })
          .width('100%')
          .layoutWeight(1)

        if (!this.isHero()) {
          Divider()
            .strokeWidth(1)
            .color($r('app.color.widget_divider'))
            .width('100%')
            .margin({ top: 6, bottom: 6 })

          WidgetTokenItem({
            name: this.t2Name,
            remark: this.t2Remark,
            code: this.t2Code,
            badgeColor: this.t2Color,
            mode: 'regular',
            onOpen: (): void => {
              this.onOpen();
            }
          })
            .width('100%')
            .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .padding(WIDGET_CARD_PADDING)
    }
  }
}

@Component
export struct WidgetMediumBody {
  @Prop t1Name: string = '';
  @Prop t1Remark: string = '';
  @Prop t1Code: string = '';
  @Prop t1Color: string = '#C4C4C4';
  @Prop t2Name: string = '';
  @Prop t2Remark: string = '';
  @Prop t2Code: string = '';
  @Prop t2Color: string = '#C4C4C4';
  @Prop t3Name: string = '';
  @Prop t3Remark: string = '';
  @Prop t3Code: string = '';
  @Prop t3Color: string = '#C4C4C4';
  @Prop t4Name: string = '';
  @Prop t4Remark: string = '';
  @Prop t4Code: string = '';
  @Prop t4Color: string = '#C4C4C4';
  @Prop refreshEnabled: boolean = true;
  onOpen: () => void = () => {};
  onRefresh: () => void = () => {};

  private count(): number {
    return CardDisplayPolicy.occupiedCount([this.t1Name, this.t2Name, this.t3Name, this.t4Name]);
  }

  private mode(): string {
    return CardDisplayPolicy.layoutMode('2*4', this.count());
  }

  @Builder
  private Token(name: string, remark: string, code: string, color: string, showRefresh: boolean) {
    WidgetTokenItem({
      name: name,
      remark: remark,
      code: code,
      badgeColor: color,
      mode: this.mode() === 'hero' ? 'hero' : 'regular',
      showRefresh: showRefresh,
      refreshEnabled: this.refreshEnabled,
      onOpen: (): void => {
        this.onOpen();
      },
      onRefresh: (): void => {
        this.onRefresh();
      }
    })
      .width('100%')
      .height('100%')
  }

  build() {
    if (CardDisplayPolicy.isEmpty([this.t1Name, this.t2Name, this.t3Name, this.t4Name])) {
      WidgetEmptyState({
        compact: false,
        onOpen: (): void => {
          this.onOpen();
        }
      })
    } else if (this.mode() === 'hero') {
      Column() {
        this.Token(this.t1Name, this.t1Remark, this.t1Code, this.t1Color, true)
      }
      .width('100%')
      .height('100%')
      .padding(WIDGET_CARD_PADDING)
    } else if (this.mode() === 'row') {
      Row({ space: WIDGET_CONTENT_GAP }) {
        Column() {
          this.Token(this.t1Name, this.t1Remark, this.t1Code, this.t1Color, false)
        }
        .layoutWeight(1)
        .height('100%')

        Column() {
          this.Token(this.t2Name, this.t2Remark, this.t2Code, this.t2Color, true)
        }
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .padding(WIDGET_CARD_PADDING)
    } else {
      Column({ space: WIDGET_CONTENT_GAP }) {
        Row({ space: WIDGET_CONTENT_GAP }) {
          Column() {
            this.Token(this.t1Name, this.t1Remark, this.t1Code, this.t1Color, false)
          }
          .layoutWeight(1)
          .height('100%')

          Column() {
            this.Token(this.t2Name, this.t2Remark, this.t2Code, this.t2Color, true)
          }
          .layoutWeight(1)
          .height('100%')
        }
        .width('100%')
        .layoutWeight(1)

        Row({ space: WIDGET_CONTENT_GAP }) {
          Column() {
            this.Token(this.t3Name, this.t3Remark, this.t3Code, this.t3Color, false)
          }
          .layoutWeight(1)
          .height('100%')

          if (this.count() >= 4) {
            Column() {
              this.Token(this.t4Name, this.t4Remark, this.t4Code, this.t4Color, false)
            }
            .layoutWeight(1)
            .height('100%')
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(WIDGET_CARD_PADDING)
    }
  }
}
