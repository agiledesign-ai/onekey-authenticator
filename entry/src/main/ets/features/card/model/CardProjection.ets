import { AccountItem } from '../../../model/AccountItem';

export interface CardProjection {
  accountId: string;
  serviceName: string;
  maskedAccountName: string;
  badgeColor: string;
  exists: boolean;
}

/** 卡片投影规则：只保留非敏感展示字段。 */
export class CardProjectionPolicy {
  static maskAccountName(name: string): string {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return '•••';
    }
    const at: number = trimmed.indexOf('@');
    if (at > 0) {
      const local: string = trimmed.substring(0, at);
      const domain: string = trimmed.substring(at);
      const keep: string = local.substring(0, Math.min(2, local.length));
      return `${keep}***${domain}`;
    }
    if (trimmed.length <= 2) {
      return `${trimmed.charAt(0)}***`;
    }
    return `${trimmed.substring(0, 2)}***`;
  }

  static fromAccount(account: AccountItem): CardProjection | null {
    if (!account.pinned) {
      return null;
    }
    return {
      accountId: account.id,
      serviceName: account.serviceName,
      maskedAccountName: CardProjectionPolicy.maskAccountName(account.accountName),
      badgeColor: account.badgeColor,
      exists: true
    };
  }

  static fromMissing(accountId: string): CardProjection {
    return {
      accountId: accountId,
      serviceName: '账号已移除',
      maskedAccountName: '•••',
      badgeColor: '#C4C4C4',
      exists: false
    };
  }
}

/** 将投影编成服务卡片绑定数据，字段名避开密钥和验证码。 */
export class CardFormData {
  static readonly EMPTY_PROMPT: string = '打开2FA验证器选择置顶账号';

  static build(
    projections: CardProjection[],
    slotCount: number,
    emptyPrompt: string,
    formId: string
  ): Record<string, string | number> {
    const data: Record<string, string | number> = {};
    data['cardFormId'] = formId;
    data['slotCount'] = slotCount;
    data['empty'] = projections.length === 0 ? 1 : 0;
    data['emptyPrompt'] = emptyPrompt;
    for (let i: number = 0; i < 3; i++) {
      const prefix: string = `s${i + 1}`;
      if (i < projections.length) {
        const item: CardProjection = projections[i];
        data[`${prefix}Name`] = item.serviceName;
        data[`${prefix}Account`] = item.maskedAccountName;
        data[`${prefix}Color`] = item.badgeColor;
        data[`${prefix}Id`] = item.accountId;
        data[`${prefix}Missing`] = item.exists ? 0 : 1;
      } else {
        data[`${prefix}Name`] = '';
        data[`${prefix}Account`] = '';
        data[`${prefix}Color`] = '';
        data[`${prefix}Id`] = '';
        data[`${prefix}Missing`] = 0;
      }
    }
    return data;
  }
}
