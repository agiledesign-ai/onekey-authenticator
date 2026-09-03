import { AppConfig } from '../config/AppConfig';
import { WindowUtil } from './WindowUtil';

/**
 * 统一轻量反馈封装。所有业务代码通过 Toast 调用，禁止散落直接使用 promptAction。
 */
export class Toast {
  static show(message: string, duration: number = AppConfig.TOAST_DURATION): void {
    const win = WindowUtil.getWindow();
    if (win === null) {
      return;
    }
    try {
      win.getUIContext().getPromptAction().showToast({ message: message, duration: duration });
    } catch {
      // 静默忽略，避免反馈本身导致崩溃
    }
  }

  static success(message: string): void {
    Toast.show(message);
  }

  static info(message: string): void {
    Toast.show(message);
  }

  static error(message: string): void {
    Toast.show(message);
  }
}
