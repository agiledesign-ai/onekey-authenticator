/** 建议反馈邮件规则，集中处理文案和 URI 编码。 */
export class FeedbackMailPolicy {
  private static readonly RECIPIENT: string = 'halolion@petalmail.com';
  private static readonly SUBJECT: string = '2FA验证器建议反馈';
  private static readonly DEFAULT_BODY: string = '请在这里描述你的建议或问题：';

  static recipient(): string {
    return FeedbackMailPolicy.RECIPIENT;
  }

  static body(content: string): string {
    const trimmed: string = content.trim();
    return trimmed.length > 0 ? trimmed : FeedbackMailPolicy.DEFAULT_BODY;
  }

  static mailtoUri(content: string): string {
    return `mailto:${FeedbackMailPolicy.RECIPIENT}` +
      `?subject=${encodeURIComponent(FeedbackMailPolicy.SUBJECT)}` +
      `&body=${encodeURIComponent(FeedbackMailPolicy.body(content))}`;
  }

  static failureMessage(): string {
    return `请发送邮件至 ${FeedbackMailPolicy.RECIPIENT}`;
  }
}
