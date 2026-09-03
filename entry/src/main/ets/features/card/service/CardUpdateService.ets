import { common } from '@kit.AbilityKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { AccountItem } from '../../../model/AccountItem';
import { Log } from '../../../common/utils/LogUtil';
import { CardFormData, CardOtpView } from '../model/CardOtpView';
import { CardTokenPolicy } from '../model/CardTokenPolicy';
import { CardTokenStore } from '../store/CardTokenStore';
import { PreferencesStringMapStore } from '../store/CardProjectionStore';

/** 主进程和卡片进程共用：用当前账号计算验证码并刷新已添加的卡片。 */
export class CardUpdateService {
  private static context: common.Context | null = null;

  static init(context: common.Context): void {
    CardUpdateService.context = context.getApplicationContext();
  }

  static sync(accounts: AccountItem[]): void {
    if (CardUpdateService.context === null) {
      return;
    }
    const store: CardTokenStore = CardUpdateService.tokens();
    const selected: AccountItem[] = CardTokenPolicy.resolveAccounts(accounts, store.getTokenIds());
    const data = CardFormData.build(CardOtpView.fromAccounts(selected));
    const formIds: string[] = store.allFormIds();
    for (let i: number = 0; i < formIds.length; i++) {
      CardUpdateService.publish(formIds[i], data);
    }
  }

  static registerForm(formId: string): void {
    if (formId.length === 0 || CardUpdateService.context === null) {
      return;
    }
    CardUpdateService.tokens().addFormId(formId);
  }

  static unregisterForm(formId: string): void {
    if (CardUpdateService.context === null) {
      return;
    }
    CardUpdateService.tokens().removeFormId(formId);
  }

  static setTokenIds(ids: string[], accounts: AccountItem[]): string[] {
    if (CardUpdateService.context === null) {
      return CardTokenPolicy.sanitizeIds(ids);
    }
    const saved: string[] = CardUpdateService.tokens().setTokenIds(ids);
    CardUpdateService.sync(accounts);
    return saved;
  }

  static tokenIds(): string[] {
    if (CardUpdateService.context === null) {
      return [];
    }
    return CardUpdateService.tokens().getTokenIds();
  }

  static bindingData(accounts: AccountItem[]): Record<string, string | number> {
    const selectedIds: string[] = CardUpdateService.context === null ?
      [] : CardUpdateService.tokens().getTokenIds();
    const selected: AccountItem[] = CardTokenPolicy.resolveAccounts(accounts, selectedIds);
    return CardFormData.build(CardOtpView.fromAccounts(selected));
  }

  static tokens(): CardTokenStore {
    return new CardTokenStore(
      new PreferencesStringMapStore(CardUpdateService.requireContext(), 'securekey_card_tokens')
    );
  }

  private static publish(formId: string, data: Record<string, string | number>): void {
    try {
      formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    } catch {
      Log.e('CardUpdateService.publish failed');
    }
  }

  private static requireContext(): common.Context {
    return CardUpdateService.context as common.Context;
  }
}
