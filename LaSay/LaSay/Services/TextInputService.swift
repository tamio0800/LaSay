//
//  TextInputService.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/1/25.
//

import Cocoa
import CoreGraphics
import ApplicationServices

class TextInputService {
    static let shared = TextInputService()

    private init() {}

    // MARK: - Paste Text

    /// 將文字貼到當前游標位置
    /// Copies text to the clipboard, then sends Command-V for direct input.
    /// The completion receives `true` when Command-V was sent successfully.
    func pasteText(
        _ text: String,
        restoreClipboard: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) {
        let canAutoPaste = AXIsProcessTrusted()
        let originalClipboard = canAutoPaste ? backupClipboard() : [:]
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard canAutoPaste else {
            completion?(false)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else {
                completion?(false)
                return
            }
            let didAutoPaste = self.simulateCommandV()

            if didAutoPaste, restoreClipboard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.restoreClipboard(originalClipboard)
                    completion?(true)
                }
            } else {
                completion?(didAutoPaste)
            }
        }
    }

    // MARK: - Clipboard Management

    /// 備份剪貼簿內容
    private func backupClipboard() -> [NSPasteboard.PasteboardType: Any] {
        let pasteboard = NSPasteboard.general
        var backup: [NSPasteboard.PasteboardType: Any] = [:]

        // 備份所有類型的內容
        for type in pasteboard.types ?? [] {
            if type == .string, let string = pasteboard.string(forType: .string) {
                backup[type] = string
            } else if type == .URL, let url = pasteboard.string(forType: .URL) {
                backup[type] = url
            } else if let data = pasteboard.data(forType: type) {
                backup[type] = data
            }
        }

        return backup
    }

    /// 還原剪貼簿內容
    private func restoreClipboard(_ backup: [NSPasteboard.PasteboardType: Any]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        for (type, content) in backup {
            if let string = content as? String {
                pasteboard.setString(string, forType: type)
            } else if let data = content as? Data {
                pasteboard.setData(data, forType: type)
            }
        }

    }

    // MARK: - Keyboard Simulation

    /// 模擬 ⌘V 按鍵
    @discardableResult
    private func simulateCommandV() -> Bool {
        // 創建 V 鍵按下事件（keyCode 9 是 V）
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else {
            return false
        }

        // 設定 Command 修飾鍵
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand

        // 發送事件
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
        return true
    }
}
