import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var transcriptionMode: TranscriptionMode = .senseVoice
    @State private var interfaceLanguage = AppLocalizer.language
    @State private var chineseOutputScript: ChineseOutputScript = .traditional
    @State private var hotkeyPreset: HotkeyPreset = .fnSpace
    @State private var launchAtLogin = false
    @State private var loginNeedsAttention = false
    @State private var enableAIPolish = false
    @State private var restoreClipboard = false
    @State private var cloudTranscriptionModel: CloudTranscriptionModel = .automatic
    @State private var customCloudTranscriptionModelID = ""
    @State private var aiPolishModel: AIPolishModel = .automatic
    @State private var customAIPolishModelID = ""
    @State private var customSystemPrompt = ""
    @State private var isAdvancedExpanded = false
    @State private var isLoadingModel = false
    @State private var apiKey = ""
    @State private var hasAPIKey = false
    @State private var editingAPIKey = false
    @State private var showAPIKey = false
    @State private var showDeleteAPIKeyConfirm = false
    @State private var accessibilityGranted = false
    @State private var didRequestAccessibilityPermission = false
    @State private var accessibilityPermissionTimer: Timer?

    private let keychain = KeychainHelper.shared
    private let senseVoice = SenseVoiceService.shared

    private var needsAPIKey: Bool { transcriptionMode == .cloud || enableAIPolish }
    private var hasCustomPrompt: Bool {
        !customSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var interfaceLanguageBinding: Binding<InterfaceLanguage> {
        Binding(
            get: { interfaceLanguage },
            set: { language in
                AppLocalizer.language = language
                interfaceLanguage = language
            }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("LaSay").font(.title2.weight(.semibold))
                    Text(String(format: AppLocalizer.string("按住 %@ 說話，放開後自動輸入"), hotkeyPreset.displayName))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    generalSection

                    Divider()

                    polishSection

                    if needsAPIKey {
                        Divider()
                        apiKeySection
                    }

                    Divider()

                    DisclosureGroup(AppLocalizer.string("進階設定"), isExpanded: $isAdvancedExpanded) {
                        advancedSection.padding(.top, 12)
                    }
                }
                .padding(.horizontal, 2)
            }

            Divider()

            HStack {
                Button(AppLocalizer.string("檢查更新...")) {
                    NotificationCenter.default.post(name: NSNotification.Name("CheckForUpdates"), object: nil)
                }
                Spacer()
                Button(AppLocalizer.string("結束 LaSay"), role: .destructive) {
                    NotificationCenter.default.post(name: NSNotification.Name("QuitApp"), object: nil)
                }
                Button(AppLocalizer.string("關閉")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 520, height: 580)
        .id(interfaceLanguage)
        .onAppear(perform: loadSettings)
        .onDisappear { stopAccessibilityPermissionPolling() }
        .onReceive(NotificationCenter.default.publisher(for: .interfaceLanguageDidChange)) { _ in
            interfaceLanguage = AppLocalizer.language
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
            let actual = AppSettings.shared.launchAtLogin
            launchAtLogin = actual
            if actual { loginNeedsAttention = false }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalizer.string("一般")).font(.headline)

            HStack {
                Text(AppLocalizer.string("介面語言"))
                Spacer()
                Picker("", selection: interfaceLanguageBinding) {
                    ForEach(InterfaceLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 250, alignment: .trailing)
            }

            HStack {
                Text(AppLocalizer.string("辨識方式"))
                Spacer()
                Picker("", selection: $transcriptionMode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { Text($0.localizedDisplayName).tag($0) }
                }
                .labelsHidden()
                .frame(width: 250, alignment: .trailing)
                .onChange(of: transcriptionMode) { mode in
                    AppSettings.shared.transcriptionMode = mode
                    if mode == .senseVoice, !senseVoice.isModelLoaded {
                        isLoadingModel = true
                        senseVoice.preloadModel { _ in isLoadingModel = false }
                    }
                }
            }

            HStack {
                Text(AppLocalizer.string("中文輸出"))
                Spacer()
                Picker("", selection: $chineseOutputScript) {
                    ForEach(ChineseOutputScript.allCases) { script in
                        Text(script.displayName).tag(script)
                    }
                }
                .labelsHidden()
                .frame(width: 250, alignment: .trailing)
                .onChange(of: chineseOutputScript) { AppSettings.shared.chineseOutputScript = $0 }
            }

            HStack {
                Text(AppLocalizer.string("按住說話快捷鍵"))
                Spacer()
                Picker("", selection: $hotkeyPreset) {
                    ForEach(HotkeyPreset.allCases) { Text($0.displayName).tag($0) }
                }
                .labelsHidden()
                .frame(width: 250, alignment: .trailing)
                .onChange(of: hotkeyPreset) { AppSettings.shared.hotkeyPreset = $0 }
            }

            Toggle(
                AppLocalizer.string("登入後自動啟動 LaSay"),
                isOn: Binding(
                    get: { launchAtLogin },
                    set: { requested in
                        _ = AppSettings.shared.setLaunchAtLogin(requested)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let actual = AppSettings.shared.launchAtLogin
                            loginNeedsAttention = actual != requested
                            launchAtLogin = actual
                        }
                    }
                )
            )

            if loginNeedsAttention {
                Button(AppLocalizer.string("在系統設定確認登入項目")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption)
            }

            if isLoadingModel {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(AppLocalizer.string("模型載入中...")).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var polishSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(AppLocalizer.string("自動整理口語文字"), isOn: $enableAIPolish)
                .font(.headline)
                .onChange(of: enableAIPolish) { AppSettings.shared.enableAIPolish = $0 }
            Text(AppLocalizer.string("移除贅字、修正文法並保留技術術語（使用 OpenAI）"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(
                        accessibilityGranted ? AppLocalizer.string("已啟用直接輸入") : AppLocalizer.string("直接輸入需要權限"),
                        systemImage: accessibilityGranted ? "checkmark.circle.fill" : "keyboard"
                    )
                    .foregroundStyle(accessibilityGranted ? .green : .secondary)
                    Spacer()
                    if !accessibilityGranted {
                        Button(
                            didRequestAccessibilityPermission
                                ? AppLocalizer.string("開啟輔助使用設定")
                                : AppLocalizer.string("允許輔助使用")
                        ) {
                            startAccessibilityPermissionPolling()
                            if didRequestAccessibilityPermission {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            } else {
                                didRequestAccessibilityPermission = true
                                HotkeyManager.shared.requestAccessibilityPermission()
                            }
                        }
                    }
                }
                Text(AppLocalizer.string("先允許 LaSay；若提示未出現，再開啟輔助使用設定。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(AppLocalizer.string("LaSay 預設會直接輸入到游標；若自動輸入失敗，結果仍會留在剪貼簿。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if transcriptionMode == .cloud {
                modelPicker(
                    title: AppLocalizer.string("轉錄模型"),
                    selection: $cloudTranscriptionModel,
                    customID: $customCloudTranscriptionModelID
                )
            }

            if enableAIPolish {
                polishModelPicker

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(AppLocalizer.string("自訂 System Prompt（選填）"))
                        Spacer()
                        if hasCustomPrompt {
                            Button(AppLocalizer.string("重設為預設")) { customSystemPrompt = "" }
                                .font(.caption)
                        }
                    }
                    TextEditor(text: $customSystemPrompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
                        .onChange(of: customSystemPrompt) { AppSettings.shared.customSystemPrompt = $0 }
                }
            }

            Toggle(AppLocalizer.string("輸入後還原原本的剪貼簿"), isOn: $restoreClipboard)
                .onChange(of: restoreClipboard) { AppSettings.shared.restoreClipboard = $0 }

        }
    }

    private func modelPicker(
        title: String,
        selection: Binding<CloudTranscriptionModel>,
        customID: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Picker("", selection: selection) {
                    ForEach(CloudTranscriptionModel.allCases, id: \.self) { Text($0.localizedDisplayName).tag($0) }
                }
                .labelsHidden()
                .onChange(of: selection.wrappedValue) { AppSettings.shared.cloudTranscriptionModel = $0 }
            }
            Text(selection.wrappedValue.localizedDescription).font(.caption).foregroundStyle(.secondary)
            if selection.wrappedValue == .custom {
                TextField(AppLocalizer.string("輸入轉錄模型 ID"), text: customID)
                    .onChange(of: customID.wrappedValue) { AppSettings.shared.customCloudTranscriptionModelID = $0 }
            }
        }
    }

    private var polishModelPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(AppLocalizer.string("潤飾模型"))
                Spacer()
                Picker("", selection: $aiPolishModel) {
                    ForEach(AIPolishModel.allCases, id: \.self) { Text($0.localizedDisplayName).tag($0) }
                }
                .labelsHidden()
                .onChange(of: aiPolishModel) { AppSettings.shared.aiPolishModel = $0 }
            }
            Text(aiPolishModel.localizedDescription).font(.caption).foregroundStyle(.secondary)
            if aiPolishModel == .custom {
                TextField(AppLocalizer.string("輸入文字模型 ID"), text: $customAIPolishModelID)
                    .onChange(of: customAIPolishModelID) { AppSettings.shared.customAIPolishModelID = $0 }
            }
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalizer.string("OpenAI API Key")).font(.headline)

            if hasAPIKey && !editingAPIKey {
                HStack {
                    Label(AppLocalizer.string("已設定 API Key"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button(AppLocalizer.string("更新")) { editingAPIKey = true }
                    Button(AppLocalizer.string("刪除"), role: .destructive) { showDeleteAPIKeyConfirm = true }
                }
            } else {
                HStack {
                    Group {
                        if showAPIKey {
                            TextField(AppLocalizer.string("請輸入 API Key (sk-...)"), text: $apiKey)
                        } else {
                            SecureField(AppLocalizer.string("請輸入 API Key (sk-...)"), text: $apiKey)
                        }
                    }
                    Button(showAPIKey ? AppLocalizer.string("隱藏") : AppLocalizer.string("顯示")) { showAPIKey.toggle() }
                    Button(AppLocalizer.string("儲存")) { saveAPIKey() }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Link(AppLocalizer.string("取得 API Key → platform.openai.com"), destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(.caption)
        }
        .alert(AppLocalizer.string("確定刪除 API Key？"), isPresented: $showDeleteAPIKeyConfirm) {
            Button(AppLocalizer.string("刪除"), role: .destructive) {
                _ = keychain.delete(key: "openai_api_key")
                apiKey = ""
                hasAPIKey = false
                editingAPIKey = true
            }
            Button(AppLocalizer.string("取消"), role: .cancel) {}
        }
    }

    private func loadSettings() {
        transcriptionMode = AppSettings.shared.transcriptionMode
        interfaceLanguage = AppLocalizer.language
        chineseOutputScript = AppSettings.shared.chineseOutputScript
        hotkeyPreset = AppSettings.shared.hotkeyPreset
        launchAtLogin = AppSettings.shared.launchAtLogin
        enableAIPolish = AppSettings.shared.enableAIPolish
        restoreClipboard = AppSettings.shared.restoreClipboard
        cloudTranscriptionModel = AppSettings.shared.cloudTranscriptionModel
        customCloudTranscriptionModelID = AppSettings.shared.customCloudTranscriptionModelID ?? ""
        aiPolishModel = AppSettings.shared.aiPolishModel
        customAIPolishModelID = AppSettings.shared.customAIPolishModelID ?? ""
        customSystemPrompt = AppSettings.shared.customSystemPrompt ?? ""
        accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
        apiKey = keychain.get(key: "openai_api_key") ?? ""
        hasAPIKey = !apiKey.isEmpty
        editingAPIKey = !hasAPIKey
    }

    private func startAccessibilityPermissionPolling() {
        guard !HotkeyManager.shared.checkAccessibilityPermission() else { return }
        accessibilityPermissionTimer?.invalidate()
        accessibilityPermissionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            guard HotkeyManager.shared.checkAccessibilityPermission() else { return }
            accessibilityGranted = true
            stopAccessibilityPermissionPolling()
            NotificationCenter.default.post(name: NSNotification.Name("FocusSettings"), object: nil)
        }
    }

    private func stopAccessibilityPermissionPolling() {
        accessibilityPermissionTimer?.invalidate()
        accessibilityPermissionTimer = nil
    }

    private func saveAPIKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, keychain.save(key: "openai_api_key", value: trimmed) else { return }
        apiKey = trimmed
        hasAPIKey = true
        editingAPIKey = false
        showAPIKey = false
    }
}

#Preview { SettingsView() }
