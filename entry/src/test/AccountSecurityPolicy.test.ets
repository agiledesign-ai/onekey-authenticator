import { describe, expect, it } from '@ohos/hypium';
import { AccountSecurityPolicy, OtpCredential } from '../main/ets/features/security/model/AccountSecurityPolicy';
import { OtpType } from '../main/ets/model/OtpType';

export default function accountSecurityPolicyTest() {
  describe('AccountSecurityPolicy', () => {
    it('normalizes valid Base32 without accepting invalid characters', 0, () => {
      expect(AccountSecurityPolicy.normalizeSecret('jbswy3dpehpk3pxp')).assertEqual('JBSWY3DPEHPK3PXP');
      expect(AccountSecurityPolicy.normalizeSecret('JBSW Y3DP')).assertEqual('');
      expect(AccountSecurityPolicy.normalizeSecret('JBSW-Y3DP')).assertEqual('');
    });

    it('detects duplicates by secret and complete TOTP parameters', 0, () => {
      const first: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 0
      };
      const same: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'jbswy3dpehpk3pxp',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 0
      };
      const differentPeriod: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 60,
        counter: 0
      };

      expect(AccountSecurityPolicy.isDuplicate(first, same)).assertTrue();
      expect(AccountSecurityPolicy.isDuplicate(first, differentPeriod)).assertFalse();
    });

    it('validates parameters by OTP type', 0, () => {
      const totp: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA512',
        digits: 8,
        period: 60,
        counter: 0
      };
      const hotp: OtpCredential = {
        type: OtpType.HOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA256',
        digits: 6,
        period: 30,
        counter: 42
      };
      const steam: OtpCredential = {
        type: OtpType.STEAM,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 5,
        period: 30,
        counter: 0
      };
      const invalidTotpDigits: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA512',
        digits: 5,
        period: 60,
        counter: 0
      };
      const negativeHotpCounter: OtpCredential = {
        type: OtpType.HOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA256',
        digits: 6,
        period: 30,
        counter: -1
      };
      const fractionalHotpCounter: OtpCredential = {
        type: OtpType.HOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA256',
        digits: 6,
        period: 30,
        counter: 1.5
      };
      const invalidSteamDigits: OtpCredential = {
        type: OtpType.STEAM,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 0
      };
      const unsupportedAlgorithm: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'MD5',
        digits: 6,
        period: 30,
        counter: 0
      };

      expect(AccountSecurityPolicy.isValidCredential(totp)).assertTrue();
      expect(AccountSecurityPolicy.isValidCredential(hotp)).assertTrue();
      expect(AccountSecurityPolicy.isValidCredential(steam)).assertTrue();
      expect(AccountSecurityPolicy.isValidCredential(invalidTotpDigits)).assertFalse();
      expect(AccountSecurityPolicy.isValidCredential(negativeHotpCounter)).assertFalse();
      expect(AccountSecurityPolicy.isValidCredential(fractionalHotpCounter)).assertFalse();
      expect(AccountSecurityPolicy.isValidCredential(invalidSteamDigits)).assertFalse();
      expect(AccountSecurityPolicy.isValidCredential(unsupportedAlgorithm)).assertFalse();
    });

    it('uses type-specific duplicate identities', 0, () => {
      const hotp: OtpCredential = {
        type: OtpType.HOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 1
      };
      const advancedHotp: OtpCredential = {
        type: OtpType.HOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 10
      };
      const totp: OtpCredential = {
        type: OtpType.TOTP,
        secret: 'JBSWY3DPEHPK3PXP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 0
      };

      expect(AccountSecurityPolicy.isDuplicate(hotp, advancedHotp)).assertTrue();
      expect(AccountSecurityPolicy.isDuplicate(hotp, totp)).assertFalse();
    });
  });
}
