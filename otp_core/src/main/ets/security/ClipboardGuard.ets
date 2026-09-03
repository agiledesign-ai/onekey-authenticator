import { pasteboard } from '@kit.BasicServicesKit';
import { ClipboardPolicy } from './ClipboardPolicy';

/** 将验证码限制在本机剪贴板，并在验证码失效或 30 秒后按所有权清除。 */
export class ClipboardGuard {
  private static clearTimer: number = 0;

  static copy(code: string, remainingSeconds: number): boolean {
    try {
      if (ClipboardGuard.clearTimer > 0) {
        clearTimeout(ClipboardGuard.clearTimer);
      }

      const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, code);
      const property: pasteboard.PasteDataProperty = data.getProperty();
      property.shareOption = pasteboard.ShareOption.LOCALDEVICE;
      data.setProperty(property);
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setDataSync(data);
      const writeChangeCount: number = systemPasteboard.getChangeCount();

      const delay: number = ClipboardPolicy.expiresAt(Date.now(), remainingSeconds) - Date.now();
      ClipboardGuard.clearTimer = setTimeout(
        () => ClipboardGuard.clearIfOwned(writeChangeCount),
        Math.max(0, delay)
      );
      return true;
    } catch {
      ClipboardGuard.clearTimer = 0;
      return false;
    }
  }

  private static clearIfOwned(writeChangeCount: number): void {
    try {
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      if (ClipboardPolicy.stillOwnsClipboard(writeChangeCount, systemPasteboard.getChangeCount())) {
        systemPasteboard.clearDataSync();
      }
    } catch {
      // 剪贴板已不可访问时不再触碰用户当前内容。
    } finally {
      ClipboardGuard.clearTimer = 0;
    }
  }
}
