/** 服务卡片预览与空态：对齐参考项目，空槽隐藏，无账号也能添加桌面。 */
export class CardPreviewPolicy {
  static readonly EMPTY_NAME: string = '暂无令牌';
  static readonly PREVIEW_COUNT: number = 3;
  static readonly AUTO_PLAY_INTERVAL_MS: number = 4000;

  static canOpenFormManager(_accountCount: number): boolean {
    return true;
  }

  static slotVisible(name: string, index: number, filledCount: number): boolean {
    if (name.length > 0) {
      return true;
    }
    return filledCount === 0 && index === 0;
  }

  static displayName(name: string, filledCount: number, index: number): string {
    if (name.length > 0) {
      return name;
    }
    return CardPreviewPolicy.slotVisible(name, index, filledCount) ? CardPreviewPolicy.EMPTY_NAME : '';
  }

  static showSmallDivider(filledCount: number): boolean {
    return filledCount >= 2;
  }

  static showMediumVertical(filledCount: number): boolean {
    return filledCount >= 2;
  }

  static showMediumLeftDivider(filledCount: number): boolean {
    return filledCount >= 3;
  }

  static showMediumRightDivider(filledCount: number): boolean {
    return filledCount >= 4;
  }

  static previewWidthVp(index: number): number {
    if (index === 0) {
      return 168;
    }
    if (index === 1) {
      return 176;
    }
    return 0;
  }

  static previewHeightVp(index: number): number {
    return index === 0 ? 88 : 176;
  }

  static previewStageHeightVp(): number {
    let maxHeight: number = 0;
    for (let i: number = 0; i < CardPreviewPolicy.PREVIEW_COUNT; i++) {
      const height: number = CardPreviewPolicy.previewHeightVp(i);
      if (height > maxHeight) {
        maxHeight = height;
      }
    }
    return maxHeight;
  }

  static nextPreviewIndex(current: number): number {
    if (current < 0) {
      return 0;
    }
    return (current + 1) % CardPreviewPolicy.PREVIEW_COUNT;
  }

  static caption(slots: number): string {
    if (slots === 1) {
      return '1×2 · 显示 1 个验证码';
    }
    if (slots === 2) {
      return '2×2 · 显示 2 个验证码';
    }
    return '2×4 · 显示 4 个验证码';
  }

  static selectionHint(selectedCount: number): string {
    if (selectedCount === 0) {
      return '未选择时按首页顺序显示。最多 8 个；当前预览尺寸只显示其中 1、2 或 4 个。';
    }
    return `已选 ${selectedCount} 个，按勾选顺序出现在卡片上。最多 8 个。`;
  }

  static emptyListHint(): string {
    return '暂无令牌，请先添加令牌';
  }

  static emptyTitle(): string {
    return '开始';
  }

  static emptyCompactHint(): string {
    return '添加一个账户';
  }

  static emptySteps(): string[] {
    return ['打开应用', '至少添加一个账户', '点击卡片选择账户'];
  }

  static formManagerHelper(accountCount: number): string {
    if (accountCount === 0) {
      return '可先添加到桌面。有账号后会按首页顺序显示';
    }
    return '系统会打开卡片选择器，可放到桌面或负一屏';
  }
}
