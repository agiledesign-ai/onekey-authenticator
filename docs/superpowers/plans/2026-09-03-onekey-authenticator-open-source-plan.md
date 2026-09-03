# 2FA验证器-工具开源整理实施计划

## 目标

按照[开源整理设计](../specs/2026-09-03-onekey-authenticator-open-source-design.md)，从私有工作区生成一套不携带原 Git 历史的公开源码，并发布到 GitHub 主仓库及 Gitee、GitCode 镜像。

公开版保留手机端 2FA、Asset Store、导入导出、人脸解锁、服务卡片、反馈页和可选华为云空间源码。公开版删除全部穿戴实现、原应用身份、正式签名和真实 Client ID。

## 当前基线

- 私有项目版本为 `1.0.5`，HarmonyOS SDK 配置为 `6.1.1`。
- 私有工作区存在已确认要纳入的反馈页未提交改动。
- 根工程包含 `entry`、`otp_core`、`wear` 三个模块。
- `entry` 与 `wear` 都依赖 `otp_core`；`otp_core` 不能整体删除。
- `otp_core/src/main/ets/wear/`、`entry/src/main/ets/features/wear/` 和 `wear/` 是穿戴专用实现。
- 私有构建配置含正式签名材料路径和密码，模块配置含原 Bundle Name 与真实 Client ID。这些内容不得进入公开 Git 对象。
- 现有 Node 合约测试基线为 20 项通过。
- 公开仓库已经仅提交设计规范，尚未复制产品源码。

## 固定原则

- 私有工作区只读，不提交、不重置、不清理、不修改远程地址。
- 公开仓库使用文件白名单生成快照，不复制私有 `.git`、构建产物和历史设计文档。
- 不把敏感配置先提交再删除；从第一个源码提交开始就必须干净。
- 每个行为变更遵循：先写失败测试，确认失败原因，再实现并运行相关回归。
- 每个阶段只暂存计划列出的公开仓库文件，不使用 `git add -A`。
- 不增加空的穿戴占位实现，也不建立旧 Bundle Name 或旧云配置的兼容路径。

## 固定验证命令

### Node 合约测试

```bash
node --test tests/*.test.mjs
```

### ArkTS 单元测试

```bash
hvigorw test \
  --mode module \
  -p module=entry@default \
  -p product=default \
  --no-daemon \
  --no-incremental
```

### 无正式签名构建

```bash
hvigorw assembleHap \
  -p product=default \
  -p module=entry@default \
  -p buildMode=debug \
  --no-daemon
```

### 开源边界检查

```bash
node scripts/open-source-audit.mjs
git diff --check
```

构建工具实际位置在执行时从已安装的 DevEco Studio 环境解析，不把个人机器路径写入仓库。

---

## 阶段 1：建立安全快照

### 任务 1：记录私有源快照并建立复制白名单

**公开仓库文件**

- 新建：`scripts/copy-manifest.txt`
- 新建：`docs/open-source-scope.md`

**步骤**

1. 记录私有仓库当前提交、分支、工作区状态和允许纳入的未提交反馈文件，用于执行后比对；该记录保存在本地执行日志，不提交源仓库隐私路径或远程信息。
2. 建立只允许以下内容进入公开仓库的清单：
   - `AppScope/` 中的图标、字符串与安全重建后的 `app.json5`。
   - `entry/` 源码、资源、单元测试和模块构建文件。
   - `otp_core/` 中手机端通用源码、单元测试入口和模块构建文件。
   - 根工程依赖、代码检查与 Hvigor 文件。
   - 现有非穿戴 Node 合约测试。
   - 已确认的反馈页未提交源码与测试。
3. 明确排除 `.git/`、`.idea/`、`.hvigor/`、`oh_modules/`、所有 `build/`、`.DS_Store`、本地配置、原 README、原历史设计文档、`wear/`、穿戴源码与穿戴测试。
4. 不复制未被反馈页引用的临时图片目录。
5. 在 `docs/open-source-scope.md` 说明保留和删除边界，但不记录私有绝对路径、真实 Client ID 或密码。
6. 人工核对复制清单只包含公开版所需文件。

### 任务 2：先实现可测试的开源审计器

**文件**

