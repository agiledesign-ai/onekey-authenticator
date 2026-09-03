# 2FA Authenticator Tool | Native HarmonyOS Authenticator

A local-first HarmonyOS NEXT authenticator for Two-Factor Authentication (2FA). It generates TOTP, HOTP, and Steam one-time passwords on the device and stores secrets in HarmonyOS Asset Store by default.

Current version: **1.0.5** (`versionCode` 1000005)

[中文说明](README.md)

## Core features

### Scan accounts

Scan a standard `otpauth` QR code to add an account. Google Authenticator migration QR codes are also supported for moving multiple existing accounts.

### Add accounts manually

Enter the issuer, account name, secret, and algorithm parameters when a service provides a text key instead of a QR code. TOTP, HOTP, and Steam account types are supported.

### Generate codes locally

One-time passwords are calculated on the device without sending secrets to an application server. TOTP uses time periods, HOTP uses a counter, and the Steam type produces the corresponding code format.

### Organize accounts

Search, pin, edit, and group accounts. These controls keep large collections of authentication accounts easy to navigate.

### Protect secrets and access

Secrets are stored in HarmonyOS Asset Store rather than ordinary preference text. Optional face unlock verifies the user when launching or returning to the app.

### Back up and restore

Export selected accounts as plaintext JSON and import them later. A plaintext backup contains 2FA secrets, so it must be encrypted and must never be attached to a public issue or chat.

### Home-screen service cards

Place frequently used codes on a HarmonyOS home-screen service card. The card presents the current code without storing the plaintext secret.

### Appearance and feedback

Choose light, dark, or system-following appearance. The feedback entry opens the system email app with a prefilled message.

### Optional Huawei Cloud Space

Huawei Cloud Space source remains in the repository, but the public build disables its entry point, permissions, and initialization. Developers must supply a separate AppGallery Connect identity and Client ID before enabling it.

## Screenshots

All five screenshots are available in [`docs/images/screenshots`](docs/images/screenshots). They show settings, security and backup, the authenticator home screen, the capability summary, and the 2FA setup guide. The screenshots named `full-edition` show the original complete product and include a watch-sync entry. The public source does not include the wearable app or watch synchronization. The About screenshot shows the original `v1.0.4` UI; the first public source release is `v1.0.5`.

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
