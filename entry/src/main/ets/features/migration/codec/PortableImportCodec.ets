import { AccountItem, createAccountItem } from '../../../model/AccountItem';
import { OtpType } from '../../../model/OtpType';
import { AccountSecurityPolicy } from '../../security/model/AccountSecurityPolicy';
import { SecretCodec } from '../../otp/codec/SecretCodec';
import { OtpImportCandidate } from '../model/OtpImportCandidate';
import { GoogleMigrationCodec } from './GoogleMigrationCodec';
import { OtpUriCodec, OtpUriStatus } from './OtpUriCodec';

export class PortableImportKind {
  static readonly PORTABLE: string = 'portable';
  static readonly VAULT: string = 'vault';
  static readonly ENCRYPTED_2FAS: string = 'encrypted-2fas';
  static readonly ENCRYPTED_MAFILE: string = 'encrypted-mafile';
  static readonly EMPTY: string = 'empty';
}

export interface PortableImportResult {
  kind: string;
  candidates: OtpImportCandidate[];
  invalid: number;
}

interface PortableExportToken {
  name: string;
  issuer: string;
  secret: string;
  type: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
}

interface PortableExportFile {
  encrypted: boolean;
  app: string;
  format: string;
  version: number;
  tokens: PortableExportToken[];
}

interface VaultProbe {
  format?: string;
  servicesEncrypted?: string;
  services?: Object[];
  shared_secret?: string;
}

/**
 * 解析明文迁入文件：json / csv / tsv / txt / otpauth / maFile / 2fas。
 * 不解密 .skvault，也不写入存储。
 */
export class PortableImportCodec {
  static parse(content: string): PortableImportResult {
    const trimmed: string = content.trim();
    if (trimmed.length === 0) {
      return PortableImportCodec.result(PortableImportKind.EMPTY, [], 0);
    }
    if (trimmed.charAt(0) === '{' || trimmed.charAt(0) === '[') {
      try {
        const parsed: Object = JSON.parse(trimmed) as Object;
        const vault: VaultProbe = parsed as VaultProbe;
        if (vault.format === 'securekey-vault') {
          return PortableImportCodec.result(PortableImportKind.VAULT, [], 0);
        }
        if (typeof vault.servicesEncrypted === 'string' && vault.servicesEncrypted.length > 0 &&
          (vault.services === undefined || vault.services.length === 0)) {
          return PortableImportCodec.result(PortableImportKind.ENCRYPTED_2FAS, [], 0);
        }
        const collected: OtpImportCandidate[] = [];
        const invalidHolder: number[] = [0];
        PortableImportCodec.collectJson(parsed, collected, invalidHolder);
        return PortableImportCodec.result(PortableImportKind.PORTABLE, collected, invalidHolder[0]);
      } catch {
        return PortableImportCodec.result(PortableImportKind.EMPTY, [], 0);
      }
    }
    if (PortableImportCodec.looksEncryptedMaFile(trimmed)) {
      return PortableImportCodec.result(PortableImportKind.ENCRYPTED_MAFILE, [], 0);
    }
    return PortableImportCodec.parseLines(trimmed);
  }

  static encodeJson(accounts: AccountItem[]): string {
    const tokens: PortableExportToken[] = [];
    for (let i: number = 0; i < accounts.length; i++) {
      const account: AccountItem = accounts[i];
      tokens.push({
        name: account.accountName,
        issuer: account.serviceName,
        secret: account.secretKey,
        type: PortableImportCodec.exportType(account.type),
        algorithm: account.algorithm,
        digits: account.digits,
        period: account.period,
        counter: account.counter
      });
    }
    const payload: PortableExportFile = {
      encrypted: false,
      app: '2FA验证器-工具',
      format: 'otpauth-uri',
      version: 1,
      tokens: tokens
    };
    return JSON.stringify(payload);
  }

  static toAccounts(candidates: OtpImportCandidate[]): AccountItem[] {
    const accounts: AccountItem[] = [];
    const now: number = Date.now();
    for (let i: number = 0; i < candidates.length; i++) {
      const candidate: OtpImportCandidate = candidates[i];
      accounts.push(createAccountItem(
        `import-${now}-${i}`,
        candidate.serviceName,
        candidate.accountName,
        candidate.secret,
        {
          type: candidate.type,
          algorithm: candidate.algorithm,
          digits: candidate.digits,
          period: candidate.period,
          counter: candidate.counter
        }
      ));
    }
    return accounts;
  }

  private static result(kind: string, candidates: OtpImportCandidate[], invalid: number): PortableImportResult {
    return { kind: kind, candidates: candidates, invalid: invalid };
  }