- 新建：`scripts/open-source-audit.mjs`
- 新建：`tests/open-source-audit.test.mjs`
- 新建：`tests/fixtures/open-source-audit/allowed.txt`
- 新建：`tests/fixtures/open-source-audit/forbidden-signing.txt`
- 新建：`tests/fixtures/open-source-audit/forbidden-wear.txt`

**步骤**

1. 先写失败测试，覆盖允许普通源码、拒绝签名字段值、拒绝真实 Client ID 形态、拒绝个人目录路径、拒绝穿戴模块路径和拒绝 WearEngine/SendToWatch 可执行引用。
2. 审计器扫描工作树时排除 `.git/`、构建目录、测试夹具、设计规范和截图；设计文档中的边界说明不应产生误报。
3. 审计器单独扫描 Git 已跟踪文件列表，拒绝证书、Profile、密钥库、备份文件和常见私钥扩展名。
4. 审计器输出具体相对路径与规则名称，但不得把匹配到的秘密值完整打印到日志。
5. 运行 `node --test tests/open-source-audit.test.mjs`，确认测试通过。
6. 提交：`test: add open-source boundary audit`。

### 任务 3：复制允许公开的源码并重建安全工程配置

**文件**

- 新建：白名单中的 `AppScope/**`
- 新建：白名单中的 `entry/**`
- 新建：白名单中的 `otp_core/**`
- 新建：根目录 `oh-package.json5`、`oh-package-lock.json5`、`hvigorfile.ts`、`code-linter.json5`
- 新建：安全版 `build-profile.json5`
- 新建或修改：`.gitignore`

**步骤**

1. 按 `scripts/copy-manifest.txt` 从私有仓库当前 `HEAD` 逐文件复制稳定基线，不使用递归复制整个私有仓库。
2. 根 `build-profile.json5` 只声明 `otp_core` 与 `entry`，不声明 `wear`。
3. 删除 `signingConfigs` 和产品的 `signingConfig` 引用；保留 SDK、产品和严格模式配置。
4. `.gitignore` 覆盖本地配置、签名材料、备份、二维码、账号导出、IDE 状态和构建产物。
5. 不复制生成的 `otp_core/BuildProfile.ets`；该文件由构建系统生成。
6. 本任务暂不复制反馈页新增文件，也不带入五个现有文件的反馈页工作区差异；这些差异由任务 9 单独纳入和验证。
7. 运行开源审计器并用 `git status --short` 人工核对新增文件。
8. 不在本任务提交源码，继续完成穿戴清理与身份替换后统一提交安全快照。

---

## 阶段 2：移除穿戴能力并保住手机端核心

### 任务 4：锁定手机端 `otp_core` 导出边界

**文件**

- 修改：`otp_core/Index.ets`
- 删除：`otp_core/src/main/ets/wear/WearAccountPolicy.ets`
- 删除：`otp_core/src/main/ets/wear/WearAccountRepository.ets`
- 删除：`otp_core/src/main/ets/wear/WearSendPolicy.ets`
- 新建：`tests/otp-core-public-boundary.test.mjs`

**步骤**

1. 先写失败合约测试，要求 `otp_core/Index.ets` 继续导出 OTP 模型、引擎、密钥 Codec、Asset Store 和安全策略，同时不导出任何穿戴类型。
2. 测试要求 `otp_core/src/main/ets/wear/` 不存在。
3. 删除 `Index.ets` 中三个穿戴文件的全部导出。
4. 删除穿戴专用目录，不移动或复制其中逻辑到手机端。
5. 运行 `otp-core-public-boundary` 测试和现有 OTP、安全、存储相关测试。

### 任务 5：删除手机端穿戴入口、路由和测试

**文件**

- 删除：`entry/src/main/ets/features/wear/**`
- 删除：`entry/src/main/ets/pages/SendToWatchPage.ets`
- 删除：`entry/src/test/WatchSyncRecord.test.ets`
- 删除：`entry/src/test/WearAccountPolicy.test.ets`
- 删除：`entry/src/test/WearSendPolicy.test.ets`
- 修改：`entry/src/main/ets/features/settings/model/SettingsDetailPolicy.ets`
- 修改：`entry/src/main/resources/base/profile/main_pages.json`
- 修改：`entry/src/test/List.test.ets`
- 修改：`entry/src/test/SettingsDetailPolicy.test.ets`
- 删除：`tests/wearable-module-contract.test.mjs`
- 新建：`tests/no-wearable-feature.test.mjs`

**步骤**

