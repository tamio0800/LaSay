//
//  HotkeyManager.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import ApplicationServices
import os.log

enum HotkeyPreset: String, CaseIterable, Identifiable {
    case fnSpace = "fn_space"
    case controlSpace = "control_space"
    case optionSpace = "option_space"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fnSpace: return "Fn + Space"
        case .controlSpace: return "Control + Space"
        case .optionSpace: return "Option + Space"
        }
    }

    var keyCode: CGKeyCode { 49 }

    var requiredFlags: CGEventFlags {
        switch self {
        case .fnSpace: return .maskSecondaryFn
        case .controlSpace: return .maskControl
        case .optionSpace: return .maskAlternate
        }
    }
}

class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Thread-safe state access
    private let stateQueue = DispatchQueue(label: "com.lasay.hotkeymanager.state")
    private var _isHotkeyPressed = false
    private var isHotkeyPressed: Bool {
        get { stateQueue.sync { _isHotkeyPressed } }
        set { stateQueue.sync { _isHotkeyPressed = newValue } }
    }

    private var _hotkeyPreset: HotkeyPreset
    private var hotkeyPresetObserver: NSObjectProtocol?
    private var hotkeyPreset: HotkeyPreset {
        get { stateQueue.sync { _hotkeyPreset } }
        set { stateQueue.sync { _hotkeyPreset = newValue } }
    }

    // 回調
    var onHotkeyPressed: (() -> Void)?
    var onHotkeyReleased: (() -> Void)?

    private init() {
        _hotkeyPreset = HotkeyPreset(rawValue: UserDefaults.standard.string(forKey: "hotkey_preset") ?? "") ?? .fnSpace
        hotkeyPresetObserver = NotificationCenter.default.addObserver(
            forName: .hotkeyPresetDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let preset = notification.object as? HotkeyPreset else { return }
            self?.applyHotkeyPreset(preset)
        }
    }
    
    deinit {
        if let hotkeyPresetObserver {
            NotificationCenter.default.removeObserver(hotkeyPresetObserver)
        }
        stopMonitoring()
    }

    var selectedHotkeyPreset: HotkeyPreset {
        get { hotkeyPreset }
        set { AppSettings.shared.hotkeyPreset = newValue }
    }

    // MARK: - Accessibility Permission

    /// 檢查 Accessibility 權限
    func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    /// 請求 Accessibility 權限
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Hotkey Management

    private func applyHotkeyPreset(_ preset: HotkeyPreset) {
        guard hotkeyPreset != preset else { return }
        hotkeyPreset = preset
        if eventTap != nil {
            restartMonitoring()
        }
    }

    /// 啟動全域快捷鍵監聽
    func startMonitoring() {
        AppLogger.ui.info("HotkeyManager: starting hotkey monitoring")

        guard checkAccessibilityPermission() else {
            AppLogger.ui.error("HotkeyManager: accessibility permission not granted, cannot start monitoring")
            return
        }

        // 如果已經在監聽，先停止
        if eventTap != nil {
            stopMonitoring()
        }

        // 創建事件監聽器
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            AppLogger.ui.error("HotkeyManager: failed to create event tap")
            return
        }

        self.eventTap = eventTap

        // 創建 run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // 啟用事件監聽
        CGEvent.tapEnable(tap: eventTap, enable: true)
        AppLogger.ui.info("HotkeyManager: hotkey monitoring started successfully")
    }

    /// 停止監聽
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
            AppLogger.ui.info("HotkeyManager: hotkey monitoring stopped")
        }
    }

    /// 重新啟動監聽（用於恢復）
    func restartMonitoring() {
        stopMonitoring()

        // 短暫延遲後重新啟動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        // 處理 flags changed（修飾鍵變化）
        if type == .flagsChanged {
            return Unmanaged.passUnretained(event)
        }

        // 獲取按鍵資訊
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        let preset = hotkeyPreset
        let isTargetKey = keyCode == Int64(preset.keyCode)

        let relevantFlags: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]
        let hasModifiers = flags.intersection(relevantFlags) == preset.requiredFlags

        // 優先處理 keyUp：只要是 Space 鍵且之前按下過，就觸發放開（不管 Fn 鍵是否還按著）
        if type == .keyUp && isTargetKey && isHotkeyPressed {
            isHotkeyPressed = false
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyReleased?()
            }
            return nil  // 消費此事件
        }

        // 處理 keyDown：檢測到 Space 鍵 + Fn 鍵的組合
        if isTargetKey && hasModifiers {
            if type == .keyDown && !isHotkeyPressed {
                isHotkeyPressed = true
                DispatchQueue.main.async { [weak self] in
                    self?.onHotkeyPressed?()
                }
            }
            // 消費所有符合條件的事件
            return nil
        }

        // 如果正在錄音中，消費所有 Space 鍵事件（防止傳遞到應用產生嘟嘟聲）
        if isHotkeyPressed && isTargetKey {
            return nil
        }

        // 不是我們的快捷鍵，讓事件繼續傳遞
        return Unmanaged.passUnretained(event)
    }

}
