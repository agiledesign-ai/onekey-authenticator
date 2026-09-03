import { Colors } from '../common/theme/Theme';
import { Toast } from '../common/utils/ToastUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { ManualAddWizard } from '../features/add/components/ManualAddWizard';
import { AddAccountWriter } from '../features/add/service/AddAccountWriter';

/** 手动输入密钥的独立页。 */
@Entry
@Component
struct ManualAddPage {
  @State statusBarHeight: number = 0;

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext();
    if (context) {
      WindowUtil.getStatusBarHeightPx(context).then((px: number) => {
        this.statusBarHeight = this.getUIContext().px2vp(px);
      });
    }
  }

  build() {
    Column() {
      ManualAddWizard({
        statusBarHeight: this.statusBarHeight,
        onCancel: () => {
          this.leave();
        },
        onSubmit: (
          service: string,
          account: string,
          secret: string,
          algorithm: string,
          digits: number,
          period: number
        ) => {
          if (!AddAccountWriter.addManual(service, account, secret, algorithm, digits, period)) {
            Toast.error('密钥格式无效或账号已存在');
            return;
          }
          Toast.success('账号添加成功');
          this.leave();
        }
      })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.page)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  private leave(): void {
    try {
      this.getUIContext().getRouter().back();
    } catch {
      Toast.error('返回失败');
    }
  }
}
