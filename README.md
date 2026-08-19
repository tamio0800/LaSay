# LaSay

<p align="center"><img src="lasay-icon.png" width="112" alt="LaSay icon"></p>

<p align="center">Voice input for developers on macOS.</p>

Hold a shortcut, speak naturally in English, Chinese, or both, then release. LaSay turns your speech into text and writes it directly into the active text field, while keeping technical terms such as `React` and `FastAPI` intact. A copy is kept as a fallback.

<p align="center"><img src="docs/assets/lasay-demo-en.gif" width="535" alt="LaSay voice input demo"></p>

[繁體中文](README_ZH.md) · [AI agent guide](AGENT_GUIDE.md) · [Contributing](CONTRIBUTING.md) · [Download the latest DMG](https://github.com/tamio0800/LaSay/releases/latest)

## Install

Paste this one command into Terminal. It adds LaSay's Homebrew source, then installs the app.

```bash
brew tap tamio0800/tap && brew install --cask lasay
```

Prefer a DMG? Download the app from [GitHub Releases](https://github.com/tamio0800/LaSay/releases/latest), then drag LaSay to Applications.

### Updates

For a Homebrew installation, quit LaSay first, then run:

```bash
brew upgrade --cask lasay
```

For a DMG installation, choose **Check for Updates…** in LaSay Settings. Use the updater that matches how LaSay was installed; Homebrew installs should use Homebrew. Normal signed updates keep Microphone and Accessibility permissions.

## First launch and daily use

On first launch, LaSay guides you through two one-time permissions:

1. **Microphone**: lets LaSay hear your voice.
2. **Accessibility**: lets LaSay insert the result into the active text field.

macOS asks you to approve each permission. If one was previously denied, LaSay opens the correct System Settings page. Permissions are detected automatically. Setup then asks you to hold the shortcut and speak into a real test field; setup is complete only after the text appears.

After setup:

1. Hold **Fn + Space** anywhere you can type. You can choose Control + Space or Option + Space in Settings.
2. Speak naturally, then release. LaSay inserts the result at the cursor.
3. If automatic insertion is unavailable or fails, the result is still copied. Press **Command + V** to paste it manually.

## Choose where transcription happens

| Mode | What happens | API key | Cost |
| --- | --- | --- | --- |
| **Local (default)** | The included SenseVoiceSmall model processes recorded audio on your Mac. | Not needed | Free |
| **OpenAI cloud** | LaSay sends the recording to OpenAI for transcription. | Required | Depends on your selected model |

LaSay does not require a LaSay account or sync your content. Your OpenAI API key is stored in macOS Keychain. If you enable optional OpenAI text cleanup, the transcribed text is also sent to OpenAI.

With AI Polish off, LaSay applies its built-in technical-term corrections. With AI Polish on, the selected model preserves terms contextually instead.

## What you get

- Push-to-talk voice input in VS Code, Terminal, Slack, browsers, and other text fields
- English, Traditional Chinese, Japanese, Korean, and automatic language detection
- Built-in technical-term corrections for framework names, code identifiers, and common abbreviations
- Optional OpenAI transcription, text cleanup, and custom model IDs
- A simple menu-bar app with launch-at-login and configurable shortcuts

## Requirements

- Apple silicon Mac
- macOS 13.5 (Ventura) or later
- Internet connection and an OpenAI API key only for OpenAI features

## Build from source

```bash
git clone https://github.com/tamio0800/LaSay.git
cd LaSay
open LaSay/LaSay.xcodeproj
```

Choose your Apple Development signing team in Xcode, then build with **Command + B**. Xcode resolves the included dependencies automatically.

## License

LaSay's original source code is available under the [MIT License](LICENSE). The bundled model and native runtime retain their own licenses; see [Third-Party Notices](THIRD_PARTY_NOTICES.md).
