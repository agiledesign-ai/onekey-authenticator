import { CardTokenPolicy } from '../model/CardTokenPolicy';
import { StringMapStore } from './CardProjectionStore';

/** 保存卡片所选令牌 ID 和已添加的 formId，不保存密钥。 */
export class CardTokenStore {
  private static readonly TOKEN_IDS_KEY: string = 'cardTokenIds';
  private static readonly FORM_IDS_KEY: string = 'formIds';
  private store: StringMapStore;

  constructor(store: StringMapStore) {
    this.store = store;
  }

  getTokenIds(): string[] {
    return CardTokenPolicy.sanitizeIds(CardTokenStore.readIds(this.store.get(CardTokenStore.TOKEN_IDS_KEY)));
  }

  setTokenIds(ids: string[]): string[] {
    const sanitized: string[] = CardTokenPolicy.sanitizeIds(ids);
    this.store.set(CardTokenStore.TOKEN_IDS_KEY, JSON.stringify(sanitized));
    return sanitized;
  }

  addFormId(formId: string): void {
    const id: string = formId.trim();
    if (id.length === 0) {
      return;
    }
    const ids: string[] = this.allFormIds();
    if (ids.indexOf(id) >= 0) {
      return;
    }
    ids.push(id);
    this.store.set(CardTokenStore.FORM_IDS_KEY, JSON.stringify(ids));
  }

  removeFormId(formId: string): void {
    const id: string = formId.trim();
    if (id.length === 0) {
      return;
    }
    const ids: string[] = this.allFormIds();
    const next: string[] = [];
    for (let i: number = 0; i < ids.length; i++) {
      if (ids[i] !== id) {
        next.push(ids[i]);
      }
    }
    this.store.set(CardTokenStore.FORM_IDS_KEY, JSON.stringify(next));
  }

  allFormIds(): string[] {
    return CardTokenStore.readIds(this.store.get(CardTokenStore.FORM_IDS_KEY));
  }

  private static readIds(raw: string): string[] {
    if (raw.length === 0) {
      return [];
    }
    try {
      const parsed: Object = JSON.parse(raw) as Object;
      if (!Array.isArray(parsed)) {
        return [];
      }
      const items: Object[] = parsed as Object[];
      const ids: string[] = [];
      for (let i: number = 0; i < items.length; i++) {
        if (typeof items[i] === 'string' && (items[i] as string).length > 0) {
          ids.push(items[i] as string);
        }
      }
      return ids;
    } catch {
      return [];
    }
  }
}
