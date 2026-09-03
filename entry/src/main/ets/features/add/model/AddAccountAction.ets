/** 首页添加账号弹窗的选项顺序。 */
export class AddAccountAction {
  static readonly SCAN: number = 0;
  static readonly MANUAL: number = 1;
  static readonly NONE: number = -1;

  static fromMenuIndex(index: number): number {
    if (index === AddAccountAction.SCAN) {
      return AddAccountAction.SCAN;
    }
    if (index === AddAccountAction.MANUAL) {
      return AddAccountAction.MANUAL;
    }
    return AddAccountAction.NONE;
  }
}
