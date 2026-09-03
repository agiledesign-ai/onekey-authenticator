import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';
import { CloudMergePolicy, CloudMergeSnapshot } from '../model/CloudMergePolicy';
import { CloudSettings } from '../model/CloudSettings';
import { CloudCommand, CloudCommandResult, CloudSyncState } from '../model/CloudSyncState';

export { CloudMergeSnapshot };

export interface CloudAuthGate {
  isLoggedIn(): boolean;
  requestDataSync(): Promise<boolean>;
}

export interface CloudMirrorGateway {
  configure(autoSync: boolean): Promise<boolean>;
  stageAll(accounts: AccountItem[], groups: GroupItem[]): Promise<boolean>;
  stageAccount(item: AccountItem): Promise<boolean>;
  deleteAccount(id: string): Promise<boolean>;
  deleteAccounts(ids: string[]): Promise<boolean>;
  push(listener: (state: CloudSyncState) => void): Promise<boolean>;
  pull(listener: (state: CloudSyncState) => void): Promise<CloudMergeSnapshot | null>;
}

export interface CloudLocalVault {
  snapshot(): CloudMergeSnapshot;
  replace(next: CloudMergeSnapshot): boolean;
  restore(previous: CloudMergeSnapshot): boolean;
}

export interface CloudSettingsPort {
  load(): CloudSettings;
  save(settings: CloudSettings): void;
}

/**
 * 编排自动同步、手动推送/获取，以及本机变更对镜像的跟随。
 */
export class CloudSyncCoordinator {
  private readonly auth: CloudAuthGate;
  private readonly mirror: CloudMirrorGateway;
  private readonly vault: CloudLocalVault;
  private readonly settings: CloudSettingsPort;
  private syncing: boolean = false;
  private applyingRemote: boolean = false;
  private lastFailureStatus: string = '';

  constructor(
    auth: CloudAuthGate,
    mirror: CloudMirrorGateway,
    vault: CloudLocalVault,
    settings: CloudSettingsPort
  ) {
    this.auth = auth;
    this.mirror = mirror;
    this.vault = vault;
    this.settings = settings;
  }

  isSyncing(): boolean {
    return this.syncing;
  }

  async enableAutoSync(): Promise<CloudCommandResult> {
    if (this.syncing) {
      return CloudCommand.busy();
    }
    if (!this.auth.isLoggedIn()) {
      return this.failAndKeepOff('请先登录');
    }
    this.syncing = true;
    this.lastFailureStatus = '';
    this.publish('正在准备', false, 0);
    try {
      if (!await this.auth.requestDataSync()) {
        return this.failAndKeepOff('未授权云同步');
      }
      if (!await this.mirror.configure(false)) {
        return this.failAndKeepOff('无法开启云同步');
      }
      const local: CloudMergeSnapshot = this.vault.snapshot();
      if (await this.mirror.pull((state: CloudSyncState) => this.observe(state)) === null) {
        return this.failAndKeepOff(this.failureStatus('推送准备失败'));
      }
      if (!await this.mirror.stageAll(local.accounts, local.groups)) {
        return this.failAndKeepOff('推送准备失败');
      }
      if (!await this.mirror.push((state: CloudSyncState) => this.observe(state))) {
        return this.failAndKeepOff(this.failureStatus('推送失败'));
      }
      const cloud: CloudMergeSnapshot | null = await this.mirror.pull((state: CloudSyncState) => this.observe(state));
      if (cloud === null) {
        return this.failAndKeepOff('获取失败');
      }
      const merged: CloudMergeSnapshot = CloudMergePolicy.merge(local, cloud);
      this.applyingRemote = true;
      const replaced: boolean = this.vault.replace(merged);
      this.applyingRemote = false;
      if (!replaced) {
        this.vault.restore(local);
        return this.failAndKeepOff('本地更新失败');
      }
      if (!await this.mirror.configure(true)) {
        this.vault.restore(local);
        return this.failAndKeepOff('无法开启云同步');
      }
      return this.succeed('云空间自动同步已开启', true);
    } finally {
      this.syncing = false;
    }
  }

  async disableAutoSync(): Promise<CloudCommandResult> {
    if (this.syncing) {
      return CloudCommand.busy();
    }
    this.syncing = true;
    try {
      await this.mirror.configure(false);
      const current: CloudSettings = this.settings.load();
      this.settings.save({
        autoSync: false,
        loggedIn: current.loggedIn,
        nickname: current.nickname,
        avatarUri: current.avatarUri,
        userId: current.userId,
        status: '云空间自动同步已关闭',
        lastSyncTime: current.lastSyncTime
      });
      return CloudCommand.ok('云空间自动同步已关闭');
    } finally {
      this.syncing = false;
    }
  }

