//
//  MenuBarManager.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Cocoa
import Combine
import QuartzCore

final class MenuBarManager: NSObject {
    private let appState = AppState.shared
    private let onOpenSettings: () -> Void
    private let onShowAbout: () -> Void
    private let onQuit: () -> Void

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    init(
        onOpenSettings: @escaping () -> Void,
        onShowAbout: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenSettings = onOpenSettings
        self.onShowAbout = onShowAbout
        self.onQuit = onQuit
        super.init()
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.setAccessibilityLabel(String(localized: "LaSay 語音輸入"))
            updateMenuBarIcon()
        }

        setupMenu()
        observeStateChanges()

    }

    private func setupMenu() {
        let menu = NSMenu()
        // 狀態顯示
        let statusText: String
        switch appState.status {
        case .idle:
            statusText = String(localized: "待機")
        case .recording:
            statusText = String(localized: "錄音中...")
        case .processing:
            statusText = String(localized: "處理中...")
        }
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: String(localized: "設定..."), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: String(localized: "關於 LaSay"), action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: String(localized: "結束 LaSay"), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func observeStateChanges() {
        appState.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenuBarIcon()
                self?.setupMenu()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }

        let status = appState.status
        let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: "LaSay")
        image?.isTemplate = true

        button.image = image

        // Update accessibility label and post announcement
        let statusText: String
        switch status {
        case .idle:
            statusText = String(localized: "待機")
        case .recording:
            statusText = String(localized: "錄音中...")
        case .processing:
            statusText = String(localized: "處理中...")
        }
        
        button.setAccessibilityLabel("\(String(localized: "LaSay 語音輸入")) - \(statusText)")
        
        // Post accessibility announcement for state changes
        let announcement = "\(String(localized: "LaSay 語音輸入")) \(statusText)"
        NSAccessibility.post(element: button, notification: .announcementRequested, userInfo: [
            .announcement: announcement,
            .priority: NSAccessibilityPriorityLevel.high.rawValue
        ])

        if let imageView = button.subviews.first as? NSImageView {
            imageView.contentTintColor = status.iconColor
            imageView.wantsLayer = true
            imageView.layer?.removeAllAnimations()

            switch status {
            case .idle:
                imageView.alphaValue = 1.0
                imageView.layer?.transform = CATransform3DIdentity

            case .recording:
                let pulseAnimation = CABasicAnimation(keyPath: "opacity")
                pulseAnimation.duration = 0.8
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 0.3
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                pulseAnimation.autoreverses = true
                pulseAnimation.repeatCount = .infinity
                imageView.layer?.add(pulseAnimation, forKey: "pulse")

            case .processing:
                let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
                rotationAnimation.duration = 2.0
                rotationAnimation.fromValue = 0
                rotationAnimation.toValue = Double.pi * 2
                rotationAnimation.repeatCount = .infinity
                rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
                imageView.layer?.add(rotationAnimation, forKey: "rotation")
            }
        }
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func showAbout() {
        onShowAbout()
    }

    @objc private func quitApp() {
        onQuit()
    }

}