  private static collectJson(value: Object, out: OtpImportCandidate[], invalid: number[]): void {
    if (typeof value === 'string') {
      PortableImportCodec.collectUri(value, out, invalid);
      return;
    }
    if (Array.isArray(value)) {
      const items: Object[] = value as Object[];
      for (let i: number = 0; i < items.length; i++) {
        PortableImportCodec.collectJson(items[i], out, invalid);
      }
      return;
    }
    if (typeof value !== 'object' || value === null) {
      return;
    }

    const tokens: Object | undefined = PortableImportCodec.readKey(value, 'tokens');
    const uris: Object | undefined = PortableImportCodec.readKey(value, 'uris');
    const services: Object | undefined = PortableImportCodec.readKey(value, 'services');
    let handled: boolean = false;
    if (Array.isArray(tokens)) {
      PortableImportCodec.collectJson(tokens, out, invalid);
      handled = true;
    }
    if (Array.isArray(uris)) {
      PortableImportCodec.collectJson(uris, out, invalid);
      handled = true;
    }
    if (Array.isArray(services)) {
      const list: Object[] = services as Object[];
      for (let i: number = 0; i < list.length; i++) {
        PortableImportCodec.collectService(list[i], out, invalid);
      }
      handled = true;
    }
    if (handled) {
      return;
    }

    const uri: string = PortableImportCodec.readString(value, [
      'uri', 'url', 'totp', 'otpUri', 'otpAuthUri', 'otpauth', 'otpAuth'
    ]);
    if (uri.length > 0) {
      PortableImportCodec.collectUri(uri, out, invalid);
      return;
    }

    const otp: Object | undefined = PortableImportCodec.readObject(value, 'otp');
    const info: Object | undefined = PortableImportCodec.readObject(value, 'info');
    const tokenSource: Object = otp !== undefined ? otp : (info !== undefined ? info : value);
    const sharedSecret: string = PortableImportCodec.readString(value, ['shared_secret', 'sharedSecret']);
    const secret: string = sharedSecret.length > 0 ? sharedSecret :
      PortableImportCodec.readString(value, [
        'secret', 'secretKey', 'secret_key', 'tokenSecret', 'otpSecret', 'otp_secret', 'seed', 'key'
      ]);
    const nestedSecret: string = secret.length > 0 ? secret :
      PortableImportCodec.readString(tokenSource, [
        'secret', 'secretKey', 'secret_key', 'shared_secret', 'tokenSecret', 'otpSecret', 'otp_secret', 'seed', 'key'
      ]);
    if (nestedSecret.length > 0) {
      let jsonType: string = PortableImportCodec.readString(value, ['type', 'tokenType', 'otpType', 'otp_type']);
      if (jsonType.length === 0) {
        jsonType = PortableImportCodec.readString(tokenSource, ['type', 'tokenType', 'otpType', 'otp_type']);
      }
      if (jsonType.length === 0 && sharedSecret.length > 0) {
        jsonType = 'Steam';
      }
      const name: string = PortableImportCodec.firstNonEmpty([
        PortableImportCodec.readString(value, [
          'name', 'service', 'label', 'accountName', 'account_name', 'account', 'username'
        ]),
        PortableImportCodec.readString(tokenSource, [
          'name', 'service', 'label', 'accountName', 'account_name', 'account', 'username'
        ])
      ]);
      const issuer: string = PortableImportCodec.firstNonEmpty([
        PortableImportCodec.readString(value, ['issuer', 'remark', 'platform', 'provider', 'vendor']),
        PortableImportCodec.readString(tokenSource, ['issuer', 'remark', 'platform', 'provider', 'vendor'])
      ]);
      const added: boolean = PortableImportCodec.pushCandidate(
        out,
        issuer,
        name,
        nestedSecret,
        jsonType,
        PortableImportCodec.firstNonEmpty([
          PortableImportCodec.readString(value, ['algorithm', 'algo']),
          PortableImportCodec.readString(tokenSource, ['algorithm', 'algo'])
        ]),
        PortableImportCodec.readNumber(value, ['digits'], PortableImportCodec.readNumber(tokenSource, ['digits'], -1)),
        PortableImportCodec.readNumber(value, ['period', 'interval', 'timeStep', 'time_step'],
          PortableImportCodec.readNumber(tokenSource, ['period', 'interval', 'timeStep', 'time_step'], -1)),
        PortableImportCodec.readNumber(value, ['counter'], PortableImportCodec.readNumber(tokenSource, ['counter'], -1))
      );
      if (!added) {
        invalid[0] = invalid[0] + 1;
      }
      return;
    }

    const keys: string[] = Object.keys(value);
    for (let i: number = 0; i < keys.length; i++) {
      const key: string = keys[i].toLowerCase();
      if (key === 'uri' || key === 'url' || key === 'totp' || key === 'otpuri' ||
        key === 'otpauthuri' || key === 'otpauth' || key === 'info' || key === 'otp') {
        continue;
      }
      const child: Object | undefined = PortableImportCodec.readKey(value, keys[i]);
      if (child !== undefined && typeof child === 'object' && child !== null) {
        PortableImportCodec.collectJson(child, out, invalid);
      }
    }
  }