  async push(): Promise<CloudCommandResult> {
    if (this.syncing) {
      return CloudCommand.busy();
    }
    if (!this.auth.isLoggedIn()) {
      return CloudCommand.fail('请先登录');
    }
    this.syncing = true;
    this.lastFailureStatus = '';
    this.publish('正在推送', this.settings.load().autoSync, this.settings.load().lastSyncTime);
    try {
      if (!await this.auth.requestDataSync()) {
        return CloudCommand.fail('未授权云同步');
      }
      if (!await this.mirror.configure(false)) {
        return CloudCommand.fail('云同步不可用');
      }
      if (await this.mirror.pull((state: CloudSyncState) => this.observe(state)) === null) {
        return CloudCommand.fail(this.failureStatus('推送准备失败'));
      }
      const local: CloudMergeSnapshot = this.vault.snapshot();
      if (!await this.mirror.stageAll(local.accounts, local.groups)) {
        return CloudCommand.fail('推送准备失败');
      }
      const pushed: boolean = await this.mirror.push((state: CloudSyncState) => this.observe(state));
      if (this.settings.load().autoSync) {
        await this.mirror.configure(true);
      }
      if (!pushed) {
        return CloudCommand.fail(this.failureStatus('推送失败'));
      }
      return this.succeed('推送成功', this.settings.load().autoSync);
    } finally {
      this.syncing = false;
    }
  }

  async pull(): Promise<CloudCommandResult> {
    if (this.syncing) {
      return CloudCommand.busy();
    }
    if (!this.auth.isLoggedIn()) {
      return CloudCommand.fail('请先登录');
    }
    this.syncing = true;
    this.lastFailureStatus = '';
    this.publish('正在获取', this.settings.load().autoSync, this.settings.load().lastSyncTime);
    try {
      if (!await this.auth.requestDataSync()) {
        return CloudCommand.fail('未授权云同步');
      }
      if (!await this.mirror.configure(false)) {
        return CloudCommand.fail('云同步不可用');
      }
      const local: CloudMergeSnapshot = this.vault.snapshot();
      const cloud: CloudMergeSnapshot | null = await this.mirror.pull((state: CloudSyncState) => this.observe(state));
      if (this.settings.load().autoSync) {
        await this.mirror.configure(true);
      }
      if (cloud === null) {
        return CloudCommand.fail(this.failureStatus('获取失败'));
      }
      const merged: CloudMergeSnapshot = CloudMergePolicy.merge(local, cloud);
      this.applyingRemote = true;
      const replaced: boolean = this.vault.replace(merged);
      this.applyingRemote = false;
      if (!replaced) {
        this.vault.restore(local);
        return CloudCommand.fail('本地更新失败');
      }
      return this.succeed('获取成功', this.settings.load().autoSync);
    } finally {
      this.syncing = false;
    }
  }

  async onLocalAccountUpserted(item: AccountItem): Promise<void> {
    if (!this.canFollowLocal()) {
      return;
    }
    await this.mirror.stageAccount(item);
  }

  async onLocalAccountRemoved(id: string): Promise<void> {
    if (!this.canFollowLocal()) {
      return;
    }
    await this.mirror.deleteAccount(id);
    await this.mirror.push((state: CloudSyncState) => this.observe(state));
  }

  async onLocalAccountsCleared(ids: string[]): Promise<void> {
    if (!this.canFollowLocal()) {
      return;
    }
    await this.mirror.deleteAccounts(ids);
    await this.mirror.push((state: CloudSyncState) => this.observe(state));
  }

  async onLocalGroupUpserted(item: GroupItem): Promise<void> {
    if (!this.canFollowLocal()) {
      return;
    }
    const local: CloudMergeSnapshot = this.vault.snapshot();
    await this.mirror.stageAll(local.accounts, local.groups.concat([item]));
  }

  logout(): void {
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: false,
      loggedIn: false,
      nickname: '',
      avatarUri: '',
      userId: '',
      status: '云空间自动同步已关闭',
      lastSyncTime: current.lastSyncTime
    });
    this.mirror.configure(false);
  }

  private canFollowLocal(): boolean {
    return this.settings.load().autoSync && !this.applyingRemote;
  }

  private observe(state: CloudSyncState): void {
    if (state.finished && !state.success) {
      this.lastFailureStatus = state.status;
    }
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: current.autoSync,
      loggedIn: current.loggedIn,
      nickname: current.nickname,
      avatarUri: current.avatarUri,
      userId: current.userId,
      status: state.status,
      lastSyncTime: current.lastSyncTime
    });
  }

  private succeed(status: string, autoSync: boolean): CloudCommandResult {
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: autoSync,
      loggedIn: current.loggedIn,
      nickname: current.nickname,
      avatarUri: current.avatarUri,
      userId: current.userId,
      status: status,
      lastSyncTime: Date.now()
    });
    return CloudCommand.ok(status);
  }

  private failAndKeepOff(status: string): CloudCommandResult {
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: false,
      loggedIn: current.loggedIn,
      nickname: current.nickname,
      avatarUri: current.avatarUri,
      userId: current.userId,
      status: status,
      lastSyncTime: current.lastSyncTime
    });
    return CloudCommand.fail(status);
  }

  private failureStatus(fallback: string): string {
    return this.lastFailureStatus.length > 0 ? this.lastFailureStatus : fallback;
  }

  private publish(status: string, autoSync: boolean, lastSyncTime: number): void {
    const current: CloudSettings = this.settings.load();
    this.settings.save({
      autoSync: autoSync,
      loggedIn: current.loggedIn,
      nickname: current.nickname,
      avatarUri: current.avatarUri,
      userId: current.userId,
      status: status,
      lastSyncTime: lastSyncTime
    });
  }
}
