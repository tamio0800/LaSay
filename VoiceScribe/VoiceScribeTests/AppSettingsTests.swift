import XCTest
@testable import VoiceScribe

@MainActor
final class AppSettingsTests: XCTestCase {
    private let testKey = "restore_clipboard"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    func testRestoreClipboardDefaultsToTrue() {
        UserDefaults.standard.removeObject(forKey: testKey)
        XCTAssertTrue(AppSettings.shared.restoreClipboard, "restoreClipboard should default to true when key is absent")
    }

    func testRestoreClipboardReadsStoredFalse() {
        AppSettings.shared.restoreClipboard = false
        XCTAssertFalse(AppSettings.shared.restoreClipboard, "restoreClipboard should return false after being set to false")
    }

    func testRestoreClipboardReadsStoredTrue() {
        AppSettings.shared.restoreClipboard = false
        AppSettings.shared.restoreClipboard = true
        XCTAssertTrue(AppSettings.shared.restoreClipboard, "restoreClipboard should return true after being set to true")
    }
}
