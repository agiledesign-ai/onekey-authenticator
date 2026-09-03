import { describe, expect, it } from '@ohos/hypium';
import {
  SettingsDetailKind,
  SettingsDetailPolicy,
  SettingsRoutes
} from '../main/ets/features/settings/model/SettingsDetailPolicy';
import {
  SettingsDetailContent,
  SettingsDetailIcon
} from '../main/ets/features/settings/model/SettingsDetailContent';

export default function settingsDetailPolicyTest() {
  describe('SettingsDetailPolicy', () => {
    it('defines one unique route for every settings detail page', 0, () => {
      const routes: string[] = SettingsRoutes.all();

      expect(routes.length).assertEqual(11);
      expect(routes[0]).assertEqual('pages/SecurityBackupPage');
      expect(routes[1]).assertEqual('pages/CloudSpacePage');
      expect(routes[2]).assertEqual('pages/ExportDataPage');
      expect(routes[3]).assertEqual('pages/ImportDataPage');
      expect(routes[4]).assertEqual('pages/TwoFactorGuidePage');
      expect(routes[5]).assertEqual('pages/AboutAppPage');
      expect(routes[6]).assertEqual('pages/VersionInfoPage');
      expect(routes[7]).assertEqual('pages/PrivacyPolicyPage');
      expect(routes[8]).assertEqual('pages/ClearAccountsPage');
      expect(routes[9]).assertEqual('pages/CardConfigPage');
      expect(routes[10]).assertEqual('pages/FeedbackPage');
      for (let i: number = 0; i < routes.length; i++) {
        expect(routes.indexOf(routes[i])).assertEqual(i);
      }
    });

    it('keeps page titles and destructive state explicit', 0, () => {
      expect(SettingsDetailPolicy.title(SettingsDetailKind.EXPORT)).assertEqual('导出数据');
      expect(SettingsDetailPolicy.title(SettingsDetailKind.IMPORT)).assertEqual('导入数据');
      expect(SettingsDetailPolicy.title(SettingsDetailKind.VERSION)).assertEqual('版本信息');
      expect(SettingsDetailPolicy.title(SettingsDetailKind.PRIVACY)).assertEqual('隐私政策');
      expect(SettingsDetailPolicy.title(SettingsDetailKind.CLEAR)).assertEqual('清空所有账号');
      expect(SettingsDetailPolicy.isDangerous(SettingsDetailKind.CLEAR)).assertEqual(true);
      expect(SettingsDetailPolicy.isDangerous(SettingsDetailKind.EXPORT)).assertEqual(false);
    });

    it('only enables actions that can change the current state', 0, () => {
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.EXPORT, 0)).assertEqual(false);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.EXPORT, 2)).assertEqual(true);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.IMPORT, 0)).assertEqual(true);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.CLEAR, 0)).assertEqual(false);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.CLEAR, 2)).assertEqual(true);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.VERSION, 2)).assertEqual(false);
      expect(SettingsDetailPolicy.canRunPrimaryAction(SettingsDetailKind.PRIVACY, 2)).assertEqual(false);
    });

    it('allows clearing only after confirmation with existing accounts', 0, () => {
      expect(SettingsDetailPolicy.shouldClearAccounts(false, 3)).assertEqual(false);
      expect(SettingsDetailPolicy.shouldClearAccounts(true, 0)).assertEqual(false);
      expect(SettingsDetailPolicy.shouldClearAccounts(true, 3)).assertEqual(true);
    });

    it('keeps native-list content concise and page-specific', 0, () => {
      expect(SettingsDetailContent.aboutSections().length).assertEqual(2);
      expect(SettingsDetailContent.versionSections().length).assertEqual(1);
      expect(SettingsDetailContent.privacyArticle().sections.length).assertEqual(6);
      expect(SettingsDetailContent.clearSections().length).assertEqual(1);
      expect(SettingsDetailContent.privacyArticle().sections[0].heading).assertEqual('1. 数据留在本机');
      expect(SettingsDetailContent.versionSections()[0].title).assertEqual('版本详情');
      expect(SettingsDetailContent.clearSections()[0].items.length).assertEqual(4);
    });

    it('encodes row meaning with icons and short status labels', 0, () => {
      expect(SettingsDetailContent.privacyArticle().sections[1].heading).assertEqual('2. 权限使用');
      expect(SettingsDetailContent.clearSections()[0].items[0].dangerous).assertEqual(true);
      expect(SettingsDetailContent.clearSections()[0].items[0].icon)
        .assertEqual(SettingsDetailIcon.TRASH);
    });

    it('separates product explanation from version details', 0, () => {
      expect(SettingsDetailContent.aboutName()).assertEqual('2FA验证器-工具');
      expect(SettingsDetailContent.aboutTagline()).assertEqual('本地优先，云空间可选');
      expect(SettingsDetailContent.aboutSections()[0].title).assertEqual('能力');
      expect(SettingsDetailContent.aboutSections()[0].items.length).assertEqual(5);
      expect(SettingsDetailContent.aboutSections()[1].title).assertEqual('原则');
      expect(SettingsDetailContent.aboutSections()[1].items[0].title).assertEqual('默认不出设备');
      expect(SettingsDetailContent.aboutSections()[1].items[1].badge).assertEqual('可选');
      expect(SettingsDetailContent.privacyArticle().notice.indexOf('不连接服务器') >= 0).assertFalse();
      expect(SettingsDetailContent.privacyArticle().notice.indexOf('华为云空间') >= 0).assertTrue();
      expect(SettingsDetailContent.privacyArticle().sections[4].heading).assertEqual('5. 华为账号与云空间');
      expect(SettingsDetailContent.versionSections()[0].items.length).assertEqual(2);
    });
  });
}
