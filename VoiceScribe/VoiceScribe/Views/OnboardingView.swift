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

    private let localization = LocalizationHelper.shared

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
                        Button(localization.localized(.back)) {
                            step -= 1
                        }
                        .accessibilityLabel(localization.localized(.onboardingBackAccessibility))
                        .accessibilityHint("Go to previous step")
                    }

                    Spacer()

                    if step == 0 {
                        Button(localization.localized(.next)) {
                            stopPermissionPolling()
                            step += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!microphoneGranted || !accessibilityGranted)
                        .accessibilityLabel(localization.localized(.onboardingNextAccessibility))
                        .accessibilityHint("Continue to next step")
                    } else {
                        Button(localization.localized(.finish)) {
                            onFinish()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(localization.localized(.onboardingFinishAccessibility))
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

            Text(localization.localized(.onboardingPermissionsComplete))
                .font(.title)
                .fontWeight(.bold)

            Text(String(format: localization.localized(.onboardingRestartingCountdown), countdown))
                .foregroundColor(.secondary)

            Text(localization.localized(.onboardingRestartHint))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permissions Step

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.onboardingPermissionsTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingPermissionsDescription))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.localized(.onboardingMicrophone))
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
                    Button(localization.localized(.onboardingGrantMicrophone)) {
                        AudioRecorder.shared.requestMicrophonePermission { granted in
                            microphoneGranted = granted
                        }
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(localization.localized(.onboardingGrantMicrophone))
                    .accessibilityHint("Request microphone permission")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localization.localized(.onboardingAccessibility))
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
                        Button(localization.localized(.onboardingOpenAccessibility)) {
                            openAccessibilitySettings()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAccessibilityGuide = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(localization.localized(.onboardingOpenAccessibility))
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
            Text(localization.localized(.onboardingAccessibilityGuideIntro))
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 6) {
                guideStep(number: 1, text: localization.localized(.onboardingAccessibilityStep1))
                guideStep(number: 2, text: localization.localized(.onboardingAccessibilityStep2))
                guideStep(number: 3, text: localization.localized(.onboardingAccessibilityStep3))
            }

            HStack(alignment: .top, spacing: 4) {
                Image(systemName: "questionmark.circle")
                    .font(.caption2)
                Text(localization.localized(.onboardingAccessibilityNotFound))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .padding(.top, 2)

            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                Text(localization.localized(.onboardingAccessibilityAutoUpdate))
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Button(localization.localized(.onboardingReopenSettings)) {
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
            
            Text(localization.localized(.onboardingTryItTitle))
                .font(.title)
                .fontWeight(.bold)

            Text(localization.localized(.onboardingTryItPrompt))
                .font(.headline)

            Text(localization.localized(.onboardingTryItDescription))
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
