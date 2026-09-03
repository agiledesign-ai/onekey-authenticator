import { describe, it, expect } from '@ohos/hypium';
import { OnboardingStore, OnboardingVersionStorage } from '../main/ets/features/onboarding/store/OnboardingStore';

class MemoryOnboardingStorage implements OnboardingVersionStorage {
  value: number = 0;

  read(): number {
    return this.value;
  }

  write(value: number): void {
    this.value = value;
  }
}

export default function onboardingStoreTest() {
  describe('OnboardingStore', () => {
    it('persists the current version when onboarding completes', 0, () => {
      const storage = new MemoryOnboardingStorage();
      const store = new OnboardingStore(storage, 1);

      expect(store.shouldShow()).assertTrue();
      store.complete();
      expect(storage.value).assertEqual(1);
      expect(store.shouldShow()).assertFalse();
    });
  });
}
