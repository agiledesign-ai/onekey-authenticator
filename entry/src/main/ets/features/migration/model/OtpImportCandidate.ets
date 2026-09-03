import { OtpType } from '../../../model/OtpType';

/** 标准 otpauth URI 解析后的导入候选。 */
export interface OtpImportCandidate {
  type: OtpType;
  secret: string;
  serviceName: string;
  accountName: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
  needsCounter: boolean;
  issuerConflict: boolean;
}
