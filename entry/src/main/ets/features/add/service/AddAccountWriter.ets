import { AccountImportSummary, AccountStore } from '../../../common/store/AccountStore';
import { AccountItem, createAccountItem } from '../../../model/AccountItem';
import { OtpType } from '../../../model/OtpType';
import { GoogleMigrationParameter } from '../../migration/codec/GoogleMigrationCodec';
import { OtpImportCandidate } from '../../migration/model/OtpImportCandidate';

/** 将扫码或手动输入的账号写入本地存储。 */
export class AddAccountWriter {
  static addCandidate(candidate: OtpImportCandidate): boolean {
    if (candidate.needsCounter) {
      return false;
    }
    const item: AccountItem = createAccountItem(
      Date.now().toString(),
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
    );
    return AccountStore.add(item);
  }

  static addParsed(parsed: OtpImportCandidate): boolean {
    return AddAccountWriter.addCandidate(parsed);
  }

  static addManual(
    service: string,
    account: string,
    secret: string,
    algorithm: string,
    digits: number,
    period: number
  ): boolean {
    const name: string = service.trim();
    const item: AccountItem = createAccountItem(
      Date.now().toString(),
      name,
      account.trim().length > 0 ? account.trim() : `${name} 账号`,
      secret.trim().toUpperCase(),
      { type: OtpType.TOTP, algorithm: algorithm, digits: digits, period: period }
    );
    return AccountStore.add(item);
  }

  static importGoogleParameters(parameters: GoogleMigrationParameter[]): AccountImportSummary {
    const accounts: AccountItem[] = [];
    for (let i: number = 0; i < parameters.length; i++) {
      const converted: AccountItem | null = AddAccountWriter.fromGoogleParameter(parameters[i], i);
      if (converted !== null) {
        accounts.push(converted);
      }
    }
    const summary: AccountImportSummary = AccountStore.importAccounts(accounts);
    summary.invalid += parameters.length - accounts.length;
    return summary;
  }

  private static fromGoogleParameter(parameter: GoogleMigrationParameter, index: number): AccountItem | null {
    let issuer: string = parameter.issuer.trim();
    let account: string = parameter.name.trim();
    const colonIndex: number = account.indexOf(':');
    if (issuer.length === 0 && colonIndex >= 0) {
      issuer = account.substring(0, colonIndex).trim();
      account = account.substring(colonIndex + 1).trim();
    }
    if (issuer.length === 0) {
      issuer = '未知服务';
    }
    return createAccountItem(
      `google-${Date.now()}-${index}`,
      issuer,
      account,
      parameter.secret,
      {
        type: parameter.type,
        algorithm: parameter.algorithm,
        digits: parameter.digits,
        period: 30,
        counter: parameter.type === OtpType.HOTP ? parameter.counter : 0
      }
    );
  }
}
