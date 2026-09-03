import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { Log } from '../common/utils/LogUtil';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    Log.i('EntryBackupAbility onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    Log.i('EntryBackupAbility onRestore ok ' + JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}