import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 统一日志封装。所有业务代码通过 Log 输出，禁止散落直接调用 hilog。
 */
const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = 'SecureKey';

export class Log {
  static d(message: string): void {
    hilog.debug(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  static i(message: string): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  static w(message: string): void {
    hilog.warn(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }

  static e(message: string): void {
    hilog.error(LOG_DOMAIN, LOG_TAG, '%{public}s', message);
  }
}
