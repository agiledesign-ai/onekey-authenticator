import { OtpType } from './OtpType';

/** 账号 UI 列表项模型；验证码始终根据安全存储中的密钥动态生成。 */
export interface AccountItem {
  id: string;
  type: OtpType;
  serviceName: string;
  accountName: string;
  badgeColor: string;
  /** 规范化后的 Base32 密钥，仅在安全存储边界内持久化。 */
  secretKey: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
  groupId: string;
  pinned: boolean;
  sortIndex: number;
  createdAt: number;
  updatedAt: number;
  schemaVersion: number;
}

export const ACCOUNT_SCHEMA_VERSION: number = 3;

/** 创建账号时显式提交类型及其专属参数，避免位置参数顺序错误。 */
export interface AccountCreationOptions {
  type: OtpType;
  algorithm?: string;
  digits?: number;
  period?: number;
  counter?: number;
  groupId?: string;
}

/** 创建字段完整的新账号，旧版数据迁移由 AccountStore 单独处理。 */
export function createAccountItem(
  id: string,
  serviceName: string,
  accountName: string,
  secretKey: string,
  options: AccountCreationOptions
): AccountItem {
  const now: number = Date.now();
  const defaultDigits: number = options.type === OtpType.STEAM ? 5 : 6;
  return {
    id: id,
    type: options.type,
    serviceName: serviceName,
    accountName: accountName,
    badgeColor: getBadgeColor(serviceName),
    secretKey: secretKey,
    algorithm: options.algorithm !== undefined ? options.algorithm : 'SHA1',
    digits: options.digits !== undefined ? options.digits : defaultDigits,
    period: options.period !== undefined ? options.period : 30,
    counter: options.counter !== undefined ? options.counter : 0,
    groupId: options.groupId !== undefined ? options.groupId : '',
    pinned: false,
    sortIndex: now,
    createdAt: now,
    updatedAt: now,
    schemaVersion: ACCOUNT_SCHEMA_VERSION
  };
}

/** 根据服务名哈希派生稳定的徽章色。 */
export function getBadgeColor(name: string): string {
  const colors: string[] = ['#4285F4', '#EA4335', '#34A853', '#FF6D00', '#7B1FA2', '#0288D1', '#00838F', '#558B2F'];
  let hash: number = 0;
  for (let i: number = 0; i < name.length; i++) {
    hash = hash + name.charCodeAt(i);
  }
  return colors[hash % colors.length];
}
