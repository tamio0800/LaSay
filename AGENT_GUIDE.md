# LaSay AI Agent Guide

Use this guide when helping someone install, configure, troubleshoot, or contribute to LaSay. Do not ask for, store, or print an OpenAI API key; users enter it themselves in LaSay Settings and macOS stores it in Keychain.

## Install and update

LaSay runs on Apple silicon Macs with macOS 13.5 or later. Install it with:

```bash
brew tap tamio0800/tap && brew install --cask lasay
```

Use the updater that matches the installation method: Homebrew installations use `brew upgrade --cask lasay`; DMG installations use **Check for Updates…** in LaSay Settings. Do not mix the two update paths. A DMG is also available from the GitHub Releases page. Start the app with `open -a LaSay` or from Applications.

## First-run success criteria

LaSay must receive two one-time macOS permissions: **Microphone** to record speech and **Accessibility** to write text into the active text field. macOS requires the person at the keyboard to approve them. Do not describe Accessibility as optional.

After both permissions are granted, LaSay returns to the foreground and opens a test field. Have the user click it, hold **Fn + Space**, speak, then release. Setup is complete only when generated text appears in that field. If a permission was denied earlier, choose **Run Setup Again…** from the LaSay menu-bar menu. Select **Allow Accessibility** first; use **Open Accessibility Settings** only if macOS does not show its prompt.

## Everyday use and settings

Hold **Fn + Space** in any editable field, speak, and release. Direct input at the cursor is the default. The transcription stays on the clipboard as a recovery path, so use **Command + V** only if direct input fails.

Open **Settings…** from LaSay's menu-bar icon, or open LaSay from Applications again. Local SenseVoice transcription is the default, free, and stays on-device. OpenAI cloud transcription and AI Polish require the user's own API key; those enabled features send the relevant audio or text to OpenAI.

Do not replace files inside `/Applications/LaSay.app`: that breaks the app signature and will be overwritten by updates. Normal Homebrew or DMG updates do not require removing LaSay from Accessibility first. Keep the `/Applications/LaSay.app` permission entry; remove only duplicate entries from Debug or backup copies when cleaning a development machine. To change the bundled recognizer, fork the source, retain model license notices, and build/test the fork.

## Troubleshooting and contributions

Check that the target app has an active editable field, then rerun setup before diagnosing transcription. Do not reset macOS privacy databases or alter system permissions outside the normal Settings flow. If LaSay says Accessibility is missing while System Settings already shows LaSay enabled, the permission record is stale: remove only the LaSay row with **–**, add `/Applications/LaSay.app` with **+**, enable it, then reopen LaSay. This is a user-approved system-permission change; do not touch other rows.

For source changes, read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md), use a fork and pull request, and do not commit credentials, build products, models, DMGs, or Xcode user data. Maintainer release signing and notarization are not contributor tasks.
