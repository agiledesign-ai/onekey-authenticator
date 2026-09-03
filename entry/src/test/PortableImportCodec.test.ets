import { describe, expect, it } from '@ohos/hypium';
import { createAccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';
import {
  PortableImportCodec,
  PortableImportKind
} from '../main/ets/features/migration/codec/PortableImportCodec';

const TOTP_SECRET: string = 'JBSWY3DPEHPK3PXP';
const RFC_SECRET: string = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

/** OpenAuthenticator 备份中的 token 结构。 */
interface OpenAuthTokenFixture {
  name: string;
  issuer: string;
  secret: string;
  type: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
}

/** 2FAS 备份中的 otp 字段结构。 */
interface TwoFasOtpFixture {
  account: string;
  secret: string;
  tokenType: string;
  algorithm: string;
  digits: number;
  period: number;
}

/** 2FAS 备份中的 service 结构。 */
interface TwoFasServiceFixture {
  name: string;
  otp: TwoFasOtpFixture;
}

export default function portableImportCodecTest() {
  describe('PortableImportCodec', () => {
    it('parses OpenAuthenticator json tokens and uris', 0, () => {
      const tokens: OpenAuthTokenFixture[] = [{
        name: 'tester@example.com',
        issuer: 'GitHub',
        secret: TOTP_SECRET,
        type: 'TOTP',
        algorithm: 'SHA1',
        digits: 6,
        period: 30,
        counter: 0
      }];
      const content: string = JSON.stringify({
        encrypted: false,
        format: 'otpauth-uri',
        tokens: tokens,
        uris: [`otpauth://hotp/VPN:astra?secret=${RFC_SECRET}&counter=3`]
      });
      const parsed = PortableImportCodec.parse(content);
      expect(parsed.kind).assertEqual(PortableImportKind.PORTABLE);
      expect(parsed.candidates.length).assertEqual(2);
      expect(parsed.candidates[0].serviceName).assertEqual('GitHub');
      expect(parsed.candidates[0].accountName).assertEqual('tester@example.com');
      expect(parsed.candidates[1].type).assertEqual(OtpType.HOTP);
      expect(parsed.candidates[1].counter).assertEqual(3);
    });

    it('parses 2FAS services and rejects encrypted 2FAS backups', 0, () => {
      const services: TwoFasServiceFixture[] = [{
        name: 'GitHub',
        otp: {
          account: 'astra@example.com',
          secret: TOTP_SECRET,
          tokenType: 'TOTP',
          algorithm: 'SHA1',
          digits: 6,
          period: 30
        }
      }];
      const content: string = JSON.stringify({
        schemaVersion: 4,
        services: services
      });
      const parsed = PortableImportCodec.parse(content);
      expect(parsed.kind).assertEqual(PortableImportKind.PORTABLE);
      expect(parsed.candidates.length).assertEqual(1);
      expect(parsed.candidates[0].serviceName).assertEqual('GitHub');
      expect(parsed.candidates[0].accountName).assertEqual('astra@example.com');

      const encrypted = PortableImportCodec.parse(JSON.stringify({
        schemaVersion: 4,
        servicesEncrypted: 'AAAA'
      }));
      expect(encrypted.kind).assertEqual(PortableImportKind.ENCRYPTED_2FAS);
      expect(encrypted.candidates.length).assertEqual(0);
    });

    it('parses csv headers, tsv rows and otpauth text files', 0, () => {
      const csv: string = 'issuer,name,secret,type,algorithm,digits,period,counter\n' +
        `GitHub,tester@example.com,${TOTP_SECRET},TOTP,SHA1,6,30,0\n`;
      const csvParsed = PortableImportCodec.parse(csv);
      expect(csvParsed.candidates.length).assertEqual(1);
      expect(csvParsed.candidates[0].serviceName).assertEqual('GitHub');

      const tsv: string = `issuer\tname\tsecret\nEmail\thotp@example.com\t${RFC_SECRET}\n`;
      const tsvParsed = PortableImportCodec.parse(tsv);
      expect(tsvParsed.candidates.length).assertEqual(1);
      expect(tsvParsed.candidates[0].type).assertEqual(OtpType.TOTP);

      const txt: string = `otpauth://totp/GitHub:astra@example.com?secret=${TOTP_SECRET}\n` +
        `otpauth://steam/Steam:player?secret=${RFC_SECRET}\n`;
      const txtParsed = PortableImportCodec.parse(txt);
      expect(txtParsed.candidates.length).assertEqual(2);
      expect(txtParsed.candidates[1].type).assertEqual(OtpType.STEAM);
      expect(txtParsed.candidates[1].digits).assertEqual(5);
    });

    it('imports an unencrypted Steam maFile as a five-character Steam account', 0, () => {
      const content: string = JSON.stringify({
        shared_secret: RFC_SECRET,
        account_name: 'demo'
      });
      const parsed = PortableImportCodec.parse(content);
      expect(parsed.kind).assertEqual(PortableImportKind.PORTABLE);
      expect(parsed.candidates.length).assertEqual(1);
      expect(parsed.candidates[0].type).assertEqual(OtpType.STEAM);
      expect(parsed.candidates[0].serviceName).assertEqual('Steam');
      expect(parsed.candidates[0].accountName).assertEqual('demo');
      expect(parsed.candidates[0].digits).assertEqual(5);
    });

    it('detects a SecureKey vault envelope without decrypting it', 0, () => {
      const content: string = JSON.stringify({
        format: 'securekey-vault',
        version: 1,
        kdf: 'PBKDF2|SHA256',
        iterations: 310000,
        salt: 'AA==',
        iv: 'AA==',
        payload: 'AA=='
      });
      const parsed = PortableImportCodec.parse(content);
      expect(parsed.kind).assertEqual(PortableImportKind.VAULT);
      expect(parsed.candidates.length).assertEqual(0);
    });

    it('skips invalid secrets and treats missing HOTP counters as zero', 0, () => {
      const csv: string = 'issuer,name,secret,type\n' +
        'Bad,user,not-a-secret,TOTP\n' +
        `VPN,astra,${TOTP_SECRET},HOTP\n`;
      const parsed = PortableImportCodec.parse(csv);
      expect(parsed.invalid).assertEqual(1);
      expect(parsed.candidates.length).assertEqual(1);
      expect(parsed.candidates[0].type).assertEqual(OtpType.HOTP);
      expect(parsed.candidates[0].counter).assertEqual(0);
      expect(parsed.candidates[0].needsCounter).assertEqual(false);
    });

    it('round trips exported json without encryption', 0, () => {
      const totp = createAccountItem('t1', 'GitHub', 'astra@example.com', TOTP_SECRET, {
        type: OtpType.TOTP
      });
      const hotp = createAccountItem('h1', 'VPN', 'astra', TOTP_SECRET, {
        type: OtpType.HOTP,
        counter: 4
      });
      const steam = createAccountItem('s1', 'Steam', 'demo', RFC_SECRET, {
        type: OtpType.STEAM
      });
      const json: string = PortableImportCodec.encodeJson([totp, hotp, steam]);
      expect(json.indexOf('AES')).assertEqual(-1);
      expect(json.indexOf('securekey-vault')).assertEqual(-1);
      expect(json.indexOf('"encrypted"') >= 0).assertTrue();
      expect(json.indexOf('uris') < 0).assertTrue();

      const parsed = PortableImportCodec.parse(json);
      expect(parsed.kind).assertEqual(PortableImportKind.PORTABLE);
      expect(parsed.candidates.length).assertEqual(3);
      expect(parsed.candidates[0].serviceName).assertEqual('GitHub');
      expect(parsed.candidates[1].type).assertEqual(OtpType.HOTP);
      expect(parsed.candidates[1].counter).assertEqual(4);
      expect(parsed.candidates[2].type).assertEqual(OtpType.STEAM);
      expect(parsed.candidates[2].digits).assertEqual(5);
    });
  });
}
