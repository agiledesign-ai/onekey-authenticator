/** 首次引导版本判断，保持纯逻辑以便单元测试。 */
export class OnboardingPolicy {
  static shouldShow(completedVersion: number, currentVersion: number): boolean {
    return completedVersion < currentVersion;
  }
}
