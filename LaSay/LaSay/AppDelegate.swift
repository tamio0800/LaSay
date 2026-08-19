//
//  AppDelegate.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import Sparkle
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    private var menuBarManager: MenuBarManager?
    private var recordingCoordinator: RecordingCoordinator?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var aboutWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(
            onOpenSettings: { [weak self] in self?.openSettings() },
            onRunSetup: { [weak self] in self?.openOnboarding() },
            onCheckForUpdates: { [weak self] in self?.updaterController.checkForUpdates(nil) },
            onShowAbout: { [weak self] in self?.showAbout() },
            onQuit: { [weak self] in self?.quitApp() }
        )
        menuBarManager?.setup()

        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkForUpdates), name: NSNotification.Name("CheckForUpdates"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(quitApp), name: NSNotification.Name("QuitApp"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWindowTitles), name: .interfaceLanguageDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusOnboarding), name: NSNotification.Name("FocusOnboarding"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(focusSettings), name: NSNotification.Name("FocusSettings"), object: nil)

        _ = updaterController

        recordingCoordinator = RecordingCoordinator()
        recordingCoordinator?.start()

        // Pre-load SenseVoice model on launch
        preloadLocalModelIfNeeded()

        checkFirstLaunch()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if setupRequired || onboardingWindow?.isVisible == true {
            openOnboarding()
            return true
        }
        openSettings()
        return true
    }

    @objc func openSettings() {
        guard !setupRequired, onboardingWindow?.isVisible != true else {
            openOnboarding()
            return
        }

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
        window.title = AppLocalizer.string("LaSay 設定")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 580))
        window.center()
        window.makeKeyAndOrderFront(nil)

        // 讓視窗置於最前面
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    @objc func openOnboarding() {
        settingsWindow?.orderOut(nil)

        if let window = onboardingWindow, window.isVisible {
            focusOnboarding()
            return
        }

        let onboardingView = OnboardingView { [weak self] in
            AppSettings.shared.hasLaunchedBefore = true
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppLocalizer.string("歡迎使用")
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
            
            Text(String(format: AppLocalizer.string("版本 %@ (Build %@)"), version, build))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(AppLocalizer.string("給開發者的語音輸入工具"))
                .font(.headline)
                .padding(.top, 4)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalizer.string("功能："))
                    .font(.headline)

                Text("• " + AppLocalizer.string("SenseVoice 離線辨識 + 雲端 OpenAI"))
                Text("• " + AppLocalizer.string("AI 文字清理（保留技術術語）"))
                Text("• " + String(format: AppLocalizer.string("全域快捷鍵：%@"), AppSettings.shared.hotkeyPreset.displayName))
                Text("• " + AppLocalizer.string("任何 app 都能用，包括 Terminal 和 IDE"))
            }
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            Text(AppLocalizer.string("聯繫：tamio.tsiu@gmail.com"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(width: 400, height: 420)

        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppLocalizer.string("LaSay")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 400, height: 420))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        aboutWindow = window
    }

    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func refreshWindowTitles() {
        settingsWindow?.title = AppLocalizer.string("LaSay 設定")
        onboardingWindow?.title = AppLocalizer.string("歡迎使用")
        aboutWindow?.title = AppLocalizer.string("LaSay")
    }

    @objc private func focusOnboarding() {
        guard let window = onboardingWindow, window.isVisible else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func focusSettings() {
        guard !setupRequired, onboardingWindow?.isVisible != true else {
            openOnboarding()
            return
        }
        guard let window = settingsWindow, window.isVisible else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var setupRequired: Bool {
        !AppSettings.shared.hasLaunchedBefore
            || !AudioRecorder.shared.checkMicrophonePermission()
            || !HotkeyManager.shared.checkAccessibilityPermission()
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
