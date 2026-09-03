import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Log } from '../common/utils/LogUtil';
import { WindowUtil } from '../common/utils/WindowUtil';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { ThemeManager } from '../common/theme/ThemeManager';
import { FaceUnlockRuntime } from '../features/security/service/FaceUnlockRuntime';
import { MigrationSessionStore } from '../features/migration/service/MigrationSessionStore';
import { CardUpdateService } from '../features/card/service/CardUpdateService';
import { CloudFeaturePolicy } from '../features/cloud/model/CloudFeaturePolicy';
import { CloudSyncRuntime } from '../features/cloud/service/CloudSyncRuntime';
import { CardDeepLink, CardDeepLinkKind } from '../features/card/model/CardDeepLink';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    PreferencesUtil.init(this.context);
    ThemeManager.init(this.context);
    FaceUnlockRuntime.init();
    CardUpdateService.init(this.context);
    if (CloudFeaturePolicy.isEnabled()) {
      CloudSyncRuntime.init(this.context);
    }
    AppStorage.setOrCreate('otpForegroundRefreshToken', 0);
    AppStorage.setOrCreate('pendingCardAccountId', '');
    AppStorage.setOrCreate('pendingCardConfigFormId', '');
    AppStorage.setOrCreate('pendingCardDimension', '');
    AppStorage.setOrCreate('homeTabRequestToken', 0);
    AppStorage.setOrCreate('accountsReady', false);
    this.captureCardWant(want);
    Log.i('Ability onCreate');
  }

  onNewWant(want: Want): void {
    this.captureCardWant(want);
  }

  onDestroy(): void {
    Log.i('Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    Log.i('Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        Log.e('Failed to load content. Cause: ' + JSON.stringify(err));
        return;
      }
      Log.i('Succeeded in loading content.');
    });

    WindowUtil.setupImmersive(windowStage);
  }

  onWindowStageDestroy(): void {
    Log.i('Ability onWindowStageDestroy');
  }

  onForeground(): void {
    if (FaceUnlockRuntime.enterForeground()) {
      WindowUtil.returnToFaceLock();
    }
    AppStorage.setOrCreate('otpForegroundRefreshToken', Date.now());
    Log.i('Ability onForeground');
  }

  onBackground(): void {
    FaceUnlockRuntime.enterBackground();
    MigrationSessionStore.clearIfBackgrounded();
    Log.i('Ability onBackground');
  }

  private captureCardWant(want: Want): void {
    if (want.parameters === undefined) {
      return;
    }
    const action = CardDeepLink.parse(want.parameters);
    if (action.kind === CardDeepLinkKind.LOCATE) {
      AppStorage.setOrCreate('pendingCardAccountId', action.accountId);
      AppStorage.setOrCreate('homeTabRequestToken', Date.now());
      return;
    }
    if (action.kind === CardDeepLinkKind.CONFIGURE) {
      AppStorage.setOrCreate('pendingCardConfigFormId', action.formId);
      AppStorage.setOrCreate('pendingCardDimension', action.dimension);
    }
  }
}
