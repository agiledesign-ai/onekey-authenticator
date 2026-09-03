import { OtpType } from '../../../model/OtpType';
import { SecretCodec } from '../../otp/codec/SecretCodec';
import { ProtoReader, ProtoWriter } from './ProtobufWireCodec';

export interface GoogleMigrationParameter {
  secret: string;
  name: string;
  issuer: string;
  algorithm: string;
  digits: number;
  type: OtpType;
  counter: number;
}

export interface GoogleMigrationPage {
  version: number;
  batchSize: number;
  batchIndex: number;
  batchId: number;
  parameters: GoogleMigrationParameter[];
}

const MIGRATION_PREFIX: string = 'otpauth-migration://offline?';
const BASE64_ALPHABET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

/** 只编解码 Google Authenticator 迁移载荷，不写入账号存储。 */
export class GoogleMigrationCodec {
  static parse(uri: string): GoogleMigrationPage | null {
    const trimmed: string = uri.trim();
    if (!trimmed.toLowerCase().startsWith(MIGRATION_PREFIX)) {
      return null;
    }
    const data: string = GoogleMigrationCodec.queryValue(trimmed.substring(MIGRATION_PREFIX.length), 'data');
    if (data.length === 0) {
      return null;
    }
    const payload: Uint8Array = GoogleMigrationCodec.decodeBase64(data);
    if (payload.length === 0) {
      return null;
    }
    return GoogleMigrationCodec.parsePayload(payload);
  }

  static encodeUri(page: GoogleMigrationPage): string {
    const encoded: string = GoogleMigrationCodec.encodeBase64(GoogleMigrationCodec.encodePayload(page));
    return `${MIGRATION_PREFIX}data=${encodeURIComponent(encoded)}`;
  }

  private static parsePayload(payload: Uint8Array): GoogleMigrationPage {
    const parameters: GoogleMigrationParameter[] = [];
    let version: number = 1;
    let batchSize: number = 1;
    let batchIndex: number = 0;
    let batchId: number = 0;
    const reader: ProtoReader = new ProtoReader(payload);
    while (reader.hasRemaining()) {
      const tag: number = reader.readTag();
      const field: number = Math.floor(tag / 8);
      const wireType: number = tag & 7;
      if (field === 1 && wireType === 2) {
        const parsed = GoogleMigrationCodec.parseParameter(reader.readBytes());
        if (parsed !== null) {
          parameters.push(parsed);
        }
      } else if (field === 2 && wireType === 0) {
        version = reader.readVarint();
      } else if (field === 3 && wireType === 0) {
        batchSize = reader.readVarint();
      } else if (field === 4 && wireType === 0) {
        batchIndex = reader.readVarint();
      } else if (field === 5 && wireType === 0) {
        batchId = reader.readVarint();
      } else {
        reader.skip(wireType);
      }
    }
    return {
      version: version,
      batchSize: batchSize > 0 ? batchSize : 1,
      batchIndex: batchIndex,
      batchId: batchId,
      parameters: parameters
    };
  }

  private static parseParameter(payload: Uint8Array): GoogleMigrationParameter | null {
    let secret: string = '';
    let name: string = '';
    let issuer: string = '';
    let algorithm: string = 'SHA1';
    let digits: number = 6;
    let type: OtpType = OtpType.TOTP;
    let counter: number = 0;
    let invalid: boolean = false;
    const reader: ProtoReader = new ProtoReader(payload);
    while (reader.hasRemaining()) {
      const tag: number = reader.readTag();
      const field: number = Math.floor(tag / 8);
      const wireType: number = tag & 7;
      if (field === 1 && wireType === 2) {
        secret = SecretCodec.encodeBase32(reader.readBytes());
      } else if (field === 2 && wireType === 2) {
        name = GoogleMigrationCodec.decodeUtf8(reader.readBytes());
      } else if (field === 3 && wireType === 2) {
        issuer = GoogleMigrationCodec.decodeUtf8(reader.readBytes());
      } else if (field === 4 && wireType === 0) {
        algorithm = GoogleMigrationCodec.algorithmName(reader.readVarint());
      } else if (field === 5 && wireType === 0) {
        digits = GoogleMigrationCodec.digitCount(reader.readVarint());
      } else if (field === 6 && wireType === 0) {
        const rawType: number = reader.readVarint();
        if (rawType === 1) {
          type = OtpType.HOTP;
        } else if (rawType === 2) {
          type = OtpType.TOTP;
        } else {
          invalid = true;
        }
      } else if (field === 7 && wireType === 0) {
        counter = reader.readVarint();
      } else {
        reader.skip(wireType);
      }
    }
    if (invalid || secret.length === 0 || algorithm.length === 0 || digits <= 0 ||
      counter > Number.MAX_SAFE_INTEGER) {
      return null;
    }
    return {
      secret: secret,
      name: name,
      issuer: issuer,
      algorithm: algorithm,
      digits: digits,
      type: type,
      counter: type === OtpType.HOTP ? counter : 0
    };
  }

