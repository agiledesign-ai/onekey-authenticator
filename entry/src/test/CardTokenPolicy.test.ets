import { describe, expect, it } from '@ohos/hypium';
import { AccountItem, createAccountItem } from '../main/ets/model/AccountItem';
import { OtpType } from '../main/ets/model/OtpType';
import { CardTokenPolicy } from '../main/ets/features/card/model/CardTokenPolicy';
import { CardFormData, CardOtpView } from '../main/ets/features/card/model/CardOtpView';
import { CardTokenStore } from '../main/ets/features/card/store/CardTokenStore';
import { MemoryStringMapStore } from '../main/ets/features/card/store/CardProjectionStore';

const RFC_SECRET: string = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

function account(id: string, service: string, name: string): AccountItem {
  return createAccountItem(id, service, name, RFC_SECRET, {
    type: OtpType.TOTP,
    digits: 8
  });
}

export default function cardTokenPolicyTest() {
  describe('CardTokenPolicy', () => {
    it('maps widget dimensions to 1, 2 or 4 slots and keeps a global limit of 8', 0, () => {
      expect(CardTokenPolicy.LIMIT).assertEqual(8);
      expect(CardTokenPolicy.maxSlots('1*2')).assertEqual(1);
      expect(CardTokenPolicy.maxSlots('1')).assertEqual(1);
      expect(CardTokenPolicy.maxSlots('2*2')).assertEqual(2);
      expect(CardTokenPolicy.maxSlots('2')).assertEqual(2);
      expect(CardTokenPolicy.maxSlots('2*4')).assertEqual(4);
      expect(CardTokenPolicy.maxSlots('3')).assertEqual(4);
      expect(CardTokenPolicy.normalizeDimension('1')).assertEqual('1*2');
      expect(CardTokenPolicy.normalizeDimension('3')).assertEqual('2*4');
      expect(CardTokenPolicy.normalizeDimension('2')).assertEqual('2*2');
    });

    it('sanitizes token ids in selection order and ignores blanks or duplicates', 0, () => {
      const ids: string[] = CardTokenPolicy.sanitizeIds(['', 'a', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i']);
      expect(ids.length).assertEqual(8);
      expect(ids[0]).assertEqual('a');
      expect(ids[7]).assertEqual('h');
    });

    it('toggles selection in check order and refuses a ninth token', 0, () => {
      const allowed: string[] = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'];
      let selected: string[] = [];
      selected = CardTokenPolicy.toggle('b', selected, allowed);
      selected = CardTokenPolicy.toggle('a', selected, allowed);
      expect(selected[0]).assertEqual('b');
      expect(selected[1]).assertEqual('a');
      selected = CardTokenPolicy.toggle('b', selected, allowed);
      expect(selected.length).assertEqual(1);
      expect(selected[0]).assertEqual('a');

      selected = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
      selected = CardTokenPolicy.toggle('i', selected, allowed);
      expect(selected.length).assertEqual(8);
      expect(selected.indexOf('i')).assertEqual(-1);
    });

    it('resolves selected accounts and falls back to the first eight when none are chosen', 0, () => {
      const accounts = [
        account('a', 'GitHub', 'astra'),
        account('b', 'Google', 'mail'),
        account('c', 'Steam', 'guard')
      ];
      const selected = CardTokenPolicy.resolveAccounts(accounts, ['c', 'missing', 'a']);
      expect(selected.length).assertEqual(2);
      expect(selected[0].id).assertEqual('c');
      expect(selected[1].id).assertEqual('a');

      const fallback = CardTokenPolicy.resolveAccounts(accounts, []);
      expect(fallback.length).assertEqual(3);
      expect(fallback[0].id).assertEqual('a');

      const stale = CardTokenPolicy.resolveAccounts(accounts, ['gone', 'missing']);
      expect(stale.length).assertEqual(0);
    });
  });

  describe('CardOtpView', () => {
    it('builds form slots with live codes and never copies the secret', 0, () => {
      const totp = account('p1', 'GitHub', 'astra@example.com');
      const slot = CardOtpView.fromAccount(totp, new Date(59_000));
      expect(slot.name).assertEqual('GitHub');
      expect(slot.remark).assertEqual('astra@example.com');
      expect(slot.code).assertEqual('94287082');
      expect(slot.remaining).assertEqual(1);
      expect(slot.period).assertEqual(30);
      expect(slot.accountId).assertEqual('p1');
      expect(slot.badgeColor).assertEqual('#FF6D00');
      expect(JSON.stringify(slot).indexOf(RFC_SECRET)).assertEqual(-1);
      expect(JSON.stringify(slot).indexOf('secretKey')).assertEqual(-1);
    });

    it('encodes eight widget fields without persisting secrets', 0, () => {
      const totp = account('p1', 'GitHub', 'astra@example.com');
      const data = CardFormData.build([CardOtpView.fromAccount(totp, new Date(59_000))]);
      const encoded: string = JSON.stringify(data);
      expect(encoded.indexOf(RFC_SECRET)).assertEqual(-1);
      expect(encoded.indexOf('secretKey')).assertEqual(-1);
      expect(data['count']).assertEqual(1);
      expect(data['t1Name']).assertEqual('GitHub');
      expect(data['t1Remark']).assertEqual('astra@example.com');
      expect(data['t1Code']).assertEqual('94287082');
      expect(data['t1Id']).assertEqual('p1');
      expect(data['t1Color']).assertEqual('#FF6D00');
      expect(data['t2Name']).assertEqual('');
    });

    it('uses an empty-state label when no tokens are selected', 0, () => {
      const data = CardFormData.build([]);
      expect(data['count']).assertEqual(0);
      expect(data['t1Name']).assertEqual('暂无令牌');
      expect(data['t1Code']).assertEqual('');
    });
  });

  describe('CardTokenStore', () => {
    it('persists selected token ids and form ids without credentials', 0, () => {
      const store = new CardTokenStore(new MemoryStringMapStore());
      const saved: string[] = store.setTokenIds(['', 'p1', 'p1', 'p2']);
      expect(saved.length).assertEqual(2);
      expect(store.getTokenIds()[0]).assertEqual('p1');
      store.addFormId('form-1');
      store.addFormId('form-1');
      store.addFormId('form-2');
      expect(store.allFormIds().length).assertEqual(2);
      store.removeFormId('form-1');
      expect(store.allFormIds()[0]).assertEqual('form-2');
      expect(JSON.stringify(store.getTokenIds()).indexOf(RFC_SECRET)).assertEqual(-1);
    });
  });
}
