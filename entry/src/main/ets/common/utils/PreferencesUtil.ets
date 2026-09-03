import { preferences } from '@kit.ArkData';
import { Log } from './LogUtil';

/**
 * 轻量键值持久化封装（基于 Preferences）。
 * 由 EntryAbility.onCreate 注入 Context 后即可全局使用。
 */
export class PreferencesUtil {
  private static prefs: preferences.Preferences | null = null;

  static init(context: Context): void {
    try {
      PreferencesUtil.prefs = preferences.getPreferencesSync(context, { name: 'securekey_store' });
    } catch {
      Log.e('PreferencesUtil.init failed');
    }
  }

  static getString(key: string, defaultValue: string): string {
    if (PreferencesUtil.prefs === null) {
      return defaultValue;
    }
    try {
      return PreferencesUtil.prefs.getSync(key, defaultValue) as string;
    } catch {
      return defaultValue;
    }
  }

  static putString(key: string, value: string): void {
    if (PreferencesUtil.prefs === null) {
      return;
    }
    try {
      PreferencesUtil.prefs.putSync(key, value);
      PreferencesUtil.prefs.flushSync();
    } catch {
      // 静默失败
    }
  }

  static getNumber(key: string, defaultValue: number): number {
    if (PreferencesUtil.prefs === null) {
      return defaultValue;
    }
    try {
      return PreferencesUtil.prefs.getSync(key, defaultValue) as number;
    } catch {
      return defaultValue;
    }
  }

  static putNumber(key: string, value: number): void {
    if (PreferencesUtil.prefs === null) {
      return;
    }
    try {
      PreferencesUtil.prefs.putSync(key, value);
      PreferencesUtil.prefs.flushSync();
    } catch {
      // 静默失败
    }
  }

  static has(key: string): boolean {
    if (PreferencesUtil.prefs === null) {
      return false;
    }
    try {
      return PreferencesUtil.prefs.hasSync(key);
    } catch {
      return false;
    }
  }

  /** 删除已迁移的敏感旧值，并立即刷盘。 */
  static delete(key: string): void {
    if (PreferencesUtil.prefs === null) {
      return;
    }
    try {
      PreferencesUtil.prefs.deleteSync(key);
      PreferencesUtil.prefs.flushSync();
    } catch {
      Log.e('PreferencesUtil.delete failed');
    }
  }
}