1. 先写失败测试，要求工程模块、可执行源码、路由、元数据和测试入口中不存在穿戴能力。
2. 从路由策略删除 `SEND_WATCH`，从 `main_pages.json` 删除 `SendToWatchPage`。
3. 从 ArkTS 测试入口移除三项穿戴测试，并将设置路由数量调整为公开版实际数量。
4. 删除手机端穿戴目录、页面和专用测试。
5. 删除原穿戴 Node 合约，使用公开边界测试替代。
6. 运行 Node 合约测试和 ArkTS 单元测试，确认 `entry` 仍能依赖 `otp_core`。

### 阶段 2 验收

- 工程只包含 `entry` 与 `otp_core`。
- `otp_core` 保留手机端通用能力，不存在穿戴导出。
- 设置、路由、权限和测试中没有手表入口或 WearEngine。
- 不存在空页面、空接口或旧路由兼容代码。

---

## 阶段 3：隔离应用身份和云空间配置

### 任务 6：切换公开 Bundle Name

**文件**

- 修改：`AppScope/app.json5`
- 修改：`entry/src/main/ets/pages/CardConfigPage.ets`
- 新建：`tests/public-app-identity.test.mjs`

**步骤**

1. 先写失败测试，要求 `AppScope/app.json5` 使用 `com.agiledesign.onekeyauthenticator.opensource`，并拒绝原正式 Bundle Name。
2. 将服务卡片 Ability 参数中的硬编码包名切换到公开 Bundle Name。
3. 将 `cloudStructuredDataSyncEnabled` 设为 `false`。
4. 保持显示名称和 `1.0.5` 版本号不变。
5. 全仓扫描原正式 Bundle Name，设计规范之外不得出现。

### 任务 7：建立单一云功能开关并默认关闭

**文件**

- 新建：`entry/src/main/ets/features/cloud/model/CloudFeaturePolicy.ets`
- 新建：`entry/src/test/CloudFeaturePolicy.test.ets`
- 修改：`entry/src/main/ets/entryability/EntryAbility.ets`
- 修改：`entry/src/main/ets/pages/SecurityBackupPage.ets`
- 修改：`entry/src/test/List.test.ets`
- 修改：`tests/cloud-space-contract.test.mjs`

**步骤**

1. 先写失败测试，要求公开源码只有一个云功能开关，默认值为 `false`。
2. `EntryAbility` 只有在开关为 `true` 时才调用 `CloudSyncRuntime.init()`。
3. `SecurityBackupPage` 只有在开关为 `true` 时才渲染华为云空间入口及对应分隔线。
4. 保留 `CloudSpacePage` 和云服务源码，供开发者配置自己的 AGC 项目后启用。
5. 不增加运行时远程开关、自动探测 Client ID 或静默启用逻辑。
6. 更新测试，分别验证云实现仍存在、公开入口默认隐藏、初始化默认不执行。

### 任务 8：移除正式云元数据和权限声明

**文件**

- 修改：`entry/src/main/module.json5`
- 修改：`tests/cloud-space-contract.test.mjs`
- 新建：`docs/cloud-space-setup.md`

**步骤**

1. 先写失败测试，要求默认模块配置中不存在 `client_id`、WearEngine 元数据、`INTERNET` 和 `DISTRIBUTED_DATASYNC` 权限。
2. 删除全部正式元数据与上述云权限，使默认公开构建不声明网络和分布式同步权限。
3. 在 `docs/cloud-space-setup.md` 给出唯一启用流程：创建开发者自己的 AGC 应用、配置公开 Bundle Name、加入自己的 Client ID 和所需权限、启用结构化数据同步、最后将 `CloudFeaturePolicy` 开关设为 `true`。
4. 示例只使用 `YOUR_CLIENT_ID` 等明确占位值，不包含原应用数值。
5. 运行云合约测试和开源审计器。

### 阶段 3 验收

- 默认构建不声明云权限、不初始化云服务、不显示云入口。
- 云同步实现源码仍保留，并有单一路径供开发者启用。
- 公开仓库不存在原 Bundle Name、真实 Client ID、签名信息或个人路径。

---

## 阶段 4：纳入反馈页并补齐开源文档

### 任务 9：完成反馈页快照集成

**文件**

