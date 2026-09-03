import { CardTokenPolicy } from './CardTokenPolicy';

export interface CardBinding {
  formId: string;
  dimension: string;
  accountIds: string[];
}

/** 服务卡片尺寸：1×2 / 2×2 / 2×4。 */
export class CardBindingPolicy {
  static normalizeDimension(dimension: string): string {
    return CardTokenPolicy.normalizeDimension(dimension);
  }

  static maxSlots(dimension: string): number {
    return CardTokenPolicy.maxSlots(dimension);
  }

  static sanitizeIds(ids: string[], dimension: string): string[] {
    const max: number = CardBindingPolicy.maxSlots(dimension);
    const result: string[] = [];
    for (let i: number = 0; i < ids.length; i++) {
      const id: string = ids[i].trim();
      if (id.length === 0 || result.indexOf(id) >= 0) {
        continue;
      }
      result.push(id);
      if (result.length >= max) {
        break;
      }
    }
    return result;
  }

  static setSelected(
    id: string,
    checked: boolean,
    selected: string[],
    dimension: string,
    pinnedIds: string[]
  ): string[] {
    const current: string[] = CardBindingPolicy.sanitizeIds(selected, dimension);
    const allowed: string[] = [];
    for (let i: number = 0; i < current.length; i++) {
      if (pinnedIds.indexOf(current[i]) >= 0) {
        allowed.push(current[i]);
      }
    }
    if (pinnedIds.indexOf(id) < 0) {
      return CardBindingPolicy.sanitizeIds(allowed, dimension);
    }
    if (checked) {
      if (CardBindingPolicy.maxSlots(dimension) === 1) {
        return [id];
      }
      if (allowed.indexOf(id) >= 0) {
        return allowed;
      }
      if (allowed.length >= CardBindingPolicy.maxSlots(dimension)) {
        return allowed;
      }
      return CardBindingPolicy.sanitizeIds(allowed.concat([id]), dimension);
    }
    const next: string[] = [];
    for (let i: number = 0; i < allowed.length; i++) {
      if (allowed[i] !== id) {
        next.push(allowed[i]);
      }
    }
    return next;
  }
}
