import AppKit
import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0
    @State private var microphoneGranted = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
    @State private var permissionTimer: Timer?
    @State private var testText = ""
    @State private var launchAtLogin = false
    @State private var didLoadLoginSetting = false
    @FocusState private var testFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if step == 0 { permissionsStep } else { testStep }

            Spacer()

            HStack {
                if step == 1 {
                    Button(String(localized: "稍後完成"), action: finish)
                    Spacer()
                    Button(String(localized: "返回")) { step = 0 }
                } else {
                    Spacer()
                }

                Button(step == 0 ? String(localized: "下一步") : String(localized: "開始使用 LaSay")) {
                    if step == 0 {
                        stopPermissionPolling()
                        step = 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { testFieldFocused = true }
                    } else {
                        finish()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(step == 0 ? !permissionsGranted : testText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(28)
        .frame(width: 480, height: 400)
        .onAppear {
            AppSettings.shared.setDefaultTranscriptionModeIfNeeded()
            guard !didLoadLoginSetting else { return }
            launchAtLogin = AppSettings.shared.hasLaunchedBefore ? AppSettings.shared.launchAtLogin : true
            didLoadLoginSetting = true
        }
    }

    private var permissionsGranted: Bool {
        microphoneGranted && accessibilityGranted
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(String(localized: "兩個權限，約一分鐘"), systemImage: "lock.open")
                .font(.title2.weight(.semibold))

            Text(String(localized: "LaSay 只在你按住快捷鍵時錄音，並把辨識結果貼到目前的 App。"))
                .foregroundStyle(.secondary)

            permissionRow(
                title: String(localized: "麥克風"),
                detail: String(localized: "用來錄下你說的話"),
                granted: microphoneGranted,
                actionTitle: String(localized: "允許")
            ) {
                AudioRecorder.shared.requestMicrophonePermission { microphoneGranted = $0 }
            }

            Divider()

            permissionRow(
                title: String(localized: "輔助使用"),
                detail: String(localized: "用來接收快捷鍵並貼上文字"),
                granted: accessibilityGranted,
                actionTitle: String(localized: "開啟系統設定")
            ) {
                HotkeyManager.shared.requestAccessibilityPermission()
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }

            Text(String(localized: "權限開啟後會自動繼續，不必重新啟動 App。"))
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
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? Color.green : Color.secondary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if !granted {
                Button(actionTitle, action: action)
            }
        }
    }

    private var testStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(String(localized: "說一句話，就設定完成"), systemImage: "waveform")
                .font(.title2.weight(.semibold))

            Text(String(format: String(localized: "點一下文字框，按住 %@ 說話，放開後 LaSay 會把結果貼進來。"), AppSettings.shared.hotkeyPreset.displayName))
                .foregroundStyle(.secondary)

            TextEditor(text: $testText)
                .focused($testFieldFocused)
                .font(.body)
                .padding(8)
                .frame(height: 130)
                .background(Color(nsColor: .textBackgroundColor))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.35)))

            if testText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(String(localized: "提示：短按不會錄音，請按住、說話、再放開。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label(String(localized: "成功！LaSay 已經可以在任何 App 使用。"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            Toggle(String(localized: "登入後自動啟動（推薦）"), isOn: $launchAtLogin)
        }
    }

    private func finish() {
        AppSettings.shared.launchAtLogin = launchAtLogin
        onFinish()
    }

    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            let wasTrusted = accessibilityGranted
            microphoneGranted = AudioRecorder.shared.checkMicrophonePermission()
            accessibilityGranted = HotkeyManager.shared.checkAccessibilityPermission()
            if accessibilityGranted && !wasTrusted { HotkeyManager.shared.startMonitoring() }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }
}

#Preview { OnboardingView(onFinish: {}) }