- 新建：`entry/src/main/ets/features/settings/model/FeedbackMailPolicy.ets`
- 新建：`entry/src/main/ets/pages/FeedbackPage.ets`
- 新建：`entry/src/test/FeedbackMailPolicy.test.ets`
- 新建：`tests/feedback-contract.test.mjs`
- 修改：`entry/src/main/ets/features/settings/components/SettingsTabContent.ets`
- 修改：`entry/src/main/ets/features/settings/model/SettingsDetailPolicy.ets`
- 修改：`entry/src/main/resources/base/profile/main_pages.json`
- 修改：`entry/src/test/List.test.ets`
- 修改：`entry/src/test/SettingsDetailPolicy.test.ets`

**步骤**

1. 先运行反馈合约与单元测试，确认在未纳入页面时失败。
2. 从私有工作区复制已经确认的反馈源码和测试，不重新设计交互。
3. 保留邮件收件人 `halolion@petalmail.com`、预填主题与失败提示。
4. 确认穿戴路由删除后，反馈路由数量和索引断言与公开版一致。
5. 运行反馈相关测试、设置路由测试和完整回归。

### 任务 10：添加许可证、DCO 与社区治理文件

**文件**

- 新建：`LICENSE`
- 新建：`NOTICE`
- 新建：`CONTRIBUTING.md`
- 新建：`SECURITY.md`
- 新建：`CODE_OF_CONDUCT.md`
- 新建：`CHANGELOG.md`
- 修改：`entry/oh-package.json5`
- 修改：`otp_core/oh-package.json5`
- 新建：`.github/ISSUE_TEMPLATE/bug_report.yml`
- 新建：`.github/ISSUE_TEMPLATE/feature_request.yml`
- 新建：`.github/ISSUE_TEMPLATE/config.yml`
- 新建：`.github/pull_request_template.md`

**步骤**

1. 使用未经改写的 Apache License 2.0 正文。
2. `NOTICE` 使用个人版权主体“曾亦远”，并说明项目名、图标、截图和身份不得用于暗示作者背书。
3. `CONTRIBUTING.md` 要求贡献者使用 `git commit -s`，每个提交包含有效 `Signed-off-by`；不使用 CLA。
4. `SECURITY.md` 使用 `halolion@petalmail.com` 私下接收漏洞报告，明确禁止提交真实密钥、二维码和备份。
5. 将 `entry` 与 `otp_core` 包清单中的许可证统一为 `Apache-2.0`，并补充准确的模块描述。
6. Issue 与 Pull Request 模板包含复现信息、测试证据、敏感信息检查和 DCO 清单。
7. `CHANGELOG.md` 将 `v1.0.5` 标记为 2026-09-03 首次公开源码版本，不声称已完成真机、云空间或应用市场验证。

### 任务 11：复制截图并编写中英文 README

**文件**

- 新建：`docs/images/screenshots/settings.png`
- 新建：`docs/images/screenshots/security-backup-full-edition.png`
- 新建：`docs/images/screenshots/authenticator-empty-state.png`
- 新建：`docs/images/screenshots/about-full-edition.png`
- 新建：`docs/images/screenshots/two-factor-guide.png`
- 新建：`README.md`
- 新建：`README_EN.md`

**步骤**

1. 原样复制用户提供的五张 PNG，不重绘产品界面；计算并记录最终文件哈希。
2. README 使用“2FA验证器-工具”“HarmonyOS 原生 2FA 验证器”“本地优先”等准确关键词。
3. 将 GitHub、Gitee、GitCode Star 徽章放在标题区域，并链接到三个仓库。
4. 明确 GitHub 为主仓库，Gitee 与 GitCode 为同步镜像。
5. 将包含手表入口的第二、第四张标记为原完整版本界面，明确公开源码不包含手表同步。
6. 标注“关于应用”截图来自 `v1.0.4`，首次公开源码为 `v1.0.5`。
7. 明确明文 JSON 导出的安全风险，以及华为云空间默认关闭和开发者自有 AGC 配置要求。
8. 加入微信 `petalmailo`、邮箱 `halolion@petalmail.com` 和来源/原因说明，用于应用定制、项目合作与技术咨询。
9. 中英文 README 的功能范围、隐私边界和镜像关系保持一致。

### 阶段 4 验收

- 反馈页和测试已纳入，设置入口可达。
- Apache-2.0、DCO、安全政策和社区模板完整。
- 五张截图均可读取，历史完整版截图有清晰边界说明。
- README 不把穿戴、云空间默认启用或未执行的设备验证宣传为公开版现状。

