//
//  AppSettings.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/20.
//

import Foundation
import ServiceManagement
import os.log

extension Notification.Name {
    static let hotkeyPresetDidChange = Notification.Name("HotkeyPresetDidChange")
}

/// Centralized UserDefaults wrapper for app-wide settings.
/// All UserDefaults access should go through this singleton.
/// Thread-safety: @MainActor ensures main-thread-only access.
@MainActor
final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    nonisolated private static let cloudTranscriptionModelKey = "cloud_transcription_model"
    nonisolated private static let customCloudTranscriptionModelIDKey = "custom_cloud_transcription_model_id"
    nonisolated private static let aiPolishModelKey = "ai_polish_model"
    nonisolated private static let customAIPolishModelIDKey = "custom_ai_polish_model_id"
    nonisolated private static let hotkeyPresetKey = "hotkey_preset"

    private init() {}

    var transcriptionMode: TranscriptionMode {
        get { defaults.string(forKey: "transcription_mode").flatMap(TranscriptionMode.init(rawValue:)) ?? .senseVoice }
        set { defaults.set(newValue.rawValue, forKey: "transcription_mode") }
    }

    var transcriptionLanguage: TranscriptionLanguage {
        get {
            guard let raw = defaults.string(forKey: "transcription_language"),
                  let lang = TranscriptionLanguage(rawValue: raw) else { return .auto }
            return lang
        }
        set { defaults.set(newValue.rawValue, forKey: "transcription_language") }
    }

    var cloudTranscriptionModel: CloudTranscriptionModel {
        get {
            guard let raw = defaults.string(forKey: Self.cloudTranscriptionModelKey),
                  let model = CloudTranscriptionModel(rawValue: raw) else { return .automatic }
            return model
        }
        set { defaults.set(newValue.rawValue, forKey: Self.cloudTranscriptionModelKey) }
    }

    var customCloudTranscriptionModelID: String? {
        get { defaults.string(forKey: Self.customCloudTranscriptionModelIDKey) }
        set { defaults.set(newValue, forKey: Self.customCloudTranscriptionModelIDKey) }
    }

    var aiPolishModel: AIPolishModel {
        get {
            guard let raw = defaults.string(forKey: Self.aiPolishModelKey),
                  let model = AIPolishModel(rawValue: raw) else { return .automatic }
            return model
        }
        set { defaults.set(newValue.rawValue, forKey: Self.aiPolishModelKey) }
    }

    var customAIPolishModelID: String? {
        get { defaults.string(forKey: Self.customAIPolishModelIDKey) }
        set { defaults.set(newValue, forKey: Self.customAIPolishModelIDKey) }
    }

    var hotkeyPreset: HotkeyPreset {
        get {
            guard let raw = defaults.string(forKey: Self.hotkeyPresetKey),
                  let preset = HotkeyPreset(rawValue: raw) else { return .fnSpace }
            return preset
        }
        set {
            defaults.set(newValue.rawValue, forKey: Self.hotkeyPresetKey)
            NotificationCenter.default.post(name: .hotkeyPresetDidChange, object: newValue)
        }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            _ = setLaunchAtLogin(newValue)
        }
    }

    @discardableResult
    func setLaunchAtLogin(_ enabled: Bool) -> Bool {
        let service = SMAppService.mainApp
        do {
            if enabled {
                switch service.status {
                case .enabled:
                    return true
                case .notRegistered, .notFound:
                    try service.register()
                case .requiresApproval:
                    SMAppService.openSystemSettingsLoginItems()
                    return false
                @unknown default:
                    return false
                }

                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
                return service.status == .enabled
            }

            // Unregistering an unknown service can throw and is unnecessary.
            guard service.status != .notRegistered, service.status != .notFound else { return true }
            try service.unregister()
            return true
        } catch {
            AppLogger.general.error("Launch at login update failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    nonisolated static func cloudTranscriptionModelID() -> String {
        modelID(
            selectionKey: cloudTranscriptionModelKey,
            customKey: customCloudTranscriptionModelIDKey,
            defaultModel: CloudTranscriptionModel.gpt4oTranscribe.rawValue
        )
    }

    nonisolated static func aiPolishModelID() -> String {
        modelID(
            selectionKey: aiPolishModelKey,
            customKey: customAIPolishModelIDKey,
            defaultModel: AIPolishModel.gpt56Luna.rawValue
        )
    }

    private nonisolated static func modelID(selectionKey: String, customKey: String, defaultModel: String) -> String {
        let defaults = UserDefaults.standard
        guard let selection = defaults.string(forKey: selectionKey) else { return defaultModel }
        if selection == "automatic" { return defaultModel }
        if selection == "custom" {
            let customID = defaults.string(forKey: customKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let customID, !customID.isEmpty else { return defaultModel }
            return customID
        }
        return selection
    }

    var punctuationStyle: PunctuationStyle {
        get {
            guard let raw = defaults.string(forKey: "punctuation_style"),
                  let style = PunctuationStyle(rawValue: raw) else { return .fullWidth }
            return style
        }
        set { defaults.set(newValue.rawValue, forKey: "punctuation_style") }
    }

    var enableAIPolish: Bool {
        get { defaults.bool(forKey: "enable_ai_polish") }
        set { defaults.set(newValue, forKey: "enable_ai_polish") }
    }

    var customSystemPrompt: String? {
        get { defaults.string(forKey: "custom_system_prompt") }
        set { defaults.set(newValue, forKey: "custom_system_prompt") }
    }

    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: "has_launched_before") }
        set { defaults.set(newValue, forKey: "has_launched_before") }
    }

    var restoreClipboard: Bool {
        get { defaults.object(forKey: "restore_clipboard") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "restore_clipboard") }
    }

    // MARK: - Helper Methods

    /// Set default transcription mode to senseVoice if not already configured
    func setDefaultTranscriptionModeIfNeeded() {
        guard defaults.string(forKey: "transcription_mode") == nil else { return }
        transcriptionMode = .senseVoice
    }
}
