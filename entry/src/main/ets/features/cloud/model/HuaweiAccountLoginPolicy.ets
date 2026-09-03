/** 华为账号登录意图：进页静默恢复，或用户点按。 */
export type HuaweiLoginIntent = 'restore' | 'tap';

/**
 * 点按登录对齐参考项目：先取消旧授权，再强制登录并申请 profile。
 */
export class HuaweiAccountLoginPolicy {
  static forceLogin(intent: HuaweiLoginIntent): boolean {
    return intent === 'tap';
  }

  static forceAuthorization(intent: HuaweiLoginIntent): boolean {
    return intent === 'tap';
  }

  static cancelBeforeLogin(): boolean {
    return true;
  }

  static preferSilentOnTap(): boolean {
    return false;
  }

  static attachCsrfState(): boolean {
    return true;
  }

  static authorizationScopes(): string[] {
    return ['openid', 'profile'];
  }

  /** 系统未登录华为账号时，用户点按才拉起系统登录页。 */
  static shouldForceLoginAfterSilentFailure(code: number): boolean {
    return code === 1001502001;
  }

  /** 静默登录成功即可同步；profile 授权只用来显示昵称。 */
  static acceptSilentLoginWithoutProfile(): boolean {
    return true;
  }

  static messageFor(code: number): string {
    if (code === -2) {
      return '授权验证失败';
    }
    if (code === 1001500001) {
      return '应用签名指纹校验失败，请检查配置';
    }
    if (code === 1001500003 || code === 1001502014) {
      return '华为账号权限未配置，请开通 openid 和 profile';
    }
    if (code === 1001502001) {
      return '请先在系统设置中登录华为账号';
    }
    if (code === 1001502002) {
      return '应用尚未获得华为账号授权';
    }
    if (code === 1001502003 || code === 401) {
      return '华为账号登录参数配置错误';
    }
    if (code === 1001502005) {
      return '网络异常，请检查网络';
    }
    if (code === 1001500002) {
      return '登录请求正在处理，请稍后再试';
    }
    if (code === 1001502009 || code === 12300001) {
      return '华为账号服务暂时异常，请稍后重试';
    }
    return code > 0 ? `华为账号登录失败（${code}）` : '华为账号登录失败';
  }
}
