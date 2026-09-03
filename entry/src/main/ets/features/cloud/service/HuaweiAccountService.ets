import { common } from '@kit.AbilityKit';
import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { BusinessError, distributedAccount } from '@kit.BasicServicesKit';
import { Log } from '../../../common/utils/LogUtil';
import { CloudSettings } from '../model/CloudSettings';
import { HuaweiAccountLoginPolicy, HuaweiLoginIntent } from '../model/HuaweiAccountLoginPolicy';
import { CloudSettingsStore } from '../store/CloudSettingsStore';

export interface HuaweiLoginResult {
  success: boolean;
  message: string;
  code: number;
}

interface HuaweiIdLoginStep {
  code: number;
  openID: string;
}

/** 点按登录对齐参考项目：取消旧授权 → 强制登录 → profile 授权。 */
export class HuaweiAccountService {
  private context: common.UIAbilityContext;
  private readonly settings: CloudSettingsStore;
  private busy: boolean = false;

  constructor(context: common.UIAbilityContext, settings: CloudSettingsStore = new CloudSettingsStore()) {
    this.context = context;
    this.settings = settings;
  }

  async restore(): Promise<HuaweiLoginResult> {
    const current: CloudSettings = this.settings.load();
    if (current.loggedIn) {
      return { success: true, message: '已登录', code: 0 };
    }
    return { success: false, message: '未登录', code: 1001502001 };
  }

  async probeSystemAccountName(): Promise<string> {
    try {
      const ability = distributedAccount.getDistributedAccountAbility();
      const info = await ability.getOsAccountDistributedInfo();
      if (info.status === distributedAccount.DistributedAccountStatus.LOGGED_IN && info.name.length > 0) {
        return info.name;
      }
    } catch (error) {
      Log.w(`HuaweiAccountService.probeSystemAccountName failed ${HuaweiAccountService.errorCode(error as BusinessError)}`);
    }
    return '';
  }

  async login(context?: common.UIAbilityContext): Promise<HuaweiLoginResult> {
    if (context) {
      this.context = context;
    }
    if (HuaweiAccountLoginPolicy.preferSilentOnTap()) {
      const silent: HuaweiLoginResult = await this.authenticate('restore');
      if (silent.success) {
        return { success: true, message: '已登录', code: 0 };
      }
      if (!HuaweiAccountLoginPolicy.shouldForceLoginAfterSilentFailure(silent.code)) {
        return silent;
      }
    }
    return await this.authenticate('tap');
  }

  async logout(): Promise<void> {
    await this.cancelAuthorization();
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: false,
      loggedIn: false,
      nickname: '',
      avatarUri: '',
      userId: '',
      status: current.status,
      lastSyncTime: current.lastSyncTime
    });
  }

  private async authenticate(intent: HuaweiLoginIntent): Promise<HuaweiLoginResult> {
    if (this.busy) {
      return { success: false, message: HuaweiAccountLoginPolicy.messageFor(1001500002), code: 1001500002 };
    }
    this.busy = true;
    try {
      await HuaweiAccountService.settle();
      if (HuaweiAccountLoginPolicy.cancelBeforeLogin()) {
        await this.cancelAuthorization();
      }
      const loginStep: HuaweiIdLoginStep = await this.loginWithHuaweiId(HuaweiAccountLoginPolicy.forceLogin(intent));
      if (loginStep.code !== 0) {
        return { success: false, message: HuaweiAccountLoginPolicy.messageFor(loginStep.code), code: loginStep.code };
      }
      const authorized: HuaweiLoginResult = await this.authorize(HuaweiAccountLoginPolicy.forceAuthorization(intent));
      if (authorized.success) {
        return authorized;
      }
      if (!HuaweiAccountLoginPolicy.acceptSilentLoginWithoutProfile()) {
        return authorized;
      }
      const nickname: string = await this.readSystemAccountName();
      this.saveCredential(nickname, '', loginStep.openID);
      return { success: true, message: '已登录', code: 0 };
    } finally {
      this.busy = false;
    }
  }

  private async cancelAuthorization(): Promise<void> {
    try {
      const provider = new authentication.HuaweiIDProvider();
      const cancelRequest = provider.createCancelAuthorizationRequest();
      const controller = new authentication.AuthenticationController(this.context);
      await controller.executeRequest(cancelRequest);
    } catch {
      Log.w('HuaweiAccountService.cancelAuthorization skipped');
    }
  }

  private async loginWithHuaweiId(forceLogin: boolean): Promise<HuaweiIdLoginStep> {
    const provider = new authentication.HuaweiIDProvider();
    const request = provider.createLoginWithHuaweiIDRequest();
    request.forceLogin = forceLogin;
    if (HuaweiAccountLoginPolicy.attachCsrfState()) {
      request.state = util.generateRandomUUID();
    }
    try {
      const controller = new authentication.AuthenticationController(this.context);
      const result = await controller.executeRequest(request);
      const response = result as authentication.LoginWithHuaweiIDResponse;
      if (HuaweiAccountLoginPolicy.attachCsrfState() && response.state && request.state !== response.state) {
        return { code: -2, openID: '' };
      }
      if (!response.data || !response.data.openID) {
        return { code: -1, openID: '' };
      }
      return { code: 0, openID: response.data.openID };
    } catch (error) {
      const business: BusinessError = error as BusinessError;
      Log.e(`HuaweiAccountService.loginWithHuaweiId ${business.code} ${business.message}`);
      return { code: HuaweiAccountService.errorCode(business), openID: '' };
    }
  }

  private async authorize(forceAuthorization: boolean): Promise<HuaweiLoginResult> {
    const provider = new authentication.HuaweiIDProvider();
    const request = provider.createAuthorizationWithHuaweiIDRequest();
    request.scopes = HuaweiAccountLoginPolicy.authorizationScopes();
    request.forceAuthorization = forceAuthorization;
    if (HuaweiAccountLoginPolicy.attachCsrfState()) {
      request.state = util.generateRandomUUID();
    }
    try {
      const controller = new authentication.AuthenticationController(this.context);
      const result = await controller.executeRequest(request);
      const response = result as authentication.AuthorizationWithHuaweiIDResponse;
      if (HuaweiAccountLoginPolicy.attachCsrfState() && response.state && request.state !== response.state) {
        return { success: false, message: HuaweiAccountLoginPolicy.messageFor(-2), code: -2 };
      }
      const credential = response.data;
      if (!credential) {
        return { success: false, message: '未获取到账号信息', code: -1 };
      }
      this.saveCredential(credential.nickName, credential.avatarUri, credential.openID);
      return { success: true, message: forceAuthorization ? '登录成功' : '已登录', code: 0 };
    } catch (error) {
      const business: BusinessError = error as BusinessError;
      const code: number = HuaweiAccountService.errorCode(business);
      Log.e(`HuaweiAccountService.authorize ${code} ${business.message}`);
      return { success: false, message: HuaweiAccountLoginPolicy.messageFor(code), code: code };
    }
  }

  private async readSystemAccountName(): Promise<string> {
    const name: string = await this.probeSystemAccountName();
    return name.length > 0 ? name : '华为账号';
  }

  private saveCredential(nickName: string | undefined, avatarUri: string | undefined, openID: string | undefined): void {
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: current.autoSync,
      loggedIn: true,
      nickname: nickName || '华为账号',
      avatarUri: avatarUri || '',
      userId: openID || '',
      status: current.status,
      lastSyncTime: current.lastSyncTime
    });
  }

  private static settle(): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, 60);
    });
  }

  private static errorCode(error: BusinessError): number {
    return typeof error.code === 'number' ? error.code : -1;
  }
}
