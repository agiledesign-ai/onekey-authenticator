/** 云空间页需要持久化的非密钥状态。 */
export interface CloudSettings {
  autoSync: boolean;
  loggedIn: boolean;
  nickname: string;
  avatarUri: string;
  userId: string;
  status: string;
  lastSyncTime: number;
}

export class CloudSettingsFactory {
  static empty(): CloudSettings {
    return {
      autoSync: false,
      loggedIn: false,
      nickname: '',
      avatarUri: '',
      userId: '',
      status: '尚未同步',
      lastSyncTime: 0
    };
  }
}
