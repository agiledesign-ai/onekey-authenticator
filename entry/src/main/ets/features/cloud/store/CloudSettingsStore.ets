import { PreferencesUtil } from '../../../common/utils/PreferencesUtil';
import { CloudSettings, CloudSettingsFactory } from '../model/CloudSettings';
import { CloudSettingsPort } from '../service/CloudSyncCoordinator';

/** 云空间开关、登录态和同步文案。密钥不进 Preferences。 */
export class CloudSettingsStore implements CloudSettingsPort {
  static readonly AUTO_SYNC_KEY: string = 'cloudAutoSyncEnabled';
  static readonly LOGGED_IN_KEY: string = 'huaweiLoggedIn';
  static readonly NICKNAME_KEY: string = 'huaweiNickname';
  static readonly AVATAR_KEY: string = 'huaweiAvatarUri';
  static readonly USER_ID_KEY: string = 'huaweiUserId';
  static readonly STATUS_KEY: string = 'cloudSyncStatus';
  static readonly LAST_SYNC_KEY: string = 'cloudLastSyncTime';
  static readonly SYNCING_KEY: string = 'cloudSyncing';

  static hydrate(): void {
    const settings: CloudSettings = new CloudSettingsStore().load();
    CloudSettingsStore.publish(settings);
    CloudSettingsStore.setSyncing(false);
  }

  load(): CloudSettings {
    return {
      autoSync: PreferencesUtil.getNumber(CloudSettingsStore.AUTO_SYNC_KEY, 0) === 1,
      loggedIn: PreferencesUtil.getNumber(CloudSettingsStore.LOGGED_IN_KEY, 0) === 1,
      nickname: PreferencesUtil.getString(CloudSettingsStore.NICKNAME_KEY, ''),
      avatarUri: PreferencesUtil.getString(CloudSettingsStore.AVATAR_KEY, ''),
      userId: PreferencesUtil.getString(CloudSettingsStore.USER_ID_KEY, ''),
      status: PreferencesUtil.getString(CloudSettingsStore.STATUS_KEY, CloudSettingsFactory.empty().status),
      lastSyncTime: PreferencesUtil.getNumber(CloudSettingsStore.LAST_SYNC_KEY, 0)
    };
  }

  save(settings: CloudSettings): void {
    PreferencesUtil.putNumber(CloudSettingsStore.AUTO_SYNC_KEY, settings.autoSync ? 1 : 0);
    PreferencesUtil.putNumber(CloudSettingsStore.LOGGED_IN_KEY, settings.loggedIn ? 1 : 0);
    PreferencesUtil.putString(CloudSettingsStore.NICKNAME_KEY, settings.nickname);
    PreferencesUtil.putString(CloudSettingsStore.AVATAR_KEY, settings.avatarUri);
    PreferencesUtil.putString(CloudSettingsStore.USER_ID_KEY, settings.userId);
    PreferencesUtil.putString(CloudSettingsStore.STATUS_KEY, settings.status);
    PreferencesUtil.putNumber(CloudSettingsStore.LAST_SYNC_KEY, settings.lastSyncTime);
    CloudSettingsStore.publish(settings);
  }

  static setSyncing(syncing: boolean): void {
    AppStorage.setOrCreate(CloudSettingsStore.SYNCING_KEY, syncing);
  }

  static formatLastSyncTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '尚未同步';
    }
    const date: Date = new Date(timestamp);
    const month: string = CloudSettingsStore.pad(date.getMonth() + 1);
    const day: string = CloudSettingsStore.pad(date.getDate());
    const hour: string = CloudSettingsStore.pad(date.getHours());
    const minute: string = CloudSettingsStore.pad(date.getMinutes());
    return `${date.getFullYear()}-${month}-${day} ${hour}:${minute}`;
  }

  static shouldShowCloudDisabledHint(status: string): boolean {
    return status.indexOf('未启用') >= 0 || status.indexOf('（3）') >= 0 || status.indexOf('(3)') >= 0;
  }

  private static publish(settings: CloudSettings): void {
    AppStorage.setOrCreate(CloudSettingsStore.AUTO_SYNC_KEY, settings.autoSync);
    AppStorage.setOrCreate(CloudSettingsStore.LOGGED_IN_KEY, settings.loggedIn);
    AppStorage.setOrCreate(CloudSettingsStore.NICKNAME_KEY, settings.nickname);
    AppStorage.setOrCreate(CloudSettingsStore.AVATAR_KEY, settings.avatarUri);
    AppStorage.setOrCreate(CloudSettingsStore.STATUS_KEY, settings.status);
    AppStorage.setOrCreate(CloudSettingsStore.LAST_SYNC_KEY, settings.lastSyncTime);
  }

  private static pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }
}