  private static collectService(service: Object, out: OtpImportCandidate[], invalid: number[]): void {
    const otp: Object | undefined = PortableImportCodec.readObject(service, 'otp');
    const source: Object = otp !== undefined ? otp : service;
    const secret: string = PortableImportCodec.firstNonEmpty([
      PortableImportCodec.readString(source, ['secret']),
      PortableImportCodec.readString(service, ['secret'])
    ]);
    const added: boolean = PortableImportCodec.pushCandidate(
      out,
      PortableImportCodec.readString(service, ['name', 'issuer']),
      PortableImportCodec.readString(source, ['account', 'name', 'label']),
      secret,
      PortableImportCodec.readString(source, ['tokenType', 'type']),
      PortableImportCodec.readString(source, ['algorithm', 'algo']),
      PortableImportCodec.readNumber(source, ['digits'], -1),
      PortableImportCodec.readNumber(source, ['period'], -1),
      PortableImportCodec.readNumber(source, ['counter'], -1)
    );
    if (!added) {
      invalid[0] = invalid[0] + 1;
    }
  }

  private static collectUri(value: string, out: OtpImportCandidate[], invalid: number[]): void {
    const trimmed: string = value.trim();
    const migration = GoogleMigrationCodec.parse(trimmed);
    if (migration !== null) {
      for (let i: number = 0; i < migration.parameters.length; i++) {
        const parameter = migration.parameters[i];
        const added: boolean = PortableImportCodec.pushCandidate(
          out,
          parameter.issuer,
          parameter.name,
          parameter.secret,
          parameter.type,
          parameter.algorithm,
          parameter.digits,
          30,
          parameter.counter
        );
        if (!added) {
          invalid[0] = invalid[0] + 1;
        }
      }
      if (migration.parameters.length === 0) {
        invalid[0] = invalid[0] + 1;
      }
      return;
    }
    const parsed = OtpUriCodec.parse(trimmed);
    if (parsed.status === OtpUriStatus.INVALID || parsed.candidate === null) {
      invalid[0] = invalid[0] + 1;
      return;
    }
    const candidate: OtpImportCandidate = parsed.candidate;
    if (candidate.needsCounter) {
      candidate.needsCounter = false;
      candidate.counter = 0;
    }
    if (PortableImportCodec.isValid(candidate)) {
      out.push(candidate);
    } else {
      invalid[0] = invalid[0] + 1;
    }
  }

