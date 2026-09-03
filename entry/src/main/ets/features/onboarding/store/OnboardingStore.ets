import { OnboardingPolicy } from '../model/OnboardingPolicy';
import { PreferencesUtil } from '../../../common/utils/PreferencesUtil';

const ONBOARDING_VERSION_KEY: string = 'onboarding_version';

/** 引导版本持久化边界。 */
export interface OnboardingVersionStorage {
  read(): number;
  write(value: number): void;
}

/** 使用现有 Preferences 存取引导版本。 */
export class OnboardingPreferencesStorage implements OnboardingVersionStorage {
  read(): number {
    return PreferencesUtil.getNumber(ONBOARDING_VERSION_KEY, 0);
  }

  write(value: number): void {
    PreferencesUtil.putNumber(ONBOARDING_VERSION_KEY, value);
  }
}

/** 首次引导状态存储。 */
export class OnboardingStore {
  private readonly storage: OnboardingVersionStorage;
  private readonly currentVersion: number;

  constructor(storage: OnboardingVersionStorage, currentVersion: number) {
    this.storage = storage;
    this.currentVersion = currentVersion;
  }

  shouldShow(): boolean {
    return OnboardingPolicy.shouldShow(this.storage.read(), this.currentVersion);
  }

  complete(): void {
    this.storage.write(this.currentVersion);
  }
}
