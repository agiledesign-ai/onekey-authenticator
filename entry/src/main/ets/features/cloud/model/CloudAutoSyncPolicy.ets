/** 未登录时，自动同步开关不可开，也不能停在打开外观。 */
export class CloudAutoSyncPolicy {
  static canOperateSwitch(loggedIn: boolean, syncing: boolean): boolean {
    return loggedIn && !syncing;
  }

  static shouldRejectEnable(loggedIn: boolean, turningOn: boolean): boolean {
    return turningOn && !loggedIn;
  }

  static nextEpoch(epoch: number, mustRemount: boolean): number {
    return mustRemount ? epoch + 1 : epoch;
  }

  static switchKey(autoSync: boolean, epoch: number): string {
    return `cloud-auto-sync-${autoSync ? 1 : 0}-${epoch}`;
  }
}
