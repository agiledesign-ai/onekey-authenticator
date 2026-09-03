/** 验证码剪贴板的失效和所有权判断。 */
export class ClipboardPolicy {
  private static readonly MAX_LIFETIME_MS: number = 30_000;

  static expiresAt(copiedAt: number, remainingSeconds: number): number {
    const codeLifetimeMs: number = Math.max(0, remainingSeconds) * 1_000;
    return copiedAt + Math.min(ClipboardPolicy.MAX_LIFETIME_MS, codeLifetimeMs);
  }

  static stillOwnsClipboard(writeChangeCount: number, currentChangeCount: number): boolean {
    return writeChangeCount > 0 && writeChangeCount === currentChangeCount;
  }
}
