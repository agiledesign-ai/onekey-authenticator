import { CardBinding, CardBindingPolicy } from '../model/CardBinding';
import { StringMapStore } from './CardProjectionStore';

/** 按 form ID 保存卡片所选账号 ID。 */
export class CardBindingStore {
  private static readonly IDS_KEY: string = 'formIds';
  private store: StringMapStore;

  constructor(store: StringMapStore) {
    this.store = store;
  }

  bind(formId: string, dimension: string, accountIds: string[]): string[] {
    const id: string = formId.trim();
    if (id.length === 0) {
      return [];
    }
    const normalizedDimension: string = CardBindingPolicy.normalizeDimension(dimension);
    const sanitized: string[] = CardBindingPolicy.sanitizeIds(accountIds, normalizedDimension);
    const binding: CardBinding = {
      formId: id,
      dimension: normalizedDimension,
      accountIds: sanitized
    };
    this.store.set(CardBindingStore.itemKey(id), JSON.stringify(binding));
    const ids: string[] = this.allFormIds();
    if (ids.indexOf(id) < 0) {
      ids.push(id);
      this.store.set(CardBindingStore.IDS_KEY, JSON.stringify(ids));
    }
    return sanitized;
  }

  unbind(formId: string): void {
    const id: string = formId.trim();
    if (id.length === 0) {
      return;
    }
    this.store.set(CardBindingStore.itemKey(id), '');
    const ids: string[] = this.allFormIds();
    const next: string[] = [];
    for (let i: number = 0; i < ids.length; i++) {
      if (ids[i] !== id) {
        next.push(ids[i]);
      }
    }
    this.store.set(CardBindingStore.IDS_KEY, JSON.stringify(next));
  }

  idsFor(formId: string): string[] {
    return this.getBinding(formId).accountIds;
  }

  getBinding(formId: string): CardBinding {
    const empty: CardBinding = { formId: formId, dimension: '2*2', accountIds: [] };
    const raw: string = this.store.get(CardBindingStore.itemKey(formId));
    if (raw.length === 0) {
      return empty;
    }
    try {
      const parsed = JSON.parse(raw) as CardBinding;
      const dimension: string = CardBindingPolicy.normalizeDimension(
        parsed.dimension !== undefined ? `${parsed.dimension}` : ''
      );
      return {
        formId: formId,
        dimension: dimension,
        accountIds: CardBindingPolicy.sanitizeIds(
          Array.isArray(parsed.accountIds) ? parsed.accountIds : [],
          dimension
        )
      };
    } catch {
      return empty;
    }
  }

  allFormIds(): string[] {
    const raw: string = this.store.get(CardBindingStore.IDS_KEY);
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

  private static itemKey(formId: string): string {
    return `binding:${formId}`;
  }
}
