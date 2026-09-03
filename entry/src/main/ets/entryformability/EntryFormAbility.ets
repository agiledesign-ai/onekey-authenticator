import { Want } from '@kit.AbilityKit';
import { FormExtensionAbility, formBindingData, formInfo } from '@kit.FormKit';
import { AssetAccountStorage } from '../common/store/AssetAccountStorage';
import { AccountItem } from '../model/AccountItem';
import { CardFormData } from '../features/card/model/CardOtpView';
import { CardUpdateService } from '../features/card/service/CardUpdateService';
import { Log } from '../common/utils/LogUtil';

/** 服务卡片扩展：从 Asset Store 读取账号，只把当前验证码推给卡片。 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    this.prepare();
    const formId: string = EntryFormAbility.readParam(want, formInfo.FormParam.IDENTITY_KEY);
    CardUpdateService.registerForm(formId);
    return formBindingData.createFormBindingData(this.currentData());
  }

  onUpdateForm(formId: string): void {
    this.prepare();
    CardUpdateService.registerForm(formId);
    CardUpdateService.sync(this.loadAccounts());
  }

  onFormEvent(formId: string, _message: string): void {
    this.prepare();
    CardUpdateService.registerForm(formId);
    CardUpdateService.sync(this.loadAccounts());
  }

  onRemoveForm(formId: string): void {
    this.prepare();
    CardUpdateService.unregisterForm(formId);
  }

  private prepare(): void {
    CardUpdateService.init(this.context);
  }

  private currentData(): Record<string, string | number> {
    try {
      return CardUpdateService.bindingData(this.loadAccounts());
    } catch {
      Log.e('EntryFormAbility.currentData failed');
      return CardFormData.build([]);
    }
  }

  private loadAccounts(): AccountItem[] {
    try {
      return new AssetAccountStorage().loadAll();
    } catch {
      Log.e('EntryFormAbility.loadAccounts failed');
      return [];
    }
  }

  private static readParam(want: Want, key: string): string {
    if (want.parameters === undefined) {
      return '';
    }
    const value: Object | undefined = want.parameters[key];
    if (typeof value === 'string') {
      return value;
    }
    if (typeof value === 'number') {
      return `${value}`;
    }
    return '';
  }
}
