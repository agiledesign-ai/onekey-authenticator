/** 设置二级页面类型。使用稳定数值，供页面策略与单元测试共享。 */
export class SettingsDetailKind {
  static readonly EXPORT: number = 0;
  static readonly IMPORT: number = 1;
  static readonly VERSION: number = 2;
  static readonly PRIVACY: number = 3;
  static readonly CLEAR: number = 4;
}

/** 设置二级页面路由的单一来源。 */
export class SettingsRoutes {
  static readonly SECURITY_BACKUP: string = 'pages/SecurityBackupPage';
  static readonly CLOUD_SPACE: string = 'pages/CloudSpacePage';
  static readonly EXPORT: string = 'pages/ExportDataPage';
  static readonly IMPORT: string = 'pages/ImportDataPage';
  static readonly TWO_FACTOR_GUIDE: string = 'pages/TwoFactorGuidePage';
  static readonly ABOUT: string = 'pages/AboutAppPage';
  static readonly VERSION: string = 'pages/VersionInfoPage';
  static readonly PRIVACY: string = 'pages/PrivacyPolicyPage';
  static readonly CLEAR: string = 'pages/ClearAccountsPage';
  static readonly CARD_CONFIG: string = 'pages/CardConfigPage';
  static readonly FEEDBACK: string = 'pages/FeedbackPage';

  static all(): string[] {
    return [
      SettingsRoutes.SECURITY_BACKUP,
      SettingsRoutes.CLOUD_SPACE,
      SettingsRoutes.EXPORT,
      SettingsRoutes.IMPORT,
      SettingsRoutes.TWO_FACTOR_GUIDE,
      SettingsRoutes.ABOUT,
      SettingsRoutes.VERSION,
      SettingsRoutes.PRIVACY,
      SettingsRoutes.CLEAR,
      SettingsRoutes.CARD_CONFIG,
      SettingsRoutes.FEEDBACK
    ];
  }
}

/** 与 UI 无关的操作规则，确保危险动作的启用条件一致。 */
export class SettingsDetailPolicy {
  private static readonly TITLES: string[] = [
    '导出数据',
    '导入数据',
    '版本信息',
    '隐私政策',
    '清空所有账号'
  ];

  static title(kind: number): string {
    return SettingsDetailPolicy.TITLES[kind];
  }

  static isDangerous(kind: number): boolean {
    return kind === SettingsDetailKind.CLEAR;
  }

  static canRunPrimaryAction(kind: number, accountCount: number): boolean {
    if (kind === SettingsDetailKind.IMPORT) {
      return true;
    }
    if (kind === SettingsDetailKind.EXPORT || kind === SettingsDetailKind.CLEAR) {
      return accountCount > 0;
    }
    return false;
  }

  static shouldClearAccounts(confirmed: boolean, accountCount: number): boolean {
    return confirmed && accountCount > 0;
  }
}
