import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { AccountItem } from '../../model/AccountItem';
import { AccountImportSummary, AccountStore } from '../store/AccountStore';
import { Log } from './LogUtil';
import { SecureBackupCodec } from '../../features/security/backup/SecureBackupCodec';
import {
  PortableImportCodec,
  PortableImportKind,
  PortableImportResult
} from '../../features/migration/codec/PortableImportCodec';

/** 导入结果 */
export interface BackupResult {
  success: boolean;
  message: string;
  count: number;
}

/** 解密后的导入预览；在用户确认前不会写入安全存储。 */
export interface BackupPreviewResult {
  success: boolean;
  message: string;
  accounts: AccountItem[];
  summary: AccountImportSummary;
}

/** 数据导出/导入工具。 */
export class BackupUtil {
  private static readonly MAX_BACKUP_BYTES: number = 10 * 1024 * 1024;

  /** 导出明文 JSON 备份；只写入调用方勾选的账号。 */
  static async exportAccounts(accounts: AccountItem[]): Promise<BackupResult> {
    if (accounts.length === 0) {
      return { success: false, message: '没有账号可导出', count: 0 };
    }

    const payload: string = PortableImportCodec.encodeJson(accounts);
    const timestamp: string = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const fileName: string = `securekey-backup-${timestamp}.json`;

    try {
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [fileName];
      const docPicker = new picker.DocumentViewPicker();
      const uris: string[] = await docPicker.save(options);
      if (uris === null || uris.length === 0) {
        return { success: false, message: '未选择保存位置', count: 0 };
      }
      const file = fileIo.openSync(
        uris[0],
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC
      );
      try {
        fileIo.writeSync(file.fd, payload);
      } finally {
        fileIo.closeSync(file);
      }
      return { success: true, message: `已导出 ${accounts.length} 个账号`, count: accounts.length };
    } catch {
      Log.e('BackupUtil.exportAccounts failed');
      return { success: false, message: '导出失败', count: 0 };
    }
  }

  /** 选择并解密备份，仅生成导入统计，不修改账号数据。 */
  static async previewImport(password: string): Promise<BackupPreviewResult> {
    const emptySummary: AccountImportSummary = { imported: 0, duplicates: 0, invalid: 0 };
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['2FA|.txt,.json,.csv,.tsv,.otpauth,.mafile,.2fas,.skvault'];
      const docPicker = new picker.DocumentViewPicker();
      const uris: string[] = await docPicker.select(options);
      if (uris === null || uris.length === 0) {
        return { success: false, message: '未选择文件', accounts: [], summary: emptySummary };
      }
      const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
      const fileSize: number = fileIo.statSync(file.fd).size;
      if (fileSize <= 0 || fileSize > BackupUtil.MAX_BACKUP_BYTES) {
        fileIo.closeSync(file);
        return {
          success: false,
          message: '备份文件为空或超过 10 MB',
          accounts: [],
          summary: emptySummary
        };
      }
      const arrayBuffer = new ArrayBuffer(fileSize);
      let readLen: number;
      try {
        readLen = fileIo.readSync(file.fd, arrayBuffer);
      } finally {
        fileIo.closeSync(file);
      }

      const decoder = util.TextDecoder.create('utf-8');
      const content: string = decoder.decode(new Uint8Array(arrayBuffer, 0, readLen));
      return BackupUtil.interpretContent(content, password);
    } catch {
      Log.e('BackupUtil.previewImport failed');
      return {
        success: false,
        message: '无法读取所选文件',
        accounts: [],
        summary: emptySummary
      };
    }
  }

  /** 识别加密备份或明文迁入文件，确认前不写入安全存储。 */
  static async interpretContent(content: string, password: string): Promise<BackupPreviewResult> {
    const emptySummary: AccountImportSummary = { imported: 0, duplicates: 0, invalid: 0 };
    const parsed: PortableImportResult = PortableImportCodec.parse(content);
    if (parsed.kind === PortableImportKind.VAULT) {
      if (password.length < 8) {
        return { success: false, message: '加密备份需要至少 8 位密码', accounts: [], summary: emptySummary };
      }
      try {
        const imported: AccountItem[] = await SecureBackupCodec.decrypt(content, password);
        if (imported === null || imported.length === 0) {
          return { success: false, message: '文件中没有有效账号', accounts: [], summary: emptySummary };
        }
        const summary: AccountImportSummary = AccountStore.previewImport(imported);
        return { success: true, message: '备份已解密', accounts: imported, summary: summary };
      } catch {
        return { success: false, message: '密码错误或文件无效', accounts: [], summary: emptySummary };
      }
    }
    if (parsed.kind === PortableImportKind.ENCRYPTED_2FAS) {
      return { success: false, message: '暂不支持加密的 2FAS 备份', accounts: [], summary: emptySummary };
    }
    if (parsed.kind === PortableImportKind.ENCRYPTED_MAFILE) {
      return {
        success: false,
        message: '加密 maFile 需要明文文件，暂不支持 SDA 加密包',
        accounts: [],
        summary: emptySummary
      };
    }
    const accounts: AccountItem[] = PortableImportCodec.toAccounts(parsed.candidates);
    if (accounts.length === 0) {
      return {
        success: false,
        message: parsed.invalid > 0 ? `文件中有 ${parsed.invalid} 条无效账号` : '文件中没有有效账号',
        accounts: [],
        summary: emptySummary
      };
    }
    const summary: AccountImportSummary = AccountStore.previewImport(accounts);
    summary.invalid = summary.invalid + parsed.invalid;
    return { success: true, message: '已识别可导入账号', accounts: accounts, summary: summary };
  }

  /** 用户确认预览结果后，才将有效且不重复的账号写入安全存储。 */
  static applyImport(accounts: AccountItem[]): BackupResult {
    try {
      const summary: AccountImportSummary = AccountStore.importAccounts(accounts);
      const details: string = `已导入 ${summary.imported} 个，跳过重复 ${summary.duplicates} 个` +
        (summary.invalid > 0 ? `，无效 ${summary.invalid} 个` : '');
      return { success: true, message: details, count: summary.imported };
    } catch {
      Log.e('BackupUtil.applyImport failed');
      return { success: false, message: '导入失败，未修改现有账号', count: 0 };
    }
  }
}
