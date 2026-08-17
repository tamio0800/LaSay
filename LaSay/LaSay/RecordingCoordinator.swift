//
//  RecordingCoordinator.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Cocoa
import SwiftUI
import UserNotifications
import AVFoundation
import os.log

final class RecordingCoordinator {
    private let appState = AppState.shared
    private let audioRecorder = AudioRecorder.shared
    private let cloudService = WhisperService.shared
    private let senseVoiceService = SenseVoiceService.shared
    private let openAIService = OpenAIService.shared
    private let textInputService = TextInputService.shared
    private let hotkeyManager = HotkeyManager.shared
    private var processingTimer: Timer?
    
    func start() {
        requestNotificationPermission()
        setupAudioRecorderCallbacks()
        setupGlobalHotkey()
    }

    // MARK: - Notification Permission

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func showNotification(title: String, body: String, isError: Bool = false) {
        DispatchQueue.main.async {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = isError ? .defaultCritical : .default

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    // MARK: - Global Hotkey

    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onHotkeyReleased = { [weak self] in
            self?.stopRecording()
        }

        if hotkeyManager.checkAccessibilityPermission() {
            hotkeyManager.startMonitoring()
        }
    }

    private func startRecording() {
        AppLogger.recording.info("RecordingCoordinator: recording started")
        appState.updateStatus(.recording)
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        AppLogger.recording.info("RecordingCoordinator: recording stopped")
        audioRecorder.stopRecording()
        appState.updateStatus(.processing)

        guard let audioURL = audioRecorder.getLastRecordingURL() else {
            AppLogger.recording.error("RecordingCoordinator: no audio URL available after stop")
            appState.updateStatus(.idle)
            hotkeyManager.restartMonitoring()
            return
        }

        // 空錄音保護：音訊長度小於 0.5 秒視為錄音太短
        let asset = AVURLAsset(url: audioURL)
        let duration = asset.durationSeconds
        if duration < 0.5 {
            AppLogger.recording.info("Recording too short: \(duration, privacy: .public)s, deleting")
            try? FileManager.default.removeItem(at: audioURL)
            showNotification(title: String(localized: "錄音太短"), body: String(localized: "請按住 Fn+Space 說話，放開後自動辨識"))
            appState.updateStatus(.idle)
            hotkeyManager.restartMonitoring()
            return
        }

        // Start processing timeout timer (60 seconds)
        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            AppLogger.transcription.error("RecordingCoordinator: processing timeout reached")
            DispatchQueue.main.async {
                self.showNotification(
                    title: String(localized: "語音轉錄失敗"),
                    body: String(localized: "處理逾時。請重試。"),
                    isError: true
                )
                self.appState.updateStatus(.idle)
                self.hotkeyManager.restartMonitoring()
                self.audioRecorder.deleteRecording(at: audioURL)
            }
        }

        let selectedMode = AppSettings.shared.transcriptionMode
        let selectedLanguage = AppSettings.shared.transcriptionLanguage
        let languageCode = selectedLanguage.languageCode

        if selectedMode == .cloud {
            guard KeychainHelper.shared.get(key: "openai_api_key")?.isEmpty == false else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.processingTimer?.invalidate()
                    self.processingTimer = nil
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                    self.showNotification(
                        title: String(localized: "需要 API Key"),
                        body: String(localized: "請在設定中輸入 OpenAI API Key 以使用雲端模式"),
                        isError: true
                    )
                    self.appState.updateStatus(.idle)
                    self.hotkeyManager.restartMonitoring()
                    self.audioRecorder.deleteRecording(at: audioURL)
                }
                return
            }
        }

        AppLogger.transcription.info("RecordingCoordinator: starting transcription (mode=\(selectedMode.rawValue, privacy: .public))")

        let transcriptionHandler: (Result<String, WhisperError>) -> Void = { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                switch result {
                case .success(let rawText):
                    AppLogger.transcription.info("RecordingCoordinator: transcription succeeded")
                    let transcribedText = self.convertToTraditionalChinese(rawText)
                    let enableAIPolish = AppSettings.shared.enableAIPolish

                    // Delete recording immediately — text is already in memory
                    self.audioRecorder.deleteRecording(at: audioURL)

                    if enableAIPolish {
                        guard KeychainHelper.shared.get(key: "openai_api_key")?.isEmpty == false else {
                            self.processFinalText(transcribedText)
                            return
                        }

                        AppLogger.transcription.info("RecordingCoordinator: AI Polish started")
                        let customPrompt = AppSettings.shared.customSystemPrompt
                        // Cloud 模式固定全形標點，不額外加指令拖慢 AI Polish
                        let puncStyle: PunctuationStyle = (selectedMode == .cloud) ? .fullWidth : AppSettings.shared.punctuationStyle

                        self.polishTextWithRetry(transcribedText, customPrompt: customPrompt, punctuationStyle: puncStyle) { [weak self] finalText in
                            self?.processFinalText(finalText)
                        }
                    } else {
                        self.processFinalText(transcribedText)
                    }

                case .failure(let error):
                    AppLogger.transcription.error("RecordingCoordinator: transcription failed - \(error.localizedDescription, privacy: .public)")
                    self.processingTimer?.invalidate()
                    self.processingTimer = nil

                    self.showNotification(
                        title: String(localized: "語音轉錄失敗"),
                        body: error.localizedDescription,
                        isError: true
                    )
                    
                    self.audioRecorder.deleteRecording(at: audioURL)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.hotkeyManager.restartMonitoring()
                    }
                    self.appState.updateStatus(.idle)
                }
            }
        }

        switch selectedMode {
        case .senseVoice:
            senseVoiceService.transcribe(
                audioFileURL: audioURL,
                completion: transcriptionHandler
            )
        case .cloud:
            cloudService.transcribe(audioFileURL: audioURL, language: languageCode, completion: transcriptionHandler)
        }
    }

    // MARK: - Text Processing
    
    private func convertToTraditionalChinese(_ text: String) -> String {
        return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
    }

    private func processFinalText(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.processingTimer?.invalidate()
            self.processingTimer = nil
            
            let correctedText: String = {
                // TechTermsDictionary only for offline mode — AI Polish handles this contextually
                let enableAIPolish = AppSettings.shared.enableAIPolish
                let techCorrected = enableAIPolish ? text : TechTermsDictionary.apply(to: text)
                let style = AppSettings.shared.punctuationStyle
                return PunctuationConverter.convert(techCorrected, to: style)
            }()
            self.textInputService.pasteText(correctedText, restoreClipboard: AppSettings.shared.restoreClipboard)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.hotkeyManager.restartMonitoring()
            }
            self.appState.updateStatus(.idle)
        }
    }

    private func polishTextWithRetry(
        _ text: String,
        customPrompt: String?,
        punctuationStyle: PunctuationStyle,
        maxRetries: Int = 1,
        attempt: Int = 0,
        completion: @escaping (String) -> Void
    ) {
        openAIService.polishText(text, customPrompt: customPrompt, punctuationStyle: punctuationStyle) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let polished):
                    AppLogger.transcription.info("AI Polish succeeded (attempt \(attempt + 1))")
                    completion(polished)
                case .failure(let error):
                    if attempt < maxRetries {
                        AppLogger.transcription.warning("AI Polish retry \(attempt + 1)/\(maxRetries): \(error.localizedDescription)")
                        self.polishTextWithRetry(text, customPrompt: customPrompt, punctuationStyle: punctuationStyle, maxRetries: maxRetries, attempt: attempt + 1, completion: completion)
                    } else {
                        AppLogger.transcription.error("AI Polish failed after \(maxRetries + 1) attempts: \(error.localizedDescription)")
                        self.showNotification(
                            title: String(localized: "AI 潤飾失敗"),
                            body: String(localized: "已使用原始轉錄文字：") + error.localizedDescription,
                            isError: false
                        )
                        completion(text) // fallback to original
                    }
                }
            }
        }
    }

    private func setupAudioRecorderCallbacks() {
        audioRecorder.onRecordingComplete = { [weak self] url in
            guard let _ = url else {
                self?.appState.updateStatus(.idle)
                return
            }
        }

        audioRecorder.onError = { [weak self] error in
            guard let self = self else { return }
            AppLogger.recording.error("AudioRecorder error: \(error.localizedDescription, privacy: .public)")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.processingTimer?.invalidate()
                self.processingTimer = nil
                self.showNotification(
                    title: String(localized: "語音轉錄失敗"),
                    body: error.localizedDescription,
                    isError: true
                )
                self.appState.updateStatus(.idle)
                self.hotkeyManager.restartMonitoring()
            }
        }
    }

}

private extension AVURLAsset {
    var durationSeconds: Double {
        if let audioFile = try? AVAudioFile(forReading: url) {
            return Double(audioFile.length) / audioFile.fileFormat.sampleRate
        }
        return 0
    }
}
