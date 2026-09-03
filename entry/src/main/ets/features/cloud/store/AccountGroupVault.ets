import { AccountStore } from '../../../common/store/AccountStore';
import { GroupStore } from '../../../common/store/GroupStore';
import { CloudMergeSnapshot } from '../model/CloudMergePolicy';
import { CloudLocalVault } from '../service/CloudSyncCoordinator';

/** 把合并结果写回 Asset Store，失败时恢复快照。 */
export class AccountGroupVault implements CloudLocalVault {
  snapshot(): CloudMergeSnapshot {
    return {
      accounts: AccountStore.list().slice(),
      groups: GroupStore.list().slice()
    };
  }

  replace(next: CloudMergeSnapshot): boolean {
    const previous: CloudMergeSnapshot = this.snapshot();
    if (!GroupStore.replaceAll(next.groups)) {
      return false;
    }
    if (!AccountStore.replaceAll(next.accounts)) {
      GroupStore.replaceAll(previous.groups);
      return false;
    }
    return true;
  }

  restore(previous: CloudMergeSnapshot): boolean {
    const groupsOk: boolean = GroupStore.replaceAll(previous.groups);
    const accountsOk: boolean = AccountStore.replaceAll(previous.accounts);
    return groupsOk && accountsOk;
  }

}
