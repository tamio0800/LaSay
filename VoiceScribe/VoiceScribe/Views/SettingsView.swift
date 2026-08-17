//
//  SettingsView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var apiKey: String = ""
    @State private var hasAPIKey: Bool = false
    @State private var showingAPIKeyInput: Bool = false
    @State private var enableAIPolish: Bool = false
    @State private var customSystemPrompt: String = ""
    @State private var transcriptionMode: TranscriptionMode = .cloud
    @State private var transcriptionLanguage: TranscriptionLanguage = .auto
    @State private var punctuationStyle: PunctuationStyle = .fullWidth
    @State private var showAPIKey: Bool = false
    @State private var isAIPolishAdvancedExpanded: Bool = false
    @State private var showDeleteAPIKeyConfirm: Bool = false
    @State private var isLoadingModel: Bool = false

    private var isUsingCustomPrompt: Bool {
        !customSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let keychainHelper = KeychainHelper.shared
    private let openAIService = OpenAIService.shared
    private let senseVoiceService = SenseVoiceService.shared
    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "設定"))
                .font(.title)
                .fontWeight(.bold)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - 轉錄模式
                        transcriptionSection

                        Divider()

                        // MARK: - 標點符號 (local 模式才顯示)
                        if transcriptionMode == .senseVoice {
                            punctuationSection

                            Divider()
                        }

                        // MARK: - AI 潤飾
                        aiPolishSection

                        Divider()

                        // MARK: - API Key
                        apiKeySection
                            .id("apiKeySection")
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    loadSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !hasAPIKey && transcriptionMode == .cloud {
                            withAnimation {
                                proxy.scrollTo("apiKeySection", anchor: .top)
                            }
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Text(String(localized: "自動儲存（API Key 除外）"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(String(localized: "關閉")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel(String(localized: "關閉設定視窗"))
            }
        }
        .padding(24)
        .frame(minWidth: 500, idealWidth: 500, maxWidth: 500, minHeight: 400, maxHeight: 600)
    }

    // MARK: - Transcription Section

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "語音轉錄"))
                .font(.headline)

            HStack {
                Text(String(localized: "轉錄模式"))
                Spacer()
                Picker("", selection: $transcriptionMode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                        Text(mode.localizedDisplayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: transcriptionMode) { newValue in
                    AppSettings.shared.transcriptionMode = newValue
                    if newValue == .senseVoice, !senseVoiceService.isModelLoaded {
                        isLoadingModel = true
                        senseVoiceService.preloadModel(completion: { _ in isLoadingModel = false })
                    }
                }
            }

            HStack {
                Text(String(localized: "轉錄語言"))
                Spacer()
                Picker("", selection: $transcriptionLanguage) {
                    ForEach(TranscriptionLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: transcriptionLanguage) { newValue in
                    AppSettings.shared.transcriptionLanguage = newValue
                }
            }

            Text(String(localized: "SenseVoice 離線辨識，雲端使用 OpenAI API"))
                .font(.caption)
                .foregroundColor(.secondary)

            if transcriptionMode == .senseVoice && isLoadingModel {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(String(localized: "模型載入中..."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Punctuation Section

    private var punctuationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "標點符號"))
                .font(.headline)

            Picker("", selection: $punctuationStyle) {
                ForEach(PunctuationStyle.allCases, id: \.self) { style in
                    Text(style.localizedDisplayName).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: punctuationStyle) { newValue in
                AppSettings.shared.punctuationStyle = newValue
            }

            Text(punctuationExample)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var punctuationExample: String {
        switch punctuationStyle {
        case .fullWidth: return "範例：Hello，World。This is a test！"
        case .halfWidth: return "範例：Hello,World.This is a test!"
        case .spaces: return "範例：Hello World This is a test"
        }
    }

    // MARK: - AI Polish Section

    private var aiPolishSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "AI 文字潤飾"))
                .font(.headline)

            Toggle(String(localized: "啟用 AI 潤飾（使用 GPT-5-mini）"), isOn: $enableAIPolish)
                .toggleStyle(.checkbox)
                .accessibilityLabel(String(localized: "AI 潤飾開關"))
                .accessibilityHint(String(localized: "點擊以切換"))
                .accessibilityValue(enableAIPolish ? String(localized: "已開啟") : String(localized: "已關閉"))
                .onChange(of: enableAIPolish) { newValue in
                    AppSettings.shared.enableAIPolish = newValue
                }

            Text(String(localized: "移除口語贅字、修正文法、優化句子結構"))
                .font(.caption)
                .foregroundColor(.secondary)

            if enableAIPolish {
                Text(String(localized: "AI 清理：移除贅字、修正文法、保留技術術語"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                DisclosureGroup(String(localized: "進階設定"), isExpanded: $isAIPolishAdvancedExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: String(localized: "目前使用：%@"), isUsingCustomPrompt ? String(localized: "自訂") : String(localized: "預設")))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(String(localized: "你可以在這裡自訂 AI 潤飾的指令"))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(String(localized: "自訂 System Prompt（選填）"))
                            .font(.subheadline)

                        ZStack(alignment: .topLeading) {
                            if !isUsingCustomPrompt {
                                Text(openAIService.getDefaultPromptSummary())
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.top, 8)
                                    .padding(.horizontal, 6)
                            }

                            TextEditor(text: $customSystemPrompt)
                                .frame(minHeight: 120, maxHeight: 180)
                                .font(.system(.body, design: .monospaced))
                                .border(Color.secondary.opacity(0.3))
                                .onChange(of: customSystemPrompt) { newValue in
                                    AppSettings.shared.customSystemPrompt = newValue
                                }
                        }

                        HStack {
                            Button(String(localized: "重設為預設")) {
                                customSystemPrompt = ""
                            }
                            .font(.caption)

                            Spacer()
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "OpenAI API Key"))
                .font(.headline)

            if hasAPIKey && !showingAPIKeyInput {
                HStack {
                    Text(String(localized: "已設定 API Key"))
                        .foregroundColor(.green)

                    if showAPIKey {
                        Text(apiKey)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text("(\(apiKey.prefix(7))...\(apiKey.suffix(4)))")
                            .font(.system(.body, design: .monospaced))
                    }

                    Spacer()

                    Button(showAPIKey ? String(localized: "隱藏") : String(localized: "顯示")) {
                        showAPIKey.toggle()
                    }
                    .font(.caption)
                    .accessibilityLabel(String(localized: "顯示或隱藏 API Key"))

                    Button(String(localized: "更新")) {
                        showingAPIKeyInput = true
                    }
                    .font(.caption)

                    Button(String(localized: "刪除")) {
                        showDeleteAPIKeyConfirm = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .accessibilityLabel(String(localized: "刪除 API Key"))
                }
                .frame(maxWidth: 420)
            } else {
                HStack {
                    if showAPIKey {
                        TextField(String(localized: "請輸入 API Key (sk-...)"), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField(String(localized: "請輸入 API Key (sk-...)"), text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(showAPIKey ? String(localized: "隱藏") : String(localized: "顯示")) {
                        showAPIKey.toggle()
                    }
                    .font(.caption)
                    .accessibilityLabel(String(localized: "顯示或隱藏 API Key"))

                    Button(String(localized: "儲存")) {
                        if !apiKey.isEmpty {
                            let success = keychainHelper.save(key: "openai_api_key", value: apiKey)
                            if success {
                                hasAPIKey = true
                                showingAPIKeyInput = false
                            }
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(String(localized: "儲存 API Key"))

                    if hasAPIKey {
                        Button(String(localized: "取消")) {
                            showingAPIKeyInput = false
                            loadAPIKey()
                        }
                        .font(.caption)
                        .accessibilityLabel(String(localized: "取消"))
                    }
                }
                .frame(maxWidth: 420)
            }

            Text(String(localized: "用於雲端語音轉錄與 AI 文字潤飾"))
                .font(.caption)
                .foregroundColor(.secondary)

            Link(String(localized: "取得 API Key → platform.openai.com"), destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(.caption)
        }
        .alert(
            String(localized: "確定刪除 API Key？"),
            isPresented: $showDeleteAPIKeyConfirm
        ) {
            Button(String(localized: "刪除"), role: .destructive) {
                _ = keychainHelper.delete(key: "openai_api_key")
                apiKey = ""
                hasAPIKey = false
                showingAPIKeyInput = true
                showAPIKey = false
            }
            Button(String(localized: "取消"), role: .cancel) {}
        } message: {
            Text(String(localized: "刪除後，雲端模式和 AI 潤飾將無法使用，直到重新輸入 API Key。"))
        }
    }

    // MARK: - Methods

    func loadSettings() {
        loadAPIKey()

        transcriptionMode = AppSettings.shared.transcriptionMode
        transcriptionLanguage = AppSettings.shared.transcriptionLanguage
        punctuationStyle = AppSettings.shared.punctuationStyle
        enableAIPolish = AppSettings.shared.enableAIPolish
        customSystemPrompt = AppSettings.shared.customSystemPrompt ?? ""
    }

    func loadAPIKey() {
        if let savedAPIKey = keychainHelper.get(key: "openai_api_key"), !savedAPIKey.isEmpty {
            apiKey = savedAPIKey
            hasAPIKey = true
            showingAPIKeyInput = false
        } else {
            apiKey = ""
            hasAPIKey = false
            showingAPIKeyInput = true
        }
    }
}

#Preview {
    SettingsView()
}
