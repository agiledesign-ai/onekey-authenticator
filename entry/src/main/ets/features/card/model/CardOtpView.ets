import { AccountItem } from '../../../model/AccountItem';
import { OtpType } from '../../../model/OtpType';
import { OtpEngine } from '../../otp/engine/OtpEngine';
import { CardTokenPolicy } from './CardTokenPolicy';

/** 卡片展示槽位：只含界面所需字段，不含密钥。 */
export interface CardOtpSlot {
  accountId: string;
  name: string;
  remark: string;
  code: string;
  badgeColor: string;
  remaining: number;
  period: number;
  progress: number;
  type: string;
}

/** 把账号转成卡片展示数据，验证码只在内存中计算。 */
export class CardOtpView {
  static fromAccount(account: AccountItem, time?: Date): CardOtpSlot {
    const period: number = account.type === OtpType.HOTP ? 30 : account.period;
    try {
      const result = OtpEngine.generate(account, time);
      const remaining: number = result.remainingSeconds;
      const progress: number = period > 0 ? remaining / period * 100 : 0;
      return {
        accountId: account.id,
        name: account.serviceName,
        remark: account.accountName,
        code: result.code,
        badgeColor: account.badgeColor,
        remaining: remaining,
        period: period,
        progress: progress,
        type: `${account.type}`
      };
    } catch {
      return {
        accountId: account.id,
        name: account.serviceName,
        remark: account.accountName,
        code: account.type === OtpType.STEAM ? '-----' : '------',
        badgeColor: account.badgeColor,
        remaining: period,
        period: period,
        progress: 0,
        type: `${account.type}`
      };
    }
  }

  static fromAccounts(accounts: AccountItem[], time?: Date): CardOtpSlot[] {
    const slots: CardOtpSlot[] = [];
    for (let i: number = 0; i < accounts.length && slots.length < CardTokenPolicy.LIMIT; i++) {
      slots.push(CardOtpView.fromAccount(accounts[i], time));
    }
    return slots;
  }
}

/** 将展示槽位编成服务卡片绑定数据，禁止写入密钥。 */
export class CardFormData {
  static readonly EMPTY_NAME: string = '暂无令牌';

  static build(slots: CardOtpSlot[]): Record<string, string | number> {
    const data: Record<string, string | number> = {};
    data['count'] = Math.min(slots.length, CardTokenPolicy.LIMIT);
    for (let i: number = 0; i < CardTokenPolicy.LIMIT; i++) {
      const prefix: string = `t${i + 1}`;
      if (i < slots.length) {
        const item: CardOtpSlot = slots[i];
        data[`${prefix}Name`] = item.name;
        data[`${prefix}Remark`] = item.remark;
        data[`${prefix}Code`] = item.code;
        data[`${prefix}Color`] = item.badgeColor;
        data[`${prefix}Remaining`] = item.remaining;
        data[`${prefix}Period`] = item.period;
        data[`${prefix}Progress`] = item.progress;
        data[`${prefix}Type`] = item.type;
        data[`${prefix}Id`] = item.accountId;
      } else {
        data[`${prefix}Name`] = i === 0 && slots.length === 0 ? CardFormData.EMPTY_NAME : '';
        data[`${prefix}Remark`] = '';
        data[`${prefix}Code`] = '';
        data[`${prefix}Color`] = '#C4C4C4';
        data[`${prefix}Remaining`] = 0;
        data[`${prefix}Period`] = 30;
        data[`${prefix}Progress`] = 0;
        data[`${prefix}Type`] = '';
        data[`${prefix}Id`] = '';
      }
    }
    return data;
  }
}
