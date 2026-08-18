# LaSay

Homebrew 安裝：`brew install --cask tamio0800/tap/lasay`

給開發者的語音輸入工具。用母語口述，夾雜英文技術術語 -- LaSay 原封不動保留。

[English](README.md)

<p align="center"><img src="lasay-icon.png" width="128" alt="LaSay 圖示"></p>

[![CI](https://github.com/tamio0800/LaSay/actions/workflows/ci.yml/badge.svg)](https://github.com/tamio0800/LaSay/actions/workflows/ci.yml)

## 為什麼需要 LaSay

開發者用混合語言思考。你用中文說「幫我 refactor 那個 useEffect hook」，所有語音工具都會把 useEffect 轉成亂碼。LaSay 內建 300+ 技術術語字典加上 AI 後處理，框架名稱、程式碼識別字、技術用語全部原樣保留。

**按住 Fn+Space，說話，放開，文字出現在游標。**

任何 app 都能用 -- VS Code、Terminal、Slack、瀏覽器，任何有輸入框的地方。

首次啟動時，依提示授予麥克風與輔助使用權限。預設按住 Fn+Space 口述；從選單列圖示開啟設定，簽章版本可自動檢查更新。

## 功能

- **混語言轉錄** -- 母語 + 英文技術術語混著說
- **300+ 術語保留** -- React、FastAPI、Kubernetes、camelCase 識別字全部保留
- **雙轉錄模式** -- 雲端（OpenAI，可選模型）或本地（SenseVoice，完全離線）
- **AI 文字清理** -- 去贅字、修文法、保留術語，可選擇 OpenAI 模型
- **可調整按住說話快捷鍵** -- 預設 Fn+Space，也可選 Control+Space 或 Option+Space
- **即時貼上** -- 轉錄完成的瞬間，文字出現在游標位置
- **安全儲存** -- API Key 存在 macOS Keychain

## 快速開始

```
1. brew install --cask tamio0800/tap/lasay
2. 開啟 LaSay，授予麥克風 + 輔助使用權限
3. 在任何地方按住 Fn+Space 開始口述
4. 選用：從選單列圖示設定 OpenAI 或更改快捷鍵
```

不用註冊。不用登入。不用雲端同步。你的 API Key，你的資料。

![LaSay 首次啟動權限設定](docs/screenshots/onboarding.png)

## 架構

```
Fn+Space（按住）
    │
    ▼
AudioRecorder（16kHz mono AAC）
    │
    ├─► 雲端：OpenAI 轉錄 API ─────► 轉錄
    │
    └─► 本地：SenseVoice ──────────► 轉錄
                                       │
                                       ▼
                                TechTermsDictionary
                                （300+ regex 術語修正）
                                       │
                                       ▼
                                AI 清理（選配）
                                可選 OpenAI 模型
                                       │
                                       ▼
                                自動貼上至游標
```

## 轉錄模式比較

| 模式 | 引擎 | 延遲 | 費用 | 離線 |
|------|------|------|------|------|
| 雲端 | OpenAI 轉錄 API | 依模型而異 | 依模型而異 | 否 |
| 本地 | SenseVoiceSmall (int8) | ~2-4 秒 | 免費 | 是 |

SenseVoiceSmall 模型已內建於 App，本地模式不需要另外下載。

## 設定

### 權限

LaSay 需要兩個 macOS 權限：

- **麥克風** -- 系統設定 > 隱私權與安全性 > 麥克風
- **輔助使用** -- 系統設定 > 隱私權與安全性 > 輔助使用（全域快捷鍵需要）

首次設定各授予一次即可；LaSay 會立即啟用快捷鍵，不需要重新啟動。

### 設定選項

從 menu bar 圖示 > 設定進入：

- **轉錄模式** -- 雲端或本地
- **OpenAI 模型** -- 推薦設定、指定模型或自訂 Model ID
- **轉錄語言** -- 自動 / 中文 / 英文 / 日文 / 韓文
- **AI 文字清理** -- 開關切換，支援自訂 prompt
- **API Key** -- 雲端模式和 AI 清理需要

### API Key

雲端模式和 AI 文字清理需要 API Key。從 [platform.openai.com/api-keys](https://platform.openai.com/api-keys) 取得。

存在 macOS Keychain，不是 UserDefaults，不是明文檔案。

## 費用

雲端轉錄與 AI 文字清理的費用取決於所選 OpenAI 模型；本地模式免費。請在設定中依準確度、速度與費用選擇模型。

## 支援語言

轉錄：自動偵測、中文（zh）、英文（en）、日文（ja）、韓文（ko）

介面：繁體中文、English

## 常見問題

**快捷鍵沒反應？**
開啟 LaSay 並依照權限設定操作；授予輔助使用權限後，快捷鍵會立即生效。

**Terminal 能用嗎？**
可以，透過模擬 Cmd+V 貼上。部分終端模擬器可能需要額外設定。

**術語修正準確嗎？**
字典涵蓋 300+ 術語，橫跨主要程式語言（Python、JavaScript、TypeScript、Swift、Rust、Java、C/C++/C#）、框架（React、FastAPI、Django、Spring）、資料庫（PostgreSQL、MongoDB、Redis）、DevOps 工具（Docker、Kubernetes、Terraform）及常見縮寫（API、SDK、CI/CD、ORM）。

**不用 API Key 能用嗎？**
可以。切換到本地模式，SenseVoice 完全在你的電腦上執行。AI 文字清理需要 API Key。

**API Key 存在哪？**
macOS Keychain（透過 Security framework）。不在 UserDefaults，不在明文檔案。

## 系統需求

- macOS 13.5（Ventura）或更新
- Apple Silicon Mac
- 網路連線（僅雲端模式）
- OpenAI API Key（雲端模式和 AI 清理）

## 從原始碼建置

```bash
git clone https://github.com/tamio0800/LaSay.git
cd LaSay/LaSay
open LaSay.xcodeproj
```

請在 Xcode 選擇 Apple Development signing team。不要使用 ad-hoc 簽章，否則每次 rebuild 後 App 身分會改變，macOS 可能要求重新授予隱私權限。

## 授權

LaSay 原始碼採 [MIT License](LICENSE)；內建模型與第三方元件各自適用其授權。完整來源、版本與聲明請見 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

---

[Tamio Tsiu](mailto:tamio.tsiu@gmail.com)
