# LaSay

<p align="center"><img src="lasay-icon.png" width="112" alt="LaSay 圖示"></p>

<p align="center">給開發者的 macOS 語音輸入工具。</p>

按住快捷鍵，用中文、英文或中英混合自然說話，再放開。LaSay 會將語音轉成文字，直接輸入到目前的文字欄位，並保留 `React`、`FastAPI` 等技術術語；同時也會保留一份複本作為備援。

<p align="center"><img src="docs/assets/lasay-demo.gif" width="535" alt="LaSay 語音輸入示範"></p>

[English](README.md) · [AI Agent 指南](AGENT_GUIDE.md) · [參與貢獻](CONTRIBUTING_ZH.md) · [下載最新版 DMG](https://github.com/tamio0800/LaSay/releases/latest)

## 安裝

把這行指令貼到「終端機」。它會加入 LaSay 的 Homebrew 軟體來源，並安裝 App。

```bash
brew tap tamio0800/tap && brew install --cask lasay
```

不使用 Homebrew？從 [GitHub Releases](https://github.com/tamio0800/LaSay/releases/latest) 下載 DMG，再把 LaSay 拖到「應用程式」。

### 更新

透過 Homebrew 安裝時，先結束 LaSay，再使用這行更新：

```bash
brew upgrade --cask lasay
```

透過 DMG 安裝時，在 LaSay 設定按 **檢查更新…**。請依照原本的安裝方式更新；Homebrew 安裝就使用 Homebrew。正常的簽章更新會保留麥克風與輔助使用權限。

## 第一次啟動與日常使用

第一次啟動時，LaSay 會帶你完成兩個只需授予一次的權限：

1. **麥克風**：讓 LaSay 聽見你的聲音。
2. **輔助使用**：讓 LaSay 將結果輸入到目前的文字欄位。

macOS 會請你確認每個權限；如果先前曾拒絕，LaSay 會開啟正確的系統設定頁面。LaSay 會自動確認權限，接著請你在真正的測試文字欄位按住快捷鍵並說一句話；只有看到文字出現，設定才算完成。

設定完成後：

1. 在任何可輸入文字的地方按住 **Fn + Space**。可在設定改為 Control + Space 或 Option + Space。
2. 自然說話後放開快捷鍵，LaSay 會直接把結果輸入到游標位置。
3. 如果自動輸入無法使用或失敗，結果仍會留在剪貼簿；按 **Command + V** 即可手動貼上。

## 選擇辨識位置

| 模式 | 會發生什麼事 | API Key | 費用 |
| --- | --- | --- | --- |
| **本機（預設）** | 內建的 SenseVoiceSmall 模型在你的 Mac 處理錄音。 | 不需要 | 免費 |
| **OpenAI 雲端** | LaSay 會把錄音傳送到 OpenAI 進行辨識。 | 需要 | 取決於你選的模型 |

LaSay 不需要 LaSay 帳號，也不會同步你的內容。OpenAI API Key 會儲存在 macOS Keychain。若開啟選用的 OpenAI 文字整理，辨識後的文字也會傳送到 OpenAI。

關閉 AI 文字潤飾時，LaSay 會套用內建的技術術語修正；開啟時則由所選模型依上下文保留術語。

## 你會得到什麼

- 在 VS Code、Terminal、Slack、瀏覽器與其他文字欄位按住說話
- 英文、繁體中文、日文、韓文，以及自動偵測語言
- 內建技術術語修正，協助保留框架名稱、程式碼識別字與常見縮寫
- 選用的 OpenAI 辨識、文字整理與自訂模型 ID
- 簡潔的選單列 App，支援登入後啟動與自訂快捷鍵

## 系統需求

- Apple Silicon Mac
- macOS 13.5（Ventura）或更新版本
- 只有 OpenAI 功能需要網路與 OpenAI API Key

## 從原始碼建置

```bash
git clone https://github.com/tamio0800/LaSay.git
cd LaSay
open LaSay/LaSay.xcodeproj
```

在 Xcode 選擇自己的 Apple Development signing team，接著按 **Command + B** 建置。Xcode 會自動處理專案包含的相依項目。

## 授權

LaSay 原始碼採 [MIT License](LICENSE)。內建模型與原生 runtime 各自適用其授權；完整聲明請見 [Third-Party Notices](THIRD_PARTY_NOTICES.md)。
