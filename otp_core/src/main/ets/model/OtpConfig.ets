/** otp_core 内的密钥校验常量，避免共享库依赖手机 AppConfig。 */
export class OtpConfig {
  static readonly SECRET_PATTERN: string = '^[A-Za-z2-7]{8,}$';
}
