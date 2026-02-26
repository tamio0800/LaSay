//
//  NetworkMonitor.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let lock = NSLock()
    private var _isOnline: Bool = true

    var isOnline: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isOnline
    }

    private func setOnline(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        _isOnline = value
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.setOnline(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}
