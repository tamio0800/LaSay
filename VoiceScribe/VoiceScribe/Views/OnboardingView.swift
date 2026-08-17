//
//  OnboardingView.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import SwiftUI
import AppKit

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step: Int = 0
    @State private var microphoneGranted: Bool = AudioRecorder.shared.checkMicrophonePermission()
    @State private var accessibilityGranted: Bool = HotkeyManager.shared.checkAccessibilityPermission()
    @State private var refreshUI: Bool = false
    @State private var isPulsing: Bool = false
    @State private var permissionTimer: Timer? = nil
    @State private var restartCountdown: Int? = nil
    @State private var restartTimer: Timer? = nil
    @State private var showAccessibilityGuide: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let countdown = restartCountdown {
                restartingView(countdown: countdown)
            } else if step == 0 {
                permissionsStep
            } else {
                tryItStep
            }

            Spacer()

            if restartCountdown == nil {
                HStack {
                    if step > 0 {
                        Button(String(localized: "返回")) {
                            step -= 1
                        }
                        .accessibilityLabel(String(localized: "返回上一步"))
                        .accessibilityHint("Go to previous step")
                    }

                    Spacer()

                    if step == 0 {
                        Button(String(localized: "下一步")) {
                            stopPermissionPolling()
                            step += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!microphoneGranted || !accessibilityGranted)
                        .accessibilityLabel(String(localized: "前往下一步"))
                        .accessibilityHint("Continue to next step")
                    } else {
                        Button(String(localized: "完成")) {
                            onFinish()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(String(localized: "完成設定"))
                        .accessibilityHint("Complete onboarding")
                    }
                }
            }
        }
        .padding(28)
        .frame(width: 460, height: 420)
        .id(refreshUI)
        .onAppear {
            applyDefaultModeIfNeeded()
        }
    }

    // MARK: - Restarting View

    private func restartingView(countdown: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(String(localized: "權限設定完成！"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(format: String(localized: "即將自動重新啟動 LaSay（%d 秒）\u{2026}"), countdown))
                .foregroundColor(.secondary)

            Text(String(localized: "重啟後即可使用 Fn + Space 語音輸入"))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permissions Step

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "權限設定"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "LaSay 需要麥克風與輔助使用權限才能正常工作。"))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "麥克風"))
                        .font(.headline)
                    Spacer()
                    if microphoneGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }

                if !microphoneGranted {
                    Button(String(localized: "授予麥克風權限")) {
                        AudioRecorder.shared.requestMicrophonePermission { granted in
                            microphoneGranted = granted
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(String(localized: "授予麥克風權限"))
                    .accessibilityHint("Request microphone permission")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(String(localized: "輔助使用"))
                        .font(.headline)
                    Spacer()
                    if accessibilityGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }

                if !accessibilityGranted {
                    if showAccessibilityGuide {
                        accessibilityGuide
                            .transition(.opacity)
                    } else {
                        Button(String(localized: "打開輔助使用設定")) {
                            openAccessibilitySettings()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAccessibilityGuide = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(String(localized: "打開輔助使用設定"))
                        .accessibilityHint("Open System Settings to grant accessibility permission")
                        .transition(.opacity)
                    }
                }
            }
        }
        .onAppear { startPermissionPolling() }
        .onDisappear { stopPermissionPolling() }
    }

    // MARK: - Accessibility Guide

    private var accessibilityGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "在「系統設定」中完成以下步驟："))
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 6) {
                guideStep(number: 1, text: String(localized: "在列表中找到「LaSay」"))
                guideStep(number: 2, text: String(localized: "開啟旁邊的開關"))
                guideStep(number: 3, text: String(localized: "如有提示，輸入密碼確認"))
            }

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .font(.caption2)
                Text(String(localized: "找不到的話請點擊左下角的 + 並搜尋「LaSay」新增"))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.top, 2)

            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                Text(String(localized: "完成後會自動偵測"))
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Button(String(localized: "重新打開系統設定")) {
                openAccessibilitySettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func guideStep(number: Int, text: String) -> some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private func openAccessibilitySettings() {
        // Register app in Accessibility database so it appears in the list
        HotkeyManager.shared.requestAccessibilityPermission()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Permission Polling

    private func startPermissionPolling() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                let newMic = AudioRecorder.shared.checkMicrophonePermission()
                let newAccessibility = HotkeyManager.shared.checkAccessibilityPermission()

                // Detect both permissions granted (either just now or already)
                let bothGrantedNow = newMic && newAccessibility
                let bothGrantedBefore = microphoneGranted && accessibilityGranted

                microphoneGranted = newMic
                accessibilityGranted = newAccessibility

                // Trigger restart when both become granted (transition from not-both to both)
                if bothGrantedNow && !bothGrantedBefore {
                    stopPermissionPolling()
                    startRestartCountdown()
                }
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    // MARK: - Auto-Restart

    private func startRestartCountdown() {
        // Mark onboarding as complete
        AppSettings.shared.hasLaunchedBefore = true

        restartCountdown = 3
        restartTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            DispatchQueue.main.async {
                guard let current = restartCountdown else {
                    timer.invalidate()
                    return
                }
                if current <= 1 {
                    timer.invalidate()
                    restartApp()
                } else {
                    restartCountdown = current - 1
                }
            }
        }
    }

    private func restartApp() {
        guard let bundleURL = Bundle.main.bundleURL as URL? else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: bundleURL, configuration: config) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: - Try It Step

    private var tryItStep: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
                .opacity(isPulsing ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear { isPulsing = true }
            
            Text(String(localized: "試試看"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "按住 Fn + Space 試試看！"))
                .font(.headline)

            Text(String(localized: "完成後就可以開始使用 LaSay。"))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Defaults

    private func applyDefaultModeIfNeeded() {
        AppSettings.shared.setDefaultTranscriptionModeIfNeeded()
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