  private static parseLines(content: string): PortableImportResult {
    const lines: string[] = PortableImportCodec.splitLines(content);
    const header: Map<string, number> = PortableImportCodec.importHeader(lines);
    const out: OtpImportCandidate[] = [];
    let invalid: number = 0;
    for (let i: number = 0; i < lines.length; i++) {
      const line: string = lines[i].trim();
      if (line.length === 0) {
        continue;
      }
      const uriIndex: number = PortableImportCodec.indexOfUri(line);
      if (uriIndex >= 0) {
        const before: number = out.length;
        const invalidHolder: number[] = [0];
        PortableImportCodec.collectUri(line.substring(uriIndex), out, invalidHolder);
        invalid = invalid + invalidHolder[0];
        if (out.length === before && invalidHolder[0] === 0) {
          invalid++;
        }
        continue;
      }
      const columns: string[] = PortableImportCodec.splitImportLine(line);
      if (columns.length === 0 || (header.size > 0 && i === 0)) {
        continue;
      }
      let added: boolean = false;
      if (header.size > 0) {
        added = PortableImportCodec.pushCandidate(
          out,
          PortableImportCodec.headerValue(columns, header, 'issuer') ||
            PortableImportCodec.headerValue(columns, header, 'remark'),
          PortableImportCodec.headerValue(columns, header, 'name') ||
            PortableImportCodec.headerValue(columns, header, 'account'),
          PortableImportCodec.headerValue(columns, header, 'secret'),
          PortableImportCodec.headerValue(columns, header, 'type'),
          PortableImportCodec.headerValue(columns, header, 'algorithm') ||
            PortableImportCodec.headerValue(columns, header, 'algo'),
          PortableImportCodec.parseIntOr(PortableImportCodec.headerValue(columns, header, 'digits'), -1),
          PortableImportCodec.parseIntOr(PortableImportCodec.headerValue(columns, header, 'period'), -1),
          PortableImportCodec.parseIntOr(PortableImportCodec.headerValue(columns, header, 'counter'), -1)
        );
      } else if (columns.length >= 2) {
        added = PortableImportCodec.pushCandidate(
          out,
          columns.length > 2 ? columns[2] : '',
          columns[0],
          columns[1],
          columns.length > 3 ? columns[3] : 'TOTP',
          columns.length > 4 ? columns[4] : 'SHA1',
          columns.length > 5 ? PortableImportCodec.parseIntOr(columns[5], -1) : -1,
          columns.length > 6 ? PortableImportCodec.parseIntOr(columns[6], -1) : -1,
          columns.length > 7 ? PortableImportCodec.parseIntOr(columns[7], -1) : -1
        );
      } else {
        added = PortableImportCodec.pushCandidate(
          out, '', `导入账号${i + 1}`, columns[0], 'TOTP', 'SHA1', -1, -1, -1
        );
      }
      if (!added) {
        invalid++;
      }
    }
    return PortableImportCodec.result(PortableImportKind.PORTABLE, out, invalid);
  }

  private static pushCandidate(
    out: OtpImportCandidate[],
    issuer: string,
    name: string,
    secretRaw: string,
    typeRaw: string,
    algorithmRaw: string,
    digitsRaw: number,
    periodRaw: number,
    counterRaw: number
  ): boolean {
    const type: OtpType = PortableImportCodec.normalizeType(typeRaw, secretRaw);
    const secret: string = type === OtpType.STEAM ?
      SecretCodec.canonicalizeSteamSecret(secretRaw) :
      AccountSecurityPolicy.normalizeSecret(secretRaw);
    if (secret.length === 0) {
      return false;
    }
    const algorithm: string = type === OtpType.STEAM ? 'SHA1' :
      (algorithmRaw.trim().length > 0 ? algorithmRaw.trim().toUpperCase().split('-').join('') : 'SHA1');
    const digits: number = type === OtpType.STEAM ? 5 :
      (digitsRaw === 6 || digitsRaw === 8 ? digitsRaw : 6);
    const period: number = type === OtpType.TOTP ?
      (periodRaw === 15 || periodRaw === 30 || periodRaw === 60 ? periodRaw : 30) : 30;
    const counter: number = type === OtpType.HOTP ?
      (Number.isInteger(counterRaw) && counterRaw >= 0 ? counterRaw : 0) : 0;
    let serviceName: string = issuer.trim();
    let accountName: string = name.trim();
    if (serviceName.length === 0) {
      serviceName = type === OtpType.STEAM ? 'Steam' : (accountName.length > 0 ? accountName : '未知服务');
    }
    if (accountName.length === 0 || accountName === serviceName) {
      accountName = accountName.length > 0 && accountName !== serviceName ?
        accountName : `${serviceName} 账号`;
    }
    if (type === OtpType.STEAM && (accountName === 'Steam 账号' || accountName.length === 0) &&
      name.trim().length > 0) {
      accountName = name.trim();
    }
    const candidate: OtpImportCandidate = {
      type: type,
      secret: secret,
      serviceName: serviceName,
      accountName: accountName,
      algorithm: algorithm,
      digits: digits,
      period: period,
      counter: counter,
      needsCounter: false,
      issuerConflict: false
    };
    if (!PortableImportCodec.isValid(candidate)) {
      return false;
    }
    out.push(candidate);
    return true;
  }

  private static exportType(type: OtpType): string {
    if (type === OtpType.HOTP) {
      return 'HOTP';
    }
    if (type === OtpType.STEAM) {
      return 'STEAM';
    }
    return 'TOTP';
  }

  private static normalizeType(raw: string, secretRaw: string): OtpType {
    const value: string = raw.trim().toUpperCase();
    if (value === 'STEAM' || value === 'STEAMGUARD') {
      return OtpType.STEAM;
    }
    if (value === 'HOTP') {
      return OtpType.HOTP;
    }
    if (value.length === 0 && (secretRaw.indexOf('+') >= 0 || secretRaw.indexOf('/') >= 0 ||
      secretRaw.indexOf('=') >= 0)) {
      return OtpType.STEAM;
    }
    return OtpType.TOTP;
  }

