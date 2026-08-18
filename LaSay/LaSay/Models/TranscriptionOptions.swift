//
//  TranscriptionOptions.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

enum TranscriptionMode: String, CaseIterable {
    case cloud
    case senseVoice

    var localizedDisplayName: String {
        switch self {
        case .cloud: return String(localized: "雲端（OpenAI）")
        case .senseVoice: return String(localized: "SenseVoice（離線可用）推薦")
        }
    }

}

enum CloudTranscriptionModel: String, CaseIterable {
    case automatic
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case whisper1 = "whisper-1"
    case custom

    var localizedDisplayName: String {
        switch self {
        case .automatic: return String(localized: "自動（推薦）")
        case .gpt4oTranscribe: return "GPT-4o Transcribe"
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe"
        case .whisper1: return "Whisper-1"
        case .custom: return String(localized: "自訂模型 ID")
        }
    }

    var localizedDescription: String {
        switch self {
        case .automatic: return String(localized: "目前使用 GPT-4o Transcribe")
        case .gpt4oTranscribe: return String(localized: "準確度優先，適合中英混合內容")
        case .gpt4oMiniTranscribe: return String(localized: "較低成本與延遲，適合日常短句")
        case .whisper1: return String(localized: "相容舊版 OpenAI 語音轉錄")
        case .custom: return String(localized: "使用你帳號可用的轉錄模型 ID")
        }
    }
}

enum AIPolishModel: String, CaseIterable {
    case automatic
    case gpt56Luna = "gpt-5.6-luna"
    case gpt56Terra = "gpt-5.6-terra"
    case gpt56Sol = "gpt-5.6-sol"
    case custom

    var localizedDisplayName: String {
        switch self {
        case .automatic: return String(localized: "自動（推薦）")
        case .gpt56Luna: return "GPT-5.6 Luna"
        case .gpt56Terra: return "GPT-5.6 Terra"
        case .gpt56Sol: return "GPT-5.6 Sol"
        case .custom: return String(localized: "自訂模型 ID")
        }
    }

    var localizedDescription: String {
        switch self {
        case .automatic: return String(localized: "目前使用 GPT-5.6 Luna，適合日常文字整理")
        case .gpt56Luna: return String(localized: "速度與費用優先，適合短文字")
        case .gpt56Terra: return String(localized: "品質、速度與費用的平衡選擇")
        case .gpt56Sol: return String(localized: "複雜內容與指令遵循品質優先")
        case .custom: return String(localized: "使用你帳號可用的文字模型 ID")
        }
    }
}

enum TranscriptionLanguage: String, CaseIterable {
    case auto
    case zh
    case en
    case ja
    case ko

    var displayName: String {
        switch self {
        case .auto: return String(localized: "自動偵測")
        case .zh: return String(localized: "繁體中文")
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    var languageCode: String? {
        switch self {
        case .auto: return nil
        default: return rawValue
        }
    }
}

enum PunctuationStyle: String, CaseIterable {
    case fullWidth
    case halfWidth
    case spaces
    
    var localizedDisplayName: String {
        switch self {
        case .fullWidth: return String(localized: "全形")
        case .halfWidth: return String(localized: "半形")
        case .spaces: return String(localized: "空格")
        }
    }
}
