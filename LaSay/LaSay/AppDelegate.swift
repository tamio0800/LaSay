//
//  AppDelegate.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var recordingCoordinator: RecordingCoordinator?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var aboutWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(
            onOpenSettings: { [weak self] in self?.openSettings() },
            onShowAbout: { [weak self] in self?.showAbout() },
            onQuit: { [weak self] in self?.quitApp() }
        )
        menuBarManager?.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)

        recordingCoordinator = RecordingCoordinator()
        recordingCoordinator?.start()

        // Pre-load SenseVoice model on launch
        preloadLocalModelIfNeeded()

        checkFirstLaunch()
    }

    @objc func openSettings() {
        // 如果設定視窗已經打開，直接聚焦
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 建立設定視窗
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        // 視窗標題根據介面語言顯示
        window.title = String(localized: "LaSay 設定")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 480))
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 讓視窗置於最前面
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc func openOnboarding() {
        if let window = onboardingWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            AppSettings.shared.hasLaunchedBefore = true
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "歡迎使用")
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    @objc func showAbout() {
        // Reuse existing window if already open
        if let window = aboutWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

        // Create AboutView inline
        let aboutView = VStack(spacing: 16) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
            }
            
            Text("LaSay")
                .font(.title)
                .fontWeight(.bold)
            
            Text(String(format: String(localized: "版本 %@ (Build %@)"), version, build))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(String(localized: "給開發者的語音輸入工具"))
                .font(.headline)
                .padding(.top, 4)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "功能："))
                    .font(.headline)

                Text("• " + String(localized: "SenseVoice 離線辨識 + 雲端 OpenAI"))
                Text("• " + String(localized: "AI 文字清理（保留技術術語）"))
                Text("• " + String(localized: "全域快捷鍵：Fn + Space"))
                Text("• " + String(localized: "任何 app 都能用，包括 Terminal 和 IDE"))
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Text(String(localized: "聯繫：tamio.tsiu@gmail.com"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400, height: 420)

        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = String(localized: "LaSay")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 420))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        aboutWindow = window
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Model Pre-loading

    private func preloadLocalModelIfNeeded() {
        let mode = AppSettings.shared.transcriptionMode
        if mode == .senseVoice {
            SenseVoiceService.shared.preloadModel()
        }
    }

    // MARK: - First Launch

    func checkFirstLaunch() {
        let needsOnboarding = !AppSettings.shared.hasLaunchedBefore
            || !AudioRecorder.shared.checkMicrophonePermission()
            || !HotkeyManager.shared.checkAccessibilityPermission()

        if needsOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.openOnboarding()
            }
        }
    }
}
