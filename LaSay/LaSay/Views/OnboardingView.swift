//
//  OnboardingView.swift
//  LaSay
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
    @State private var isPulsing: Bool = false
    @State private var permissionTimer: Timer? = nil
    @State private var showAccessibilityGuide: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if step == 0 {
                permissionsStep
            } else {
                tryItStep
            }

            Spacer()

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
        .padding(28)
        .frame(width: 460, height: 420)
        .onAppear {
            applyDefaultModeIfNeeded()
        }
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
                        Button(String(localized: "授予輔助使用權限")) {
                            HotkeyManager.shared.requestAccessibilityPermission()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAccessibilityGuide = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(String(localized: "授予輔助使用權限"))
                        .accessibilityHint("Request accessibility permission")
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
            Text(String(localized: "在系統提示中完成以下步驟："))
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 6) {
                guideStep(number: 1, text: String(localized: "點擊「打開系統設定」"))
                guideStep(number: 2, text: String(localized: "開啟「LaSay」旁邊的開關"))
                guideStep(number: 3, text: String(localized: "如有提示，輸入密碼確認"))
            }

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .font(.caption2)
                Text(String(localized: "若系統提示沒有出現，請使用下方按鈕。"))
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

            Button(String(localized: "直接打開系統設定")) {
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

                let accessibilityWasGranted = accessibilityGranted

                microphoneGranted = newMic
                accessibilityGranted = newAccessibility

                if newAccessibility && !accessibilityWasGranted {
                    HotkeyManager.shared.startMonitoring()
                }
            }
        }
    }

    private func stopPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = nil
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
