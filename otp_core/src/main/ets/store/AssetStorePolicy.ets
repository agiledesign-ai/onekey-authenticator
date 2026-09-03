import { asset } from '@kit.AssetStoreKit';

/** Asset Store 写入守卫：本机解锁后可读，禁止系统同步。 */
export class AssetStorePolicy {
  static applyPersistenceGuards(attributes: asset.AssetMap): void {
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_UNLOCKED);
    attributes.set(asset.Tag.REQUIRE_PASSWORD_SET, false);
    attributes.set(asset.Tag.AUTH_TYPE, asset.AuthType.NONE);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    attributes.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE);
  }
}
