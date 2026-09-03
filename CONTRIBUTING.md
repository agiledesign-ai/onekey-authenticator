# 贡献指南

感谢你参与“2FA验证器-工具”。Issue 和 Pull Request 可以使用中文或英文。

## 适合贡献的内容

- TOTP、HOTP、Steam 兼容性和正确性改进
- HarmonyOS 适配、性能与无障碍改进
- Asset Store、导入导出、生物认证和服务卡片改进
- 隐私、安全、测试、文档和翻译改进
- 符合公开版边界的新功能

本仓库不接收穿戴设备应用、WearEngine 集成或手机向手表发送账号的实现。请勿通过 Pull Request 恢复已移除的穿戴代码。

## 提交 Issue

提交缺陷前，请先搜索已有 Issue。报告应包含：

- 版本或完整提交号
- 设备型号与 HarmonyOS 版本
- 最小复现步骤、预期结果和实际结果
- 已移除敏感信息的日志或截图

不要提交真实 2FA 密钥、二维码、验证码、账号备份、Client ID、证书或签名信息。安全问题请按照 [SECURITY.md](SECURITY.md) 私下报告。

## 本地开发

```bash
git clone https://github.com/agiledesign-ai/onekey-authenticator.git
cd onekey-authenticator
ohpm install --all
node --test tests/*.test.mjs
node scripts/open-source-audit.mjs
```

使用 DevEco Studio 6.1.1 Release 和 HarmonyOS SDK 6.1.1。调试签名必须使用贡献者自己的本地配置。

## 分支与提交

1. 从最新 `main` 创建短期功能分支。
2. 一个 Pull Request 只处理一个清晰问题。
3. 保持现有代码格式，并在安全或数据边界添加简洁注释。
4. 行为变更必须先补充能复现问题或描述新行为的测试。
5. 使用清晰的提交信息，例如 `fix: reject invalid hotp counter`。

## DCO 签名

本项目使用 [Developer Certificate of Origin 1.1](DCO)，不要求签署 CLA。

每个提交都必须带有与你提交身份匹配的 `Signed-off-by`：

```bash
git commit -s -m "fix: describe your change"
```

如果已有提交缺少签名，可以在确认你有权提交这些内容后执行：

```bash
git commit --amend --signoff --no-edit
```

## 提交前检查

```bash
node --test tests/*.test.mjs
node scripts/open-source-audit.mjs
git diff --check
```

涉及 ArkTS 行为时还应运行：

```bash
hvigorw test --mode module \
  -p module=entry@default \
  -p product=default \
  --no-daemon \
  --no-incremental
```

## Pull Request 要求

- 说明问题、方案、影响范围和验证结果。
- UI 改动附修改前后截图，并移除真实账号和验证码。
- 不得包含构建产物、本机路径、密钥、签名材料或真实 Client ID。
- 不得加入未经说明的网络服务、遥测或统计 SDK。
- 依赖变更说明用途、许可证和必要性。
- 用户可见变化更新 README 或 CHANGELOG。
- 所有提交通过 DCO 检查。

维护者会根据范围、正确性、安全性、测试证据和长期维护成本评审变更。
