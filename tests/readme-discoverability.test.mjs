import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function read(relativePath) {
  return readFileSync(join(root, relativePath), 'utf8');
}

test('中文 README 使用鸿蒙双重验证和动态口令关键词', () => {
  const readme = read('README.md');

  assert.match(readme, /^# 2FA验证器-工具｜HarmonyOS 鸿蒙原生双重验证器$/m);
  assert.match(readme, /鸿蒙验证器/);
  assert.match(readme, /两步验证/);
  assert.match(readme, /动态口令/);
  assert.match(readme, /OTP 验证器/);
  assert.match(readme, /HarmonyOS NEXT/);
});

test('中文 README 按用户任务说明九组核心功能', () => {
  const readme = read('README.md');
  const headings = [
    '扫码添加账号',
    '手动添加账号',
    '本地动态口令',
    '账号整理',
    '密钥与访问保护',
    '备份与恢复',
    '桌面服务卡片',
    '外观与反馈',
    '可选华为云空间'
  ];

  assert.match(readme, /^## 核心功能详解$/m);
  for (const heading of headings) {
    assert.match(readme, new RegExp(`^### ${heading}$`, 'm'));
  }
  assert.match(readme, /Google Authenticator 迁移二维码/);
  assert.match(readme, /TOTP、HOTP 和 Steam/);
  assert.match(readme, /Asset Store/);
  assert.match(readme, /明文 JSON/);
  assert.match(readme, /桌面服务卡片/);
  assert.match(readme, /不包含穿戴设备与手表同步/);
});

test('英文 README 提供对等功能说明和安全边界', () => {
  const readme = read('README_EN.md');
  const headings = [
    'Scan accounts',
    'Add accounts manually',
    'Generate codes locally',
    'Organize accounts',
    'Protect secrets and access',
    'Back up and restore',
    'Home-screen service cards',
    'Appearance and feedback',
    'Optional Huawei Cloud Space'
  ];

  assert.match(readme, /^# 2FA Authenticator Tool \| Native HarmonyOS Authenticator$/m);
  assert.match(readme, /HarmonyOS NEXT/);
  assert.match(readme, /Two-Factor Authentication/);
  for (const heading of headings) {
    assert.match(readme, new RegExp(`^### ${heading}$`, 'm'));
  }
  assert.match(readme, /plaintext JSON/);
  assert.match(readme, /does not include the wearable app or watch synchronization/);
});
