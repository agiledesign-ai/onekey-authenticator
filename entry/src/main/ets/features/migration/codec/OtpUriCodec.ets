import { OtpType } from '../../../model/OtpType';
import { AccountSecurityPolicy } from '../../security/model/AccountSecurityPolicy';
import { SecretCodec } from '../../otp/codec/SecretCodec';
import { OtpImportCandidate } from '../model/OtpImportCandidate';

export class OtpUriStatus {
  static readonly OK: string = 'ok';
  static readonly NEEDS_COUNTER: string = 'needs_counter';
  static readonly INVALID: string = 'invalid';
}

export interface OtpUriParseResult {
  status: string;
  candidate: OtpImportCandidate | null;
}

/** 解析 otpauth://totp|hotp|steam URI，不接受 Google 迁移格式。 */
export class OtpUriCodec {
  static parse(uri: string): OtpUriParseResult {
    const trimmed: string = uri.trim();
    const lower: string = trimmed.toLowerCase();
    let type: OtpType = OtpType.TOTP;
    let prefix: string = 'otpauth://totp/';
    if (lower.startsWith('otpauth://hotp/')) {
      type = OtpType.HOTP;
      prefix = trimmed.substring(0, 'otpauth://hotp/'.length);
    } else if (lower.startsWith('otpauth://steam/')) {
      type = OtpType.STEAM;
      prefix = trimmed.substring(0, 'otpauth://steam/'.length);
    } else if (lower.startsWith('otpauth://totp/')) {
      prefix = trimmed.substring(0, 'otpauth://totp/'.length);
    } else {
      return OtpUriCodec.invalid();
    }

    const afterPrefix: string = trimmed.substring(prefix.length);
    const qIndex: number = afterPrefix.indexOf('?');
    const rawLabel: string = qIndex >= 0 ? afterPrefix.substring(0, qIndex) : afterPrefix;
    const query: string = qIndex >= 0 ? afterPrefix.substring(qIndex + 1) : '';
    const label: string = OtpUriCodec.decodeComponent(rawLabel);
    if (label.length === 0 && rawLabel.length > 0) {
      return OtpUriCodec.invalid();
    }

    let labelIssuer: string = '';
    let account: string = '';
    const colonIndex: number = label.indexOf(':');
    if (colonIndex >= 0) {
      labelIssuer = label.substring(0, colonIndex).trim();
      account = label.substring(colonIndex + 1).trim();
    } else {
      account = label.trim();
    }

    const secretRaw: string = OtpUriCodec.queryParam(query, 'secret');
    if (secretRaw.length === 0) {
      return OtpUriCodec.invalid();
    }
    const secret: string = type === OtpType.STEAM ?
      SecretCodec.canonicalizeSteamSecret(secretRaw) :
      AccountSecurityPolicy.normalizeSecret(secretRaw);
    if (secret.length === 0) {
      return OtpUriCodec.invalid();
    }

    const queryIssuer: string = OtpUriCodec.queryParam(query, 'issuer');
    const issuerConflict: boolean = queryIssuer.length > 0 && labelIssuer.length > 0 &&
      queryIssuer.toLowerCase() !== labelIssuer.toLowerCase();
    let serviceName: string = queryIssuer.length > 0 ? queryIssuer : labelIssuer;
    if (serviceName.length === 0) {
      serviceName = type === OtpType.STEAM ? 'Steam' : '未知服务';
    }
    if (account.length === 0) {
      account = `${serviceName} 账号`;
    }

    const algorithmValue: string = OtpUriCodec.queryParam(query, 'algorithm');
    const algorithm: string = type === OtpType.STEAM ? 'SHA1' :
      (algorithmValue.length > 0 ? algorithmValue.toUpperCase().replace('-', '') : 'SHA1');
    const digitsValue: string = OtpUriCodec.queryParam(query, 'digits');
    const digits: number = type === OtpType.STEAM ? 5 :
      (digitsValue.length > 0 ? Number(digitsValue) : 6);
    const periodValue: string = OtpUriCodec.queryParam(query, 'period');
    const period: number = type === OtpType.HOTP || type === OtpType.STEAM ? 30 :
      (periodValue.length > 0 ? Number(periodValue) : 30);
    const counterValue: string = OtpUriCodec.queryParam(query, 'counter');
    const hasCounter: boolean = counterValue.length > 0;
    const counter: number = hasCounter ? Number(counterValue) : 0;
    if (hasCounter && (!Number.isInteger(counter) || counter < 0 || counter > Number.MAX_SAFE_INTEGER)) {
      return OtpUriCodec.invalid();
    }

    const candidate: OtpImportCandidate = {
      type: type,
      secret: secret,
      serviceName: serviceName,
      accountName: account,
      algorithm: algorithm,
      digits: digits,
      period: period,
      counter: type === OtpType.HOTP ? counter : 0,
      needsCounter: type === OtpType.HOTP && !hasCounter,
      issuerConflict: issuerConflict
    };
    if (!AccountSecurityPolicy.isValidCredential({
      type: candidate.type,
      secret: candidate.secret,
      algorithm: candidate.algorithm,
      digits: candidate.digits,
      period: candidate.period,
      counter: candidate.needsCounter ? 0 : candidate.counter
    })) {
      return OtpUriCodec.invalid();
    }
    if (candidate.needsCounter) {
      return { status: OtpUriStatus.NEEDS_COUNTER, candidate: candidate };
    }
    return { status: OtpUriStatus.OK, candidate: candidate };
  }

  private static invalid(): OtpUriParseResult {
    return { status: OtpUriStatus.INVALID, candidate: null };
  }

  private static queryParam(query: string, name: string): string {
    const pairs: string[] = query.split('&');
    for (let i: number = 0; i < pairs.length; i++) {
      const pair: string = pairs[i];
      const eqIndex: number = pair.indexOf('=');
      if (eqIndex >= 0) {
        const key: string = OtpUriCodec.decodeComponent(pair.substring(0, eqIndex)).toLowerCase();
        if (key === name) {
          return OtpUriCodec.decodeComponent(pair.substring(eqIndex + 1));
        }
      }
    }
    return '';
  }

  private static decodeComponent(value: string): string {
    try {
      return decodeURIComponent(value.replace(/\+/g, ' '));
    } catch {
      return '';
    }
  }
}
