//
//  TranscriptionOptions.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation

enum InterfaceLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

enum ChineseOutputScript: String, CaseIterable, Identifiable {
    case traditional
    case simplified

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .traditional: return AppLocalizer.string("繁體")
        case .simplified: return AppLocalizer.string("簡體")
        }
    }
}

enum ChineseOutputConverter {
    static func convert(_ text: String, to script: ChineseOutputScript) -> String {
        let transform = StringTransform(script == .traditional ? "Hans-Hant" : "Hant-Hans")
        return text.applyingTransform(transform, reverse: false) ?? text
    }
}

enum TranscriptionMode: String, CaseIterable {
    case cloud
    case senseVoice

    var localizedDisplayName: String {
        switch self {
        case .cloud: return AppLocalizer.string("雲端（OpenAI）")
        case .senseVoice: return AppLocalizer.string("SenseVoice（離線可用）推薦")
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
        case .automatic: return AppLocalizer.string("自動（推薦）")
        case .gpt4oTranscribe: return "GPT-4o Transcribe"
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe"
        case .whisper1: return "Whisper-1"
        case .custom: return AppLocalizer.string("自訂模型 ID")
        }
    }

    var localizedDescription: String {
        switch self {
        case .automatic: return AppLocalizer.string("目前使用 GPT-4o Transcribe")
        case .gpt4oTranscribe: return AppLocalizer.string("準確度優先，適合中英混合內容")
        case .gpt4oMiniTranscribe: return AppLocalizer.string("較低成本與延遲，適合日常短句")
        case .whisper1: return AppLocalizer.string("相容舊版 OpenAI 語音轉錄")
        case .custom: return AppLocalizer.string("使用你帳號可用的轉錄模型 ID")
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
        case .automatic: return AppLocalizer.string("自動（推薦）")
        case .gpt56Luna: return "GPT-5.6 Luna"
        case .gpt56Terra: return "GPT-5.6 Terra"
        case .gpt56Sol: return "GPT-5.6 Sol"
        case .custom: return AppLocalizer.string("自訂模型 ID")
        }
    }

    var localizedDescription: String {
        switch self {
        case .automatic: return AppLocalizer.string("目前使用 GPT-5.6 Luna，適合日常文字整理")
        case .gpt56Luna: return AppLocalizer.string("速度與費用優先，適合短文字")
        case .gpt56Terra: return AppLocalizer.string("品質、速度與費用的平衡選擇")
        case .gpt56Sol: return AppLocalizer.string("複雜內容與指令遵循品質優先")
        case .custom: return AppLocalizer.string("使用你帳號可用的文字模型 ID")
        }
    }
}
