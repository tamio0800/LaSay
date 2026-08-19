import AppKit
import AVFoundation
import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0
    @State private var interfaceLanguage = AppLocalizer.language
    @State private var microphoneGranted = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
    @State private var didRequestAccessibilityPermission = false
    @State private var didEnterSystemSettingsFlow = false
    @State private var permissionTimer: Timer?
    @State private var testText = ""
    @State private var didStartTest = false
    @State private var didCompleteTest = false
    @State private var launchAtLogin = false
    @State private var didLoadLoginSetting = false
    @FocusState private var testFieldFocused: Bool

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
        VStack(alignment: .leading, spacing: 24) {
            if step == 0 { permissionsStep } else { testStep }

            Spacer()

            if step == 1 {
                HStack {
                    Spacer()
                    Button(AppLocalizer.string("開始使用 LaSay"), action: finish)
                        .buttonStyle(.borderedProminent)
                        .disabled(!didCompleteTest)
                }
            }
        }
        .padding(28)
        .frame(width: 480, height: 400)
        .id(interfaceLanguage)
        .onAppear {
            AppSettings.shared.setDefaultTranscriptionModeIfNeeded()
            guard !didLoadLoginSetting else { return }
            launchAtLogin = AppSettings.shared.hasLaunchedBefore ? AppSettings.shared.launchAtLogin : true
            didLoadLoginSetting = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .interfaceLanguageDidChange)) { _ in
            interfaceLanguage = AppLocalizer.language
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(AppLocalizer.string("介面語言"))
                Spacer()
                Picker("", selection: interfaceLanguageBinding) {
                    ForEach(InterfaceLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 170, alignment: .trailing)
            }

            Label(AppLocalizer.string("兩個權限，約一分鐘"), systemImage: "lock.open")
                .font(.title2.weight(.semibold))

            Text(AppLocalizer.string("LaSay 只在你按住快捷鍵時錄音，並把辨識結果貼到目前的 App。"))
                .foregroundStyle(.secondary)

            permissionRow(
                title: AppLocalizer.string("麥克風"),
                detail: AppLocalizer.string("用來錄下你說的話"),
                granted: microphoneGranted,
                actionTitle: microphoneNeedsSystemSettings ? AppLocalizer.string("開啟系統設定") : AppLocalizer.string("允許")
            ) {
                if microphoneNeedsSystemSettings {
                    didEnterSystemSettingsFlow = true
                    openPrivacySettings("Privacy_Microphone")
                } else {
                    AudioRecorder.shared.requestMicrophonePermission { granted in
                        microphoneGranted = granted
                        refreshPermissions()
                    }
                }
            }

            Divider()

            permissionRow(
                title: AppLocalizer.string("輔助使用"),
                detail: AppLocalizer.string("先允許 LaSay；若提示未出現，再開啟輔助使用設定。"),
                granted: accessibilityGranted,
                actionTitle: didRequestAccessibilityPermission
                    ? AppLocalizer.string("開啟輔助使用設定")
                    : AppLocalizer.string("允許輔助使用")
            ) {
                if didRequestAccessibilityPermission {
                    didEnterSystemSettingsFlow = true
                    openPrivacySettings("Privacy_Accessibility")
                } else {
                    didRequestAccessibilityPermission = true
                    HotkeyManager.shared.requestAccessibilityPermission()
                }
            }

            Text(AppLocalizer.string("完成後返回 LaSay；權限會自動偵測，不必重新啟動。"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { startPermissionPolling() }
        .onDisappear { stopPermissionPolling() }
    }

    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(granted ? Color.green : Color.secondary)
                    .font(.title2)

                Text(title).font(.headline)

                Spacer()

                if !granted {
                    Button(actionTitle, action: action)
                }
            }

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 38)
        }
    }

    private var testStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(AppLocalizer.string("說一句話，就設定完成"), systemImage: "waveform")
                .font(.title2.weight(.semibold))

            Text(testInstruction)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $testText)
                .focused($testFieldFocused)
                .font(.body)
                .padding(8)
                .frame(height: 130)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.35)))
                .onChange(of: testText) { value in
                    guard didStartTest, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    didCompleteTest = true
                }

            if !didCompleteTest {
                Text(AppLocalizer.string("提示：短按不會錄音，請按住、說話、再放開。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label(AppLocalizer.string("成功！LaSay 已經可以在任何 App 使用。"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Toggle(AppLocalizer.string("登入後自動啟動（推薦）"), isOn: $launchAtLogin)
        }
        .onReceive(AppState.shared.$status) { status in
            if case .recording = status { didStartTest = true }
        }
    }

    private var testInstruction: String {
        String(format: AppLocalizer.string("點一下文字框，按住 %@ 說話，放開後 LaSay 會把結果貼進來。"), AppSettings.shared.hotkeyPreset.displayName)
    }

    private var microphoneNeedsSystemSettings: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .denied || status == .restricted
    }

    private func finish() {
        guard microphoneGranted, accessibilityGranted, didCompleteTest else { return }
        AppSettings.shared.launchAtLogin = launchAtLogin
        onFinish()
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        refreshPermissions()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in refreshPermissions() }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    private func openPrivacySettings(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func refreshPermissions() {
        let wasMicrophoneGranted = microphoneGranted
        let wasAccessibilityGranted = accessibilityGranted
        microphoneGranted = AudioRecorder.shared.checkMicrophonePermission()
        accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()

        let permissionWasGranted = (!wasMicrophoneGranted && microphoneGranted)
            || (!wasAccessibilityGranted && accessibilityGranted)
        if permissionWasGranted && (didRequestAccessibilityPermission || didEnterSystemSettingsFlow) {
            NotificationCenter.default.post(name: NSNotification.Name("FocusOnboarding"), object: nil)
        }

        guard step == 0, microphoneGranted, accessibilityGranted else { return }

        stopPermissionPolling()
        step = 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { testFieldFocused = true }
    }
}

#Preview { OnboardingView(onFinish: {}) }