---

## 阶段 5：持续集成、完整验证与本地发布提交

### 任务 12：建立 CI 和发布前审计

**文件**

- 新建：`.github/workflows/quality.yml`
- 修改：`scripts/open-source-audit.mjs`
- 修改：`tests/open-source-audit.test.mjs`

**步骤**

1. 先写失败测试，覆盖 Git 跟踪文件、源码内容、图片路径、README 链接和版本号一致性。
2. CI 固定运行 Node 合约测试、开源边界审计和 `git diff --check`。
3. HarmonyOS 构建依赖本地 DevEco 环境，README 给出命令；没有对应官方 CI 环境时不伪造云端构建结果。
4. 审计器增加 `git ls-files` 模式，确认无证书、Profile、备份、二维码和构建产物被跟踪。
5. 运行完整 Node 测试。

### 任务 13：运行 ArkTS、构建和源码边界回归

**步骤**

1. 运行 ArkTS 单元测试并记录通过数量；若 DevEco/Hvigor 环境失败，先定位环境或源码根因，不跳过失败。
2. 运行 `entry` Debug HAP 构建，确认不依赖正式签名和真实 Client ID。
3. 检查最终包信息，验证公开 Bundle Name、版本 `1.0.5` 和仅包含手机/二合一入口。
4. 全仓搜索穿戴符号、原 Bundle Name、Client ID、签名字段和个人路径。
5. 对待提交文件运行 `git diff --check`、文件类型检查和大文件清单检查。
6. 比对私有源工作区状态，确认其提交、修改和未跟踪文件与任务开始时一致。

### 任务 14：形成公开源码提交和标签

**步骤**

1. 仅暂存已审计的公开源码、文档、测试和截图。
2. 提交：`feat: publish clean open-source authenticator snapshot`。
3. 对 `git ls-tree -r HEAD` 和所有可达 Git 对象重新运行敏感信息扫描。
4. 确认设计、计划和源码历史中没有真实秘密。
5. 创建带说明标签 `v1.0.5`，暂不推送远程。
6. 输出本地提交哈希、标签目标、测试结果和未执行的外部验证，交付发布前核对。

---

## 阶段 6：创建三平台仓库并同步发布

### 任务 15：创建远程仓库

**目标**

- GitHub：`https://github.com/agiledesign-ai/onekey-authenticator`
- Gitee：`https://gitee.com/agiledesign/onekey-authenticator-open-source`（同名路径已被原私有源码仓库占用）
- GitCode：`https://gitcode.com/yunagile/onekey-authenticator`

**步骤**

1. 先检查三个目标是否已存在，避免创建重名或覆盖已有仓库。
2. 创建公开空仓库，不自动生成 README、许可证或 `.gitignore`。
3. 设置 GitHub 为 `origin`，Gitee 与 GitCode 使用清晰的镜像远程名。
4. 平台要求登录、验证码或身份确认时停止自动操作，由仓库所有者完成。
5. 不在终端历史、仓库文件或文档中保存访问令牌。

### 任务 16：推送、核验并发布 `v1.0.5`

**步骤**

1. 将 `main` 和 `v1.0.5` 推送到 GitHub。
2. 将完全相同的提交和标签推送到 Gitee、GitCode。
3. 核对三个平台 `main` 的提交哈希与本地一致。
4. 核对三个平台 `v1.0.5` 标签指向相同提交。
5. 打开三个公开页面，验证 README、五张截图、许可证、联系方式和 Star 徽章。
6. 在 GitHub 创建 `v1.0.5` 源码 Release；不上传正式签名 HAP。
7. 记录三个公开链接、最终提交哈希、标签目标和平台核验结果。

## 最终完成定义

以下条件全部满足后才能报告完成：

- 私有源工作区保持原状。
- Node、ArkTS、公开边界和 Debug 构建验证均有真实结果。
- 公开 Git 对象不含敏感信息、正式身份或穿戴实现。
- 默认公开应用不声明云权限、不显示云入口、不初始化云服务。
- GitHub、Gitee、GitCode 的 `main` 和 `v1.0.5` 完全一致。
- 三个平台页面均已验证 README、截图、许可证、链接和 Star 徽章。
- GitHub Release 已发布源码，未发布正式签名 HAP。
