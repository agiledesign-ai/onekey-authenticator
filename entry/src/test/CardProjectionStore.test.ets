import { describe, expect, it } from '@ohos/hypium';
import { createAccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';
import {
  CardFormData,
  CardProjectionPolicy
} from '../main/ets/features/card/model/CardProjection';
import {
  CardBindingPolicy
} from '../main/ets/features/card/model/CardBinding';
import {
  CardDeepLink,
  CardDeepLinkKind
} from '../main/ets/features/card/model/CardDeepLink';
import {
  CardProjectionStore,
  MemoryStringMapStore
} from '../main/ets/features/card/store/CardProjectionStore';
import { CardBindingStore } from '../main/ets/features/card/store/CardBindingStore';

const TOTP_SECRET: string = 'JBSWY3DPEHPK3PXP';

export default function cardProjectionStoreTest() {
  describe('CardProjection', () => {
    it('masks account names and only projects pinned accounts', 0, () => {
      expect(CardProjectionPolicy.maskAccountName('astra@example.com')).assertEqual('as***@example.com');
      expect(CardProjectionPolicy.maskAccountName('GitHubUser')).assertEqual('Gi***');
      expect(CardProjectionPolicy.maskAccountName('ab')).assertEqual('a***');
      expect(CardProjectionPolicy.maskAccountName('')).assertEqual('•••');

      const pinned = createAccountItem('p1', 'GitHub', 'astra@example.com', TOTP_SECRET, {
        type: OtpType.TOTP
      });
      pinned.pinned = true;
      const plain = createAccountItem('u1', 'VPN', 'office', TOTP_SECRET, {
        type: OtpType.TOTP
      });
      expect(CardProjectionPolicy.fromAccount(plain) === null).assertTrue();
      const projection = CardProjectionPolicy.fromAccount(pinned);
      expect(projection !== null).assertTrue();
      if (projection === null) {
        return;
      }
      expect(projection.accountId).assertEqual('p1');
      expect(projection.serviceName).assertEqual('GitHub');
      expect(projection.maskedAccountName).assertEqual('as***@example.com');
      expect(projection.exists).assertTrue();
      expect(JSON.stringify(projection).indexOf(TOTP_SECRET)).assertEqual(-1);
    });

    it('caps 2x2 to two accounts and 2x4 to four unique ids', 0, () => {
      expect(CardBindingPolicy.maxSlots('2*2')).assertEqual(2);
      expect(CardBindingPolicy.maxSlots('2*4')).assertEqual(4);
      expect(CardBindingPolicy.maxSlots('1*2')).assertEqual(1);
      expect(CardBindingPolicy.normalizeDimension('3')).assertEqual('2*4');
      expect(CardBindingPolicy.normalizeDimension('2')).assertEqual('2*2');
      expect(CardBindingPolicy.normalizeDimension('1')).assertEqual('1*2');
      const ids: string[] = CardBindingPolicy.sanitizeIds(['', 'a', 'a', 'b', 'c', 'd'], '2*4');
      expect(ids.length).assertEqual(4);
      expect(ids[0]).assertEqual('a');
      expect(ids[3]).assertEqual('d');
    });

    it('builds form data without secrets, codes or counters', 0, () => {
      const missing = CardProjectionPolicy.fromMissing('gone');
      expect(missing.exists).assertEqual(false);
      expect(missing.serviceName).assertEqual('账号已移除');
      const data = CardFormData.build([missing], 3, '打开2FA验证器选择置顶账号', 'form-9');
      const encoded: string = JSON.stringify(data);
      expect(encoded.indexOf('secret')).assertEqual(-1);
      expect(encoded.indexOf('code')).assertEqual(-1);
      expect(encoded.indexOf('counter')).assertEqual(-1);
      expect(encoded.indexOf('OtpEngine')).assertEqual(-1);
      expect(data['cardFormId']).assertEqual('form-9');
      expect(data['s1Name']).assertEqual('账号已移除');
      expect(data['emptyPrompt']).assertEqual('打开2FA验证器选择置顶账号');
    });

    it('persists projections and form bindings without credential fields', 0, () => {
      const projectionStore = new CardProjectionStore(new MemoryStringMapStore());
      const bindingStore = new CardBindingStore(new MemoryStringMapStore());
      const pinned = createAccountItem('p1', 'GitHub', 'astra@example.com', TOTP_SECRET, {
        type: OtpType.TOTP
      });
      pinned.pinned = true;
      const unpinned = createAccountItem('u1', 'VPN', 'office', TOTP_SECRET, {
        type: OtpType.TOTP
      });
      projectionStore.rebuild([pinned, unpinned]);
      expect(projectionStore.list().length).assertEqual(1);
      expect(projectionStore.get('p1').exists).assertTrue();
      expect(projectionStore.get('u1').exists).assertEqual(false);
      expect(JSON.stringify(projectionStore.list()).indexOf(TOTP_SECRET)).assertEqual(-1);

      expect(bindingStore.bind('form-1', '2*2', ['p1', 'u1']).length).assertEqual(2);
      expect(bindingStore.idsFor('form-1')[0]).assertEqual('p1');
      expect(bindingStore.idsFor('form-1')[1]).assertEqual('u1');
      bindingStore.unbind('form-1');
      expect(bindingStore.idsFor('form-1').length).assertEqual(0);
    });

    it('parses card deep links into locate or configure actions', 0, () => {
      const locateParams: Record<string, Object> = { 'cardAccountId': 'p1' };
      const locate = CardDeepLink.parse(locateParams);
      expect(locate.kind).assertEqual(CardDeepLinkKind.LOCATE);
      expect(locate.accountId).assertEqual('p1');

      const configureParams: Record<string, Object> = {
        'cardConfigure': '1',
        'formId': 'form-1',
        'dimension': '2*4'
      };
      const configure = CardDeepLink.parse(configureParams);
      expect(configure.kind).assertEqual(CardDeepLinkKind.CONFIGURE);
      expect(configure.formId).assertEqual('form-1');
      expect(configure.dimension).assertEqual('2*4');

      const numericDimensionParams: Record<string, Object> = {
        'cardConfigure': '1',
        'formId': 'form-2',
        'dimension': 3
      };
      const configureByCode = CardDeepLink.parse(numericDimensionParams);
      expect(configureByCode.kind).assertEqual(CardDeepLinkKind.CONFIGURE);
      expect(configureByCode.dimension).assertEqual('2*4');

      const emptyParams: Record<string, Object> = {};
      const none = CardDeepLink.parse(emptyParams);
      expect(none.kind).assertEqual(CardDeepLinkKind.NONE);
    });
  });
}
