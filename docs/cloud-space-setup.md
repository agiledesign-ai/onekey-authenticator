# 华为云空间配置

公开源码中的华为云空间能力默认关闭。只有在完成自己的 AppGallery Connect（AGC）配置后才能启用。

## 前置条件

- 创建 Bundle Name 为 `com.agiledesign.onekeyauthenticator.opensource` 的 AGC 应用，或先将项目改为你自己的 Bundle Name。
- 配置与该应用匹配的调试或发布签名。
- 启用云数据库和端云数据同步服务。
- 将测试华为账号加入项目允许范围。

## 1. 创建云数据

创建容器 `securekeyAccounts`，并建立以下数据类型：

### `accounts`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 主键 |
| `type` | String | TOTP、HOTP 或 Steam |
| `serviceName` | String | 服务名称 |
| `accountName` | String | 账号名称 |
| `secretKey` | Encrypted String | 2FA 密钥，必须使用加密字符串 |
| `algorithm` | String | 摘要算法 |
| `digits` | Number | 验证码位数 |
| `period` | Number | TOTP 周期 |
| `counter` | Number | HOTP 计数器 |
| `groupId` | String | 分组 ID |
| `pinned` | Number | 置顶状态，0 或 1 |
| `sortIndex` | Number | 排序值 |
| `createdAt` | Number | 创建时间 |
| `updatedAt` | Number | 更新时间 |
| `schemaVersion` | Number | 本地模型版本 |
| `badgeColor` | String | 标识颜色 |

### `groups`

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 主键 |
| `name` | String | 分组名称 |
| `sortIndex` | Number | 排序值 |
| `createdAt` | Number | 创建时间 |
| `updatedAt` | Number | 更新时间 |

字段必须与 `entry/src/main/ets/features/cloud/model/CloudRecordCodec.ets` 保持一致。已经发布的数据类型不要改名或改变类型。

## 2. 启用应用级云同步

将 `AppScope/app.json5` 中的配置改为：

```json5
"cloudStructuredDataSyncEnabled": true
```

## 3. 添加模块元数据与权限

在 `entry/src/main/module.json5` 的 `module` 中加入自己的 OAuth 2.0 Client ID：

```json5
"metadata": [
  {
    "name": "client_id",
    "value": "YOUR_CLIENT_ID"
  }
]
```

`YOUR_CLIENT_ID` 必须来自你自己的 AGC 应用，不是 App ID。

同时在 `requestPermissions` 中加入：

```json5
{
  "name": "ohos.permission.INTERNET"
},
{
  "name": "ohos.permission.DISTRIBUTED_DATASYNC",
  "reason": "$string:distributed_data_sync_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "inuse"
  }
}
```

## 4. 打开唯一功能开关

将 `entry/src/main/ets/features/cloud/model/CloudFeaturePolicy.ets` 中的常量改为：

```typescript
private static readonly ENABLED: boolean = true;
```

该开关同时控制设置入口和应用启动时的云服务初始化。不要另建第二套运行时开关。

## 5. 验证

1. 运行 ArkTS 单元测试和 Debug HAP 构建。
2. 在测试真机登录已加入 AGC 测试范围的华为账号。
3. 验证手动推送、手动获取、自动同步和退出账号。
4. 验证未开启自动同步时，本地增删改不会写入云空间。
5. 检查日志只包含状态码，不包含账号密钥。

Client ID、证书、Profile 和签名密码属于本地或部署配置，不得提交到公开仓库。