  private static encodePayload(page: GoogleMigrationPage): Uint8Array {
    const writer: ProtoWriter = new ProtoWriter();
    for (let i: number = 0; i < page.parameters.length; i++) {
      writer.writeBytesField(1, GoogleMigrationCodec.encodeParameter(page.parameters[i]));
    }
    writer.writeVarintField(2, page.version);
    writer.writeVarintField(3, page.batchSize);
    writer.writeVarintField(4, page.batchIndex);
    writer.writeVarintField(5, page.batchId);
    return writer.toBytes();
  }

  private static encodeParameter(parameter: GoogleMigrationParameter): Uint8Array {
    const writer: ProtoWriter = new ProtoWriter();
    writer.writeBytesField(1, SecretCodec.decodeBase32(parameter.secret));
    writer.writeBytesField(2, GoogleMigrationCodec.encodeUtf8(parameter.name));
    writer.writeBytesField(3, GoogleMigrationCodec.encodeUtf8(parameter.issuer));
    writer.writeVarintField(4, GoogleMigrationCodec.algorithmValue(parameter.algorithm));
    writer.writeVarintField(5, parameter.digits === 8 ? 2 : 1);
    writer.writeVarintField(6, parameter.type === OtpType.HOTP ? 1 : 2);
    if (parameter.type === OtpType.HOTP) {
      writer.writeVarintField(7, parameter.counter);
    }
    return writer.toBytes();
  }

  private static algorithmName(value: number): string {
    if (value === 0) {
      return '';
    }
    if (value === 2) {
      return 'SHA256';
    }
    if (value === 3) {
      return 'SHA512';
    }
    if (value === 4) {
      return '';
    }
    return 'SHA1';
  }

  private static algorithmValue(name: string): number {
    if (name === 'SHA256') {
      return 2;
    }
    if (name === 'SHA512') {
      return 3;
    }
    if (name === 'MD5') {
      return 4;
    }
    return 1;
  }

  private static digitCount(value: number): number {
    if (value === 0) {
      return -1;
    }
    return value === 2 ? 8 : 6;
  }

  private static queryValue(query: string, key: string): string {
    const pairs: string[] = query.split('&');
    for (let i: number = 0; i < pairs.length; i++) {
      const pair: string = pairs[i];
      const eqIndex: number = pair.indexOf('=');
      const rawKey: string = eqIndex >= 0 ? pair.substring(0, eqIndex) : pair;
      if (GoogleMigrationCodec.decodeComponent(rawKey) === key) {
        return GoogleMigrationCodec.decodeComponent(eqIndex >= 0 ? pair.substring(eqIndex + 1) : '');
      }
    }
    return '';
  }

  private static decodeComponent(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch {
      return value;
    }
  }

  private static decodeBase64(data: string): Uint8Array {
    let normalized: string = data.replace(/ /g, '+').replace(/-/g, '+').replace(/_/g, '/');
    while (normalized.length % 4 !== 0) {
      normalized += '=';
    }
    return SecretCodec.decodeBase64(normalized);
  }

  private static encodeBase64(bytes: Uint8Array): string {
    let result: string = '';
    for (let i: number = 0; i < bytes.length; i += 3) {
      const a: number = bytes[i];
      const b: number = i + 1 < bytes.length ? bytes[i + 1] : 0;
      const c: number = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result += BASE64_ALPHABET.charAt((a >> 2) & 63);
      result += BASE64_ALPHABET.charAt(((a & 3) << 4) | ((b >> 4) & 15));
      if (i + 1 < bytes.length) {
        result += BASE64_ALPHABET.charAt(((b & 15) << 2) | ((c >> 6) & 3));
      } else {
        result += '=';
      }
      if (i + 2 < bytes.length) {
        result += BASE64_ALPHABET.charAt(c & 63);
      } else {
        result += '=';
      }
    }
    return result;
  }

  private static encodeUtf8(text: string): Uint8Array {
    const bytes: number[] = [];
    for (let i: number = 0; i < text.length; i++) {
      const code: number = text.charCodeAt(i);
      if (code < 128) {
        bytes.push(code);
      } else if (code < 2048) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 63));
      } else {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 63));
        bytes.push(0x80 | (code & 63));
      }
    }
    return new Uint8Array(bytes);
  }

  private static decodeUtf8(bytes: Uint8Array): string {
    let result: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const b: number = bytes[i];
      if (b < 128) {
        result += String.fromCharCode(b);
        i++;
      } else if (b >= 224 && i + 2 < bytes.length) {
        const code: number = ((b & 15) << 12) | ((bytes[i + 1] & 63) << 6) | (bytes[i + 2] & 63);
        result += String.fromCharCode(code);
        i += 3;
      } else if (b >= 192 && i + 1 < bytes.length) {
        const code: number = ((b & 31) << 6) | (bytes[i + 1] & 63);
        result += String.fromCharCode(code);
        i += 2;
      } else {
        i++;
      }
    }
    return result;
  }
}
