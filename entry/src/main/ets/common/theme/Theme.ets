import { Colors, BadgePalette } from './Colors';
import { Spacing, Radius } from './Metrics';
import { FontSize } from './Typography';
import { ThemeManager } from './ThemeManager';

export { Colors, BadgePalette, Spacing, Radius, FontSize, ThemeManager };

/**
 * 是否深色模式。由 ThemeManager 管理。
 */
export function isDark(): boolean {
  return ThemeManager.isDark();
}
