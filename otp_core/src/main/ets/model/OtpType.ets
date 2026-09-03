/** SecureKey 支持的验证码类型；字符串值会直接写入加密存储。 */
export enum OtpType {
  TOTP = 'TOTP',
  HOTP = 'HOTP',
  STEAM = 'STEAM'
}
