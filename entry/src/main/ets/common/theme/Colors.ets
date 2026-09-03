/**
 * 颜色设计令牌（单一来源）。
 * 组件一律引用此处常量，禁止散落硬编码 hex。
 * 通过 applyColorTheme(mode) 在浅色/深色调色板间切换。
 */

export interface ColorTokens {
  page: string;
  homePageStart: string;
  homePageEnd: string;
  homeMaterial: string;
  homeAmbient: string;
  card: string;
  cardElevated: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  brand: string;
  brandLight: string;
  brandMaterial: string;
  warning: string;
  caution: string;
  success: string;
  divider: string;
  chipBg: string;
  border: string;
  cardPressed: string;
  hint: string;
  disabled: string;
  onColor: string;
  transparent: string;
  shadow: string;
}

/** 浅色调色板 */
const LIGHT_COLORS: ColorTokens = {
  page: '#FFFFFF',
  homePageStart: '#F9FBFF',
  homePageEnd: '#EDF2F7',
  homeMaterial: '#24FFFFFF',
  homeAmbient: '#260A66FF',
  card: '#FFFFFF',
  cardElevated: '#FAFAFB',
  textPrimary: '#182431',
  textSecondary: '#9DA5AE',
  textTertiary: '#A0A8B0',
  brand: '#0A59F7',
  brandLight: '#E8F0FE',
  brandMaterial: '#1A0A59F7',
  warning: '#FA2A2D',
  caution: '#ED6F21',
  success: '#4CB859',
  divider: '#F0F2F5',
  chipBg: '#F5F6F7',
  border: '#F1F2F4',
  cardPressed: '#F5F7FA',
  hint: '#7A828C',
  disabled: '#E0E4E8',
  onColor: '#FFFFFF',
  transparent: '#00000000',
  shadow: '#0D182431'
};

/** 深色调色板 */
const DARK_COLORS: ColorTokens = {
  page: '#000000',
  homePageStart: '#111823',
  homePageEnd: '#05080D',
  homeMaterial: '#26182431',
  homeAmbient: '#24317AF7',
  card: '#1C1C1C',
  cardElevated: '#2C2C2C',
  textPrimary: '#E6E6E6',
  textSecondary: '#8E96A0',
  textTertiary: '#6E7680',
  brand: '#317AF7',
  brandLight: '#1A2B3E',
  brandMaterial: '#24317AF7',
  warning: '#FF5557',
  caution: '#FF9148',
  success: '#5DD36C',
  divider: '#2A2A2A',
  chipBg: '#2C2C2C',
  border: '#2A2A2A',
  cardPressed: '#333333',
  hint: '#8E96A0',
  disabled: '#3A3A3A',
  onColor: '#FFFFFF',
  transparent: '#00000000',
  shadow: '#00000000'
};

/** 当前激活调色板（初始为浅色，由 ThemeManager 切换） */
export const Colors: ColorTokens = {
  page: LIGHT_COLORS.page,
  homePageStart: LIGHT_COLORS.homePageStart,
  homePageEnd: LIGHT_COLORS.homePageEnd,
  homeMaterial: LIGHT_COLORS.homeMaterial,
  homeAmbient: LIGHT_COLORS.homeAmbient,
  card: LIGHT_COLORS.card,
  cardElevated: LIGHT_COLORS.cardElevated,
  textPrimary: LIGHT_COLORS.textPrimary,
  textSecondary: LIGHT_COLORS.textSecondary,
  textTertiary: LIGHT_COLORS.textTertiary,
  brand: LIGHT_COLORS.brand,
  brandLight: LIGHT_COLORS.brandLight,
  brandMaterial: LIGHT_COLORS.brandMaterial,
  warning: LIGHT_COLORS.warning,
  caution: LIGHT_COLORS.caution,
  success: LIGHT_COLORS.success,
  divider: LIGHT_COLORS.divider,
  chipBg: LIGHT_COLORS.chipBg,
  border: LIGHT_COLORS.border,
  cardPressed: LIGHT_COLORS.cardPressed,
  hint: LIGHT_COLORS.hint,
  disabled: LIGHT_COLORS.disabled,
  onColor: LIGHT_COLORS.onColor,
  transparent: LIGHT_COLORS.transparent,
  shadow: LIGHT_COLORS.shadow
};

/**
 * 切换调色板。mode: 0=浅色 1=深色 2=跟随系统。
 * 将目标调色板属性逐一复制到 Colors 可变对象，
 * 调用方需同时触发 AppStorage.setOrCreate 以驱动组件重渲染。
 */
export function applyColorTheme(mode: number): void {
  const src: ColorTokens = mode === 1 ? DARK_COLORS : LIGHT_COLORS;
  Colors.page = src.page;
  Colors.homePageStart = src.homePageStart;
  Colors.homePageEnd = src.homePageEnd;
  Colors.homeMaterial = src.homeMaterial;
  Colors.homeAmbient = src.homeAmbient;
  Colors.card = src.card;
  Colors.cardElevated = src.cardElevated;
  Colors.textPrimary = src.textPrimary;
  Colors.textSecondary = src.textSecondary;
  Colors.textTertiary = src.textTertiary;
  Colors.brand = src.brand;
  Colors.brandLight = src.brandLight;
  Colors.brandMaterial = src.brandMaterial;
  Colors.warning = src.warning;
  Colors.caution = src.caution;
  Colors.success = src.success;
  Colors.divider = src.divider;
  Colors.chipBg = src.chipBg;
  Colors.border = src.border;
  Colors.cardPressed = src.cardPressed;
  Colors.hint = src.hint;
  Colors.disabled = src.disabled;
  Colors.onColor = src.onColor;
  Colors.transparent = src.transparent;
  Colors.shadow = src.shadow;
}

/** 账号徽章调色板（按服务名哈希取色） */
export const BadgePalette: string[] = [
  '#4285F4', '#EA4335', '#34A853', '#FF6D00',
  '#7B1FA2', '#0288D1', '#00838F', '#558B2F'
];
