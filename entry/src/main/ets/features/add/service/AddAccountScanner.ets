import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { AccountImportSummary } from '../../../common/store/AccountStore';
import { Permission } from '../../../common/permission/PermissionUtil';
import { GoogleMigrationCodec, GoogleMigrationPage } from '../../migration/codec/GoogleMigrationCodec';
import { OtpUriCodec, OtpUriStatus } from '../../migration/codec/OtpUriCodec';
import { OtpImportCandidate } from '../../migration/model/OtpImportCandidate';
import {
  MigrationSessionStatus,
  MigrationSessionStore
} from '../../migration/service/MigrationSessionStore';
import { AddAccountWriter } from './AddAccountWriter';

export class ScanImportKind {
  static readonly CANCELLED: string = 'cancelled';
  static readonly ERROR: string = 'error';
  static readonly SAVED: string = 'saved';
  static readonly NEEDS_COUNTER: string = 'needs_counter';
  static readonly MIGRATION_PROGRESS: string = 'migration_progress';
  static readonly MIGRATION_DONE: string = 'migration_done';
}

export interface ScanImportOutcome {
  kind: string;
  message: string;
  candidate: OtpImportCandidate | null;
  scanned: number;
  total: number;
}

/** 启动系统扫码并解析标准 OTP URI 或 Google 迁移码。 */
export class AddAccountScanner {
  static async start(context: common.Context): Promise<ScanImportOutcome> {
    const granted: boolean = await Permission.request(context, Permission.CAMERA);
    if (!granted) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '需要相机权限才能扫码');
    }
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: true
    };
    MigrationSessionStore.markScanInProgress();
    try {
      const result: scanBarcode.ScanResult = await scanBarcode.startScanForResult(context, options);
      return AddAccountScanner.handleValue(result.originalValue);
    } catch (_err) {
      return AddAccountScanner.outcome(ScanImportKind.CANCELLED, '');
    } finally {
      MigrationSessionStore.markScanFinished();
    }
  }

  static handleValue(rawValue: string): ScanImportOutcome {
    const value: string = rawValue.trim();
    if (value.toLowerCase().startsWith('otpauth-migration://offline?')) {
      return AddAccountScanner.handleMigration(value);
    }
    const parsed = OtpUriCodec.parse(value);
    if (parsed.status === OtpUriStatus.NEEDS_COUNTER) {
      return {
        kind: ScanImportKind.NEEDS_COUNTER,
        message: '请确认 HOTP 起始计数器',
        candidate: parsed.candidate,
        scanned: 0,
        total: 0
      };
    }
    if (parsed.status !== OtpUriStatus.OK || parsed.candidate === null) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '无法识别二维码内容');
    }
    if (!AddAccountWriter.addCandidate(parsed.candidate)) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '二维码密钥无效或账号已存在');
    }
    return AddAccountScanner.outcome(ScanImportKind.SAVED, '账号添加成功');
  }

  static confirmHotpCandidate(candidate: OtpImportCandidate, counterText: string): ScanImportOutcome {
    const trimmed: string = counterText.trim();
    const counter: number = Number(trimmed);
    if (trimmed.length === 0 || !Number.isInteger(counter) || counter < 0 || counter > Number.MAX_SAFE_INTEGER) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '请输入有效的计数器');
    }
    const confirmed: OtpImportCandidate = {
      type: candidate.type,
      secret: candidate.secret,
      serviceName: candidate.serviceName,
      accountName: candidate.accountName,
      algorithm: candidate.algorithm,
      digits: candidate.digits,
      period: candidate.period,
      counter: counter,
      needsCounter: false,
      issuerConflict: candidate.issuerConflict
    };
    if (!AddAccountWriter.addCandidate(confirmed)) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '二维码密钥无效或账号已存在');
    }
    return AddAccountScanner.outcome(ScanImportKind.SAVED, '账号添加成功');
  }

  private static handleMigration(value: string): ScanImportOutcome {
    const page: GoogleMigrationPage | null = GoogleMigrationCodec.parse(value);
    if (page === null) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '无法识别 Google 迁移二维码');
    }
    const session = MigrationSessionStore.addPage(page, Date.now());
    if (session.status === MigrationSessionStatus.MIXED_BATCH) {
      MigrationSessionStore.clear();
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '检测到新的迁移批次，请重新扫描全部页面');
    }
    if (session.status === MigrationSessionStatus.EXPIRED) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '迁移会话已超时，请重新扫描');
    }
    if (session.status === MigrationSessionStatus.TOO_LARGE) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '单次迁移不能超过 200 个账号');
    }
    if (session.status === MigrationSessionStatus.INVALID) {
      return AddAccountScanner.outcome(ScanImportKind.ERROR, '无法识别 Google 迁移二维码');
    }
    if (session.status === MigrationSessionStatus.PROGRESS) {
      return {
        kind: ScanImportKind.MIGRATION_PROGRESS,
        message: `已扫描 ${session.scanned}/${session.total} 页，请继续扫描`,
        candidate: null,
        scanned: session.scanned,
        total: session.total
      };
    }
    const summary: AccountImportSummary = AddAccountWriter.importGoogleParameters(
      MigrationSessionStore.collectParameters()
    );
    MigrationSessionStore.clear();
    return {
      kind: ScanImportKind.MIGRATION_DONE,
      message: AddAccountScanner.migrationMessage(summary),
      candidate: null,
      scanned: session.scanned,
      total: session.total
    };
  }

  private static migrationMessage(summary: AccountImportSummary): string {
    if (summary.imported === 0) {
      return `没有新增账号（重复 ${summary.duplicates}，无效 ${summary.invalid}）`;
    }
    return `已导入 ${summary.imported} 个账号（重复 ${summary.duplicates}，无效 ${summary.invalid}）`;
  }

  private static outcome(kind: string, message: string): ScanImportOutcome {
    return { kind: kind, message: message, candidate: null, scanned: 0, total: 0 };
  }
}
