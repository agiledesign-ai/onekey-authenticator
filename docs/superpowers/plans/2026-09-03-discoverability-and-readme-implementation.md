# 2FA 验证器可发现性与 README 功能说明实施计划

## 目标

按照[可发现性与 README 功能说明设计](../specs/2026-09-03-discoverability-and-readme-design.md)，完善中英文 README，并更新 GitHub、Gitee 和 GitCode 的项目介绍与标签。仓库名称、应用源码、版本号和穿戴能力排除边界保持不变。

## 任务 1：先建立 README 文档契约

**文件**

- 新建：`tests/readme-discoverability.test.mjs`

**步骤**

1. 断言中文 README 标题和首段包含“HarmonyOS”“鸿蒙原生双重验证器”“动态口令”。
2. 断言中文 README 包含九组核心功能标题。
3. 断言 README 说明 TOTP、HOTP、Steam、扫码迁移、Asset Store、备份和服务卡片。
4. 断言 README 明确备份为明文 JSON，并保留安全警告。
5. 断言中英文 README 都说明公开源码不包含穿戴设备与手表同步。
6. 运行新增测试，确认它因现有 README 信息不足而失败。

## 任务 2：重写中文 README 首屏与功能说明

**文件**

- 修改：`README.md`

**步骤**

1. 将标题调整为“2FA验证器-工具｜HarmonyOS 鸿蒙原生双重验证器”。
2. 在首段自然加入“鸿蒙验证器”“两步验证”“动态口令”和“OTP 验证器”等词。
3. 保留本地计算和 Asset Store 安全定位。
4. 将现有功能清单扩展为九组核心功能详解。
5. 为截图补充对应功能说明，并保留原完整版本截图提示。
6. 在备份、桌面卡片和华为云空间章节保留准确安全边界。
7. 不暗示公开源码包含手表同步。

## 任务 3：同步更新英文 README

**文件**

- 修改：`README_EN.md`

**步骤**

1. 使用“2FA Authenticator Tool | Native HarmonyOS Authenticator”作为标题语义。
2. 加入 HarmonyOS NEXT、Two-Factor Authentication、OTP、TOTP、HOTP 和 Steam 等准确术语。
3. 提供与中文 README 对等的九组功能说明。
4. 保留 plaintext JSON、Asset Store、service card 和 cloud feature 的安全警告。
5. 明确 wearable app、watch sync 和 WearEngine 不在公开源码中。

## 任务 4：完成本地验证并提交

运行：

```bash
node --test tests/*.test.mjs
node scripts/open-source-audit.mjs
git diff --check
```

在可用的 DevEco Studio 环境中运行现有 ArkTS 单元测试。精确暂存新增测试、两个 README 和实施计划，提交信息使用：

```text
docs: expand authenticator features and discoverability
```

现有 `v1.0.5` 标签保持不动。

## 任务 5：发布 GitHub 主仓库并同步镜像

1. 将 `main` 推送到 GitHub 主仓库。
2. 等待 Gitee 和 GitCode 自动镜像完成。
3. 核对三个平台的 `main` 指向同一个提交。
4. 不创建新版本、不移动 `v1.0.5` 标签。

## 任务 6：更新三平台项目元数据

### GitHub

- 保存设计中确定的 About 文案。
- 保留现有 Topics，增加 `arkui`、`harmonyos-next`、`otp`、`two-factor-authentication`、`steam`、`security` 和 `hongmeng`。

### Gitee

- 更新介绍并注明 GitHub 主仓库镜像关系。
- 保存五个标签：`HarmonyOS`、`2FA验证器`、`动态口令`、`ArkTS`、`TOTP`。

### GitCode

- 更新项目介绍并注明同步镜像。
- 保存五个标签：`HarmonyOS`、`2FA`、`Authenticator`、`TOTP`、`ArkTS`。

## 任务 7：线上验收

1. 查看三个平台 README 的标题、首段、功能分组、截图和徽章。
2. 查看三个平台项目介绍和标签是否保存成功。
3. 核对 GitHub Actions 实际运行状态；未运行或未完成时不得写成通过。
4. 重新查询 GitHub 站内和通用搜索引擎，并记录当时结果。
5. 搜索引擎尚未收录不阻塞发布完成，但交付说明必须明确当前状态。
