import { PageLayout } from '../../../common/theme/Metrics';
import { Colors } from '../../../common/theme/Theme';
import {
  SettingsDetailIcon,
  SettingsDetailItem
} from '../model/SettingsDetailContent';

/** 原生设置风格的信息行：图标、两级文字与可选右侧状态。 */
@Component
export struct SettingsDetailRow {
  @Prop item: SettingsDetailItem = {
    title: '',
    description: '',
    icon: SettingsDetailIcon.ACCOUNT
  };
  @StorageProp('themeMode') private _themeMode: number = 0;

  build() {
    Row({ space: 14 }) {
      Column() {
        SymbolGlyph(this.iconResource(this.item.icon))
          .fontSize(22)
          .fontColor([this.item.dangerous ? Colors.warning : Colors.hint])
      }
      .width(PageLayout.DETAIL_ROW_ICON_SIZE)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: 3 }) {
        Text(this.item.title)
          .fontSize(PageLayout.DETAIL_ROW_TITLE_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.item.dangerous ? Colors.warning : Colors.textPrimary)
          .width('100%')

        if (this.item.description.length > 0) {
          Text(this.item.description)
            .fontSize(PageLayout.DETAIL_ROW_BODY_SIZE)
            .lineHeight(20)
            .fontColor(Colors.hint)
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.item.badge && this.item.badge.length > 0) {
        Text(this.item.badge)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.brand)
          .height(28)
          .padding({ left: 10, right: 10 })
          .borderRadius(14)
          .backgroundColor(Colors.brandLight)
          .textAlign(TextAlign.Center)
      } else if (this.item.value && this.item.value.length > 0) {
        Text(this.item.value)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.item.dangerous ? Colors.warning : Colors.hint)
          .maxLines(1)
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 68 })
    .alignItems(VerticalAlign.Center)
    .padding({ top: 12, bottom: 12 })
  }

  /** 将内容语义集中映射到项目已使用并验证过的系统符号。 */
  private iconResource(icon: SettingsDetailIcon): Resource {
    if (icon === SettingsDetailIcon.KEY || icon === SettingsDetailIcon.EXTERNAL) {
      return $r('sys.symbol.lock_fill');
    }
    if (icon === SettingsDetailIcon.FILE || icon === SettingsDetailIcon.CLIPBOARD) {
      return $r('sys.symbol.doc_text');
    }
    if (icon === SettingsDetailIcon.SHIELD) {
      return $r('sys.symbol.checkmark_shield_fill');
    }
    if (icon === SettingsDetailIcon.QR || icon === SettingsDetailIcon.CAMERA) {
      return $r('sys.symbol.qrcode');
    }
    if (icon === SettingsDetailIcon.BACKUP || icon === SettingsDetailIcon.RECOVERY) {
      return $r('sys.symbol.arrow_up_circle');
    }
    if (icon === SettingsDetailIcon.TRASH) {
      return $r('sys.symbol.trash');
    }
    if (icon === SettingsDetailIcon.NETWORK) {
      return $r('sys.symbol.xmark');
    }
    return $r('sys.symbol.info_circle');
  }
}
