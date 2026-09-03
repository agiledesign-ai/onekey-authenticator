import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

test('otp_core exports the phone OTP storage and security surface', () => {
  const index = readFileSync(join(root, 'otp_core/Index.ets'), 'utf8');

  for (const symbol of [
    'OtpType',
    'AccountItem',
    'OtpEngine',
    'SecretCodec',
    'AssetAccountStorage',
    'AssetStorePolicy',
    'AccountSecurityPolicy',
    'ClipboardGuard'
  ]) {
    assert.match(index, new RegExp(`\\b${symbol}\\b`));
  }
});

test('otp_core does not export wearable-only types', () => {
  const index = readFileSync(join(root, 'otp_core/Index.ets'), 'utf8');

  assert.equal(/\bWear[A-Z]/.test(index), false);
});
