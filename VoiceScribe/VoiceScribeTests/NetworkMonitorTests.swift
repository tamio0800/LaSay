import XCTest
@testable import VoiceScribe

final class NetworkMonitorTests: XCTestCase {
    func testConcurrentReadDoesNotCrash() {
        let monitor = NetworkMonitor.shared
        let iterations = 1000
        let group = DispatchGroup()

        for _ in 0..<iterations {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                _ = monitor.isOnline
                group.leave()
            }

            group.enter()
            DispatchQueue.global(qos: .background).async {
                _ = monitor.isOnline
                group.leave()
            }
        }

        let result = group.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success, "Concurrent reads should complete without crash")
    }
}
