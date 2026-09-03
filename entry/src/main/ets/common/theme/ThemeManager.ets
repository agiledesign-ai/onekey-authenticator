import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { applyColorTheme } from './Colors';

const STORAGE_KEY: string = 'themeMode';

/**
 * 主题管理器。管理浅色/深色/跟随系统三档模式。
 * 持久化到 Preferences，通过 AppStorage.setOrCreate 驱动组件重渲染。
 */
export class ThemeManager {
  static readonly LIGHT: number = 0;
  static readonly DARK: number = 1;
  static readonly SYSTEM: number = 2;

  private static appContext: common.ApplicationContext | null = null;

  /** 初始化：读取持久化模式并应用。需在 EntryAbility.onCreate 调用。 */
  static init(context: common.Context): void {
    ThemeManager.appContext = context.getApplicationContext();
    const mode: number = PreferencesUtil.getNumber(STORAGE_KEY, ThemeManager.SYSTEM);
    ThemeManager.apply(mode);
  }

  /** 获取当前模式。 */
  static getMode(): number {
    return PreferencesUtil.getNumber(STORAGE_KEY, ThemeManager.SYSTEM);
  }

  /** 设置并持久化模式。 */
  static setMode(mode: number): void {
    PreferencesUtil.putNumber(STORAGE_KEY, mode);
    ThemeManager.apply(mode);
  }

  /** 当前是否为深色。跟随系统模式下默认浅色。 */
  static isDark(): boolean {
    const mode: number = ThemeManager.getMode();
    if (mode === ThemeManager.DARK) {
      return true;
    }
    return false;
  }

  /** 应用模式：设系统颜色模式 + 切换调色板 + 触发重渲染。 */
  private static apply(mode: number): void {
    if (ThemeManager.appContext !== null) {
      const colorMode: ConfigurationConstant.ColorMode =
        mode === ThemeManager.LIGHT ? ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT :
        mode === ThemeManager.DARK ? ConfigurationConstant.ColorMode.COLOR_MODE_DARK :
        ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
      try {
        ThemeManager.appContext.setColorMode(colorMode);
      } catch {
        // setColorMode 可能因平台限制失败，忽略
      }
    }
    const effective: number = ThemeManager.isDark() ? ThemeManager.DARK : ThemeManager.LIGHT;
    applyColorTheme(effective);
    AppStorage.setOrCreate(STORAGE_KEY, mode);
  }
}
