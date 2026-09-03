# 2FA Authenticator Tool

A local-first native HarmonyOS authenticator for TOTP, HOTP, and Steam codes.

Current version: **1.0.5** (`versionCode` 1000005)

[中文说明](README.md)

## Highlights

- Generates verification codes locally.
- Stores secrets in HarmonyOS Asset Store by default.
- Imports `otpauth` and Google Authenticator migration QR codes.
- Supports search, pinning, editing, and groups.
- Supports optional face unlock and home-screen service cards.
- Imports and exports selected accounts as plaintext JSON.
- Opens the system email app for feedback.
- Keeps Huawei Cloud Space source available but disabled in the public build.

## Screenshots

All five screenshots are available in [`docs/images/screenshots`](docs/images/screenshots). The screenshots named `full-edition` show the original complete product and include a watch-sync entry. The public source does not include wearable or watch-sync functionality. The About screenshot shows the original `v1.0.4` UI; the first public source release is `v1.0.5`.

## Public-source boundary

This repository excludes the wearable app, WearEngine integration, watch routes and tests, the original production Bundle Name, Client ID, certificates, profiles, and signing passwords.

The `otp_core` module remains because the phone app depends on its OTP algorithms, Asset Store adapters, and security policies. Wearable-only code has been removed from that module.

## Build

Requirements:

- DevEco Studio 6.1.1 Release
- HarmonyOS SDK 6.1.1 (API 24)
- Node.js 20 or newer for source contract tests

```bash
git clone https://github.com/agiledesign-ai/onekey-authenticator.git
cd onekey-authenticator
ohpm install --all
node --test tests/*.test.mjs
```

Open the project in DevEco Studio and configure your own debug signing identity. No production signing material is included.

## Huawei Cloud Space

The public build does not request cloud permissions, contain a Client ID, show the Cloud Space entry, or initialize cloud services. To enable it, configure your own AppGallery Connect application by following [`docs/cloud-space-setup.md`](docs/cloud-space-setup.md).

## Security

Exported JSON files contain plaintext 2FA secrets. Encrypt and store them securely. Never attach real secrets, QR codes, or backups to public issues or pull requests.

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Contributions require a DCO sign-off:

```bash
git commit -s -m "feat: describe your change"
```

## Repository roles

- Primary: [GitHub](https://github.com/agiledesign-ai/onekey-authenticator)
- Mirror: [Gitee](https://gitee.com/agiledesign/onekey-authenticator-open-source)
- Mirror: [GitCode](https://gitcode.com/yunagile/onekey-authenticator)

Use GitHub for issues, pull requests, and releases.

## Contact

- WeChat: `petalmailo`
- Email: `halolion@petalmail.com`

When adding WeChat, include where you found the project, your contact details, and the reason for contacting. Custom app development and project cooperation inquiries are welcome.

## License

Licensed under [Apache License 2.0](LICENSE). Contributions are also subject to the [DCO](DCO).
