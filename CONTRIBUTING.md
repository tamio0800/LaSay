# Contributing to LaSay

Thanks for helping improve LaSay. Please open an issue first for substantial changes so the user problem and scope are clear.

繁體中文請見 [CONTRIBUTING_ZH.md](CONTRIBUTING_ZH.md)。

## Quick start

1. Fork the repository and create a focused branch, for example `fix/accessibility-setup`.
2. Open `LaSay/LaSay.xcodeproj` in Xcode and select your own Apple Development signing team.
3. Build and test before opening a pull request:

   ```bash
   xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay -configuration Debug build
   xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay test
   ```

Follow the Swift conventions in [AGENTS.md](AGENTS.md). Keep changes small, add a focused XCTest regression test when behavior changes, and retain the English and Traditional Chinese interface text.

## Pull requests

Use a short Conventional Commit subject such as `fix: restore direct-input setup`. Explain the user-visible change, verification performed, and related issue. Include screenshots for menu-bar, onboarding, settings, or other UI changes.

Never commit API keys, credentials, model downloads, build products, DMGs, logs, or Xcode user data. Do not run the maintainer's signing, notarization, or release workflow. Contributions are submitted under the repository's MIT license.
