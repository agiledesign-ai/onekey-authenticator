# 更新记录

本项目采用 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 的结构，并使用语义化版本号。

## [Unreleased]

### 计划

- 接收社区反馈并继续完善兼容性、测试和文档。

## [1.0.5] - 2026-09-03

### 新增

- 首个公开源码版本。
- TOTP、HOTP、Steam、扫码、手动添加和 Google 迁移二维码。
- Asset Store、本地导入导出、人脸解锁和桌面服务卡片。
- 建议反馈页面。
- 华为云空间实现源码及开发者自有 AGC 配置指南。
- Apache-2.0、DCO、社区模板和开源边界检查。

### 安全

- 使用独立公开 Bundle Name。
- 移除原应用 Client ID、签名材料和个人机器路径。
- 默认不声明云权限、不显示云入口、不初始化云服务。
- 完整移除穿戴应用、WearEngine 和手表同步代码。

### 验证说明

- 首次发布提供源码，不提供正式签名 HAP。
- 本地构建不代表已完成真机云空间或应用市场验证。

[Unreleased]: https://github.com/agiledesign-ai/onekey-authenticator/compare/v1.0.5...HEAD
[1.0.5]: https://github.com/agiledesign-ai/onekey-authenticator/releases/tag/v1.0.5
