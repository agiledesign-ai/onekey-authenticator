/**
 * 应用级常量配置。集中管理魔法值，避免散落各处。
 */
export class AppConfig {
  /** 应用显示名称 */
  static readonly APP_NAME: string = '2FA验证器-工具';
  /** 应用版本标签（设置页/关于展示） */
  static readonly APP_VERSION_LABEL: string = 'v1.0.5';
  /** TOTP 周期（秒） */
  static readonly TOTP_PERIOD: number = 30;
  /** TOTP 位数 */
  static readonly TOTP_DIGITS: number = 6;
  /** Base32 密钥最小长度 */
  static readonly SECRET_MIN_LENGTH: number = 8;
  /** Base32 密钥正则 */
  static readonly SECRET_PATTERN: string = '^[A-Za-z2-7]{8,}$';
  /** Toast 默认时长（毫秒） */
  static readonly TOAST_DURATION: number = 1500;
  /** 首次使用引导版本 */
  static readonly ONBOARDING_VERSION: number = 1;
}