  private static isValid(candidate: OtpImportCandidate): boolean {
    return AccountSecurityPolicy.isValidCredential({
      type: candidate.type,
      secret: candidate.secret,
      algorithm: candidate.algorithm,
      digits: candidate.digits,
      period: candidate.period,
      counter: candidate.counter
    });
  }

  private static looksEncryptedMaFile(content: string): boolean {
    if (content.length < 64 || PortableImportCodec.indexOfUri(content) >= 0) {
      return false;
    }
    const alphabet: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=\n\r';
    for (let i: number = 0; i < content.length; i++) {
      if (alphabet.indexOf(content.charAt(i)) < 0) {
        return false;
      }
    }
    return true;
  }

  private static importHeader(lines: string[]): Map<string, number> {
    const header: Map<string, number> = new Map<string, number>();
    if (lines.length === 0) {
      return header;
    }
    const columns: string[] = PortableImportCodec.splitImportLine(lines[0]);
    let hasSecret: boolean = false;
    for (let i: number = 0; i < columns.length; i++) {
      if (columns[i].trim().toLowerCase() === 'secret') {
        hasSecret = true;
      }
    }
    if (!hasSecret) {
      return header;
    }
    for (let i: number = 0; i < columns.length; i++) {
      header.set(columns[i].trim().toLowerCase(), i);
    }
    return header;
  }

  private static splitImportLine(line: string): string[] {
    const delimiter: string = line.indexOf('\t') >= 0 ? '\t' : (line.indexOf(';') >= 0 ? ';' : ',');
    const parts: string[] = line.split(delimiter);
    const result: string[] = [];
    for (let i: number = 0; i < parts.length; i++) {
      let part: string = parts[i].trim();
      if (part.length >= 2 && part.charAt(0) === '"' && part.charAt(part.length - 1) === '"') {
        part = part.substring(1, part.length - 1);
      }
      result.push(part);
    }
    return result;
  }

  private static splitLines(text: string): string[] {
    return text.split('\r').join('\n').split('\n');
  }

  private static indexOfUri(line: string): number {
    const lower: string = line.toLowerCase();
    const otp: number = lower.indexOf('otpauth://');
    const migration: number = lower.indexOf('otpauth-migration://');
    if (otp < 0) {
      return migration;
    }
    if (migration < 0) {
      return otp;
    }
    return Math.min(otp, migration);
  }

  private static headerValue(columns: string[], header: Map<string, number>, key: string): string {
    if (!header.has(key)) {
      return '';
    }
    const index: number = header.get(key) as number;
    if (index < 0 || index >= columns.length) {
      return '';
    }
    return columns[index].trim();
  }

  private static parseIntOr(value: string, fallback: number): number {
    if (value.length === 0) {
      return fallback;
    }
    const parsed: number = Number(value);
    if (!Number.isFinite(parsed)) {
      return fallback;
    }
    return parsed;
  }

  private static readKey(source: Object, key: string): Object | undefined {
    const keys: string[] = Object.keys(source);
    const wanted: string = key.toLowerCase();
    for (let i: number = 0; i < keys.length; i++) {
      if (keys[i].toLowerCase() === wanted) {
        const record: Record<string, Object> = source as Record<string, Object>;
        return record[keys[i]];
      }
    }
    return undefined;
  }

  private static readObject(source: Object, key: string): Object | undefined {
    const value: Object | undefined = PortableImportCodec.readKey(source, key);
    if (value !== undefined && typeof value === 'object' && value !== null && !Array.isArray(value)) {
      return value;
    }
    return undefined;
  }

  private static readString(source: Object, keys: string[]): string {
    for (let i: number = 0; i < keys.length; i++) {
      const value: Object | undefined = PortableImportCodec.readKey(source, keys[i]);
      if (typeof value === 'string' && value.trim().length > 0) {
        return value.trim();
      }
    }
    return '';
  }

  private static readNumber(source: Object, keys: string[], fallback: number): number {
    for (let i: number = 0; i < keys.length; i++) {
      const value: Object | undefined = PortableImportCodec.readKey(source, keys[i]);
      if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
      }
      if (typeof value === 'string') {
        const parsed: number = Number(value);
        if (Number.isFinite(parsed)) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  private static firstNonEmpty(values: string[]): string {
    for (let i: number = 0; i < values.length; i++) {
      if (values[i].length > 0) {
        return values[i];
      }
    }
    return '';
  }
}
