import { AccountItem } from '../../../model/AccountItem';
import { GroupItem } from '../../../model/GroupItem';
import { OtpType } from '../../../model/OtpType';

/** 与云侧 accounts 表一一对应的镜像行。 */
export interface CloudAccountRow {
  id: string;
  type: string;
  serviceName: string;
  accountName: string;
  secretKey: string;
  algorithm: string;
  digits: number;
  period: number;
  counter: number;
  groupId: string;
  pinned: number;
  sortIndex: number;
  createdAt: number;
  updatedAt: number;
  schemaVersion: number;
  badgeColor: string;
}

/** 与云侧 groups 表一一对应的镜像行。 */
export interface CloudGroupRow {
  id: string;
  name: string;
  sortIndex: number;
  createdAt: number;
  updatedAt: number;
}

/** 本机模型与云镜像行的双向映射。 */
export class CloudRecordCodec {
  static accountToRow(account: AccountItem): CloudAccountRow {
    return {
      id: account.id,
      type: account.type,
      serviceName: account.serviceName,
      accountName: account.accountName,
      secretKey: account.secretKey,
      algorithm: account.algorithm,
      digits: account.digits,
      period: account.period,
      counter: account.counter,
      groupId: account.groupId,
      pinned: account.pinned ? 1 : 0,
      sortIndex: account.sortIndex,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      schemaVersion: account.schemaVersion,
      badgeColor: account.badgeColor
    };
  }

  static rowToAccount(row: CloudAccountRow): AccountItem {
    return {
      id: row.id,
      type: CloudRecordCodec.toOtpType(row.type),
      serviceName: row.serviceName,
      accountName: row.accountName,
      badgeColor: row.badgeColor,
      secretKey: row.secretKey,
      algorithm: row.algorithm,
      digits: row.digits,
      period: row.period,
      counter: row.counter,
      groupId: row.groupId,
      pinned: row.pinned === 1,
      sortIndex: row.sortIndex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      schemaVersion: row.schemaVersion
    };
  }

  static groupToRow(group: GroupItem): CloudGroupRow {
    return {
      id: group.id,
      name: group.name,
      sortIndex: group.sortIndex,
      createdAt: group.createdAt,
      updatedAt: group.updatedAt
    };
  }

  static rowToGroup(row: CloudGroupRow): GroupItem {
    return {
      id: row.id,
      name: row.name,
      sortIndex: row.sortIndex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    };
  }

  private static toOtpType(type: string): OtpType {
    if (type === OtpType.HOTP) {
      return OtpType.HOTP;
    }
    if (type === OtpType.STEAM) {
      return OtpType.STEAM;
    }
    return OtpType.TOTP;
  }
}
