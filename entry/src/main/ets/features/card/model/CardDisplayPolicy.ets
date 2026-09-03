import { CardTokenPolicy } from './CardTokenPolicy';
import { CardFormData } from './CardOtpView';

/** 服务卡片展示：验证码分组、两行身份、按尺寸选不挤的布局。 */
export class CardDisplayPolicy {
  static readonly DEFAULT_BADGE_COLOR: string = '#C4C4C4';

  static badgeIndex(name: string): number {
    if (name.length === 0 || name === CardFormData.EMPTY_NAME) {
      return 4;
    }
    let hash: number = 0;
    for (let i: number = 0; i < name.length; i++) {
      hash = hash + name.charCodeAt(i);
    }
    return hash % 8;
  }

  static formatCode(code: string): string {
    const compact: string = code.split(' ').join('');
    if (compact.length === 0) {
      return '';
    }
    if (compact.length === 5) {
      return compact;
    }
    if (compact.length === 6) {
      return `${compact.substring(0, 3)} ${compact.substring(3)}`;
    }
    if (compact.length === 8) {
      return `${compact.substring(0, 4)} ${compact.substring(4)}`;
    }
    return compact;
  }

  static issuerLine(name: string, remark: string = ''): string {
    if (name.length > 0) {
      return name;
    }
    const account: string = remark.trim();
    if (account.length > 0) {
      return account;
    }
    return CardFormData.EMPTY_NAME;
  }

  static accountLine(name: string, remark: string): string {
    const account: string = remark.trim();
    if (account.length === 0 || account === name.trim()) {
      return '';
    }
    return account;
  }

  static occupiedCount(names: string[]): number {
    let count: number = 0;
    for (let i: number = 0; i < names.length; i++) {
      const name: string = names[i];
      if (name.length > 0 && name !== CardFormData.EMPTY_NAME) {
        count++;
      }
    }
    return count;
  }

  static isEmpty(names: string[]): boolean {
    return CardDisplayPolicy.occupiedCount(names) === 0;
  }

  static showAppTitle(): boolean {
    return false;
  }

  static layoutMode(dimension: string, filledCount: number): string {
    const normalized: string = CardTokenPolicy.normalizeDimension(dimension);
    if (normalized === '1*2') {
      return 'compact';
    }
    if (normalized === '2*2') {
      return filledCount <= 1 ? 'hero' : 'stack';
    }
    if (filledCount <= 1) {
      return 'hero';
    }
    if (filledCount === 2) {
      return 'row';
    }
    return 'grid';
  }
}
