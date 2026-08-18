//
//  HotkeyManager.swift
//  LaSay
//

import ApplicationServices
import Carbon.HIToolbox
import Cocoa
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

    var keyCode: UInt32 { 49 }

    var carbonModifiers: UInt32 {
        switch self {
        case .fnSpace: return UInt32(kEventKeyModifierFnMask)
        case .controlSpace: return UInt32(controlKey)
        case .optionSpace: return UInt32(optionKey)
        }
    }
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
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

    var onHotkeyPressed: (() -> Void)?
    var onHotkeyReleased: (() -> Void)?

    private let hotKeyID = EventHotKeyID(signature: 0x4C615361, id: 1) // "LaSa"

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

    // MARK: - Direct Input Permission

    /// Accessibility enables direct input by synthesizing Command-V; the hotkey itself works without it.
    func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Hotkey Management

    private func applyHotkeyPreset(_ preset: HotkeyPreset) {
        guard hotkeyPreset != preset else { return }
        hotkeyPreset = preset
        if hotKeyRef != nil { restartMonitoring() }
    }

    /// RegisterEventHotKey is delivered by the application event loop and does not require Accessibility.
    func startMonitoring() {
        guard hotKeyRef == nil else { return }

        if eventHandlerRef == nil {
            let eventTypes = [
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
                EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
            ]
            let status = eventTypes.withUnsafeBufferPointer { pointer in
                InstallEventHandler(
                    GetApplicationEventTarget(),
                    Self.eventHandler,
                    eventTypes.count,
                    pointer.baseAddress,
                    Unmanaged.passUnretained(self).toOpaque(),
                    &eventHandlerRef
                )
            }
            guard status == noErr else {
                AppLogger.ui.error("HotkeyManager: failed to install Carbon handler: \(status)")
                return
            }
        }

        var registeredHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkeyPreset.keyCode,
            hotkeyPreset.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &registeredHotKey
        )
        guard status == noErr, let registeredHotKey else {
            AppLogger.ui.error("HotkeyManager: failed to register hotkey: \(status)")
            return
        }

        hotKeyRef = registeredHotKey
        AppLogger.ui.info("HotkeyManager: hotkey monitoring started successfully")
    }

    func stopMonitoring() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
        isHotkeyPressed = false
    }

    func restartMonitoring() {
        stopMonitoring()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startMonitoring()
        }
    }

    private static let eventHandler: EventHandlerUPP = { _, event, userData in
        guard let event, let userData else { return OSStatus(eventNotHandledErr) }
        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        return manager.handleEvent(event)
    }

    private func handleEvent(_ event: EventRef) -> OSStatus {
        var eventHotKeyID = EventHotKeyID()
        var actualSize = 0
        let status = withUnsafeMutablePointer(to: &eventHotKeyID) { idPointer in
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                &actualSize,
                idPointer
            )
        }
        guard status == noErr,
              eventHotKeyID.signature == hotKeyID.signature,
              eventHotKeyID.id == hotKeyID.id else { return OSStatus(eventNotHandledErr) }

        switch GetEventKind(event) {
        case UInt32(kEventHotKeyPressed):
            guard !isHotkeyPressed else { return noErr }
            isHotkeyPressed = true
            onHotkeyPressed?()
        case UInt32(kEventHotKeyReleased):
            guard isHotkeyPressed else { return noErr }
            isHotkeyPressed = false
            onHotkeyReleased?()
        default:
            return OSStatus(eventNotHandledErr)
        }
        return noErr
    }
}
