import { CardBindingPolicy } from './CardBinding';

export class CardDeepLinkKind {
  static readonly NONE: string = 'none';
  static readonly LOCATE: string = 'locate';
  static readonly CONFIGURE: string = 'configure';
}

export interface CardDeepLinkAction {
  kind: string;
  accountId: string;
  formId: string;
  dimension: string;
}

/** 解析卡片点击或系统配置入口，只接受非敏感 ID。 */
export class CardDeepLink {
  static parse(params: Object): CardDeepLinkAction {
    const empty: CardDeepLinkAction = {
      kind: CardDeepLinkKind.NONE,
      accountId: '',
      formId: '',
      dimension: ''
    };
    if (params === null || typeof params !== 'object') {
      return empty;
    }
    const record: Record<string, Object> = params as Record<string, Object>;
    const accountId: string = CardDeepLink.read(record, ['cardAccountId']);
    if (accountId.length > 0) {
      return {
        kind: CardDeepLinkKind.LOCATE,
        accountId: accountId,
        formId: '',
        dimension: ''
      };
    }
    const configure: string = CardDeepLink.read(record, ['cardConfigure']);
    const formId: string = CardDeepLink.read(record, [
      'formId',
      'ohos.extra.param.key.form_identity'
    ]);
    const dimension: string = CardDeepLink.read(record, [
      'dimension',
      'ohos.extra.param.key.form_dimension'
    ]);
    if (configure === '1' || formId.length > 0) {
      return {
        kind: CardDeepLinkKind.CONFIGURE,
        accountId: '',
        formId: formId,
        dimension: CardBindingPolicy.normalizeDimension(dimension)
      };
    }
    return empty;
  }

  private static read(source: Record<string, Object>, keys: string[]): string {
    for (let i: number = 0; i < keys.length; i++) {
      const value: Object | undefined = source[keys[i]];
      if (typeof value === 'string' && value.trim().length > 0) {
        return value.trim();
      }
      if (typeof value === 'number' && Number.isFinite(value)) {
        return `${value}`;
      }
    }
    return '';
  }
}
