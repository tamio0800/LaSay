# 貢獻 LaSay

感謝你協助改善 LaSay。較大的改動請先開 issue，讓使用者問題與範圍先被確認。

English: [CONTRIBUTING.md](CONTRIBUTING.md)

## 快速開始

1. Fork 此 repo，建立單一目的的分支，例如 `fix/accessibility-setup`。
2. 用 Xcode 開啟 `LaSay/LaSay.xcodeproj`，並選擇自己的 Apple Development signing team。
3. 開 Pull Request 前，先建置與測試：

   ```bash
   xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay -configuration Debug build
   xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay test
   ```

請遵循 [AGENTS.md](AGENTS.md) 的 Swift 慣例。改動保持聚焦；行為有改變時加一個針對性的 XCTest regression test；介面文字要同步維護英文與繁體中文。

## Pull Request

Commit 標題使用短的 Conventional Commit，例如 `fix: restore direct-input setup`。PR 要說明使用者看得到的改變、做過的驗證與相關 issue。選單列、初始設定、設定頁或其他 UI 改動請附截圖。

不要提交 API Key、憑證、模型下載檔、建置產物、DMG、log 或 Xcode 使用者資料。不要執行維護者的簽章、notarization 或 release 流程。提交的貢獻採用此 repo 的 MIT 授權。
