/**
 * Public-build gate for Huawei Cloud Space.
 * Enable only after replacing the manifest values with your own AGC application.
 */
export class CloudFeaturePolicy {
  private static readonly ENABLED: boolean = false;

  static isEnabled(): boolean {
    return CloudFeaturePolicy.ENABLED;
  }
}
