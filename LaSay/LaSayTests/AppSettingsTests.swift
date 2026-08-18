import XCTest
@testable import LaSay

@MainActor
final class AppSettingsTests: XCTestCase {
    private let testKeys = [
        "restore_clipboard",
        "cloud_transcription_model",
        "custom_cloud_transcription_model_id",
        "ai_polish_model",
        "custom_ai_polish_model_id",
        "hotkey_preset"
    ]

    override func setUp() {
        super.setUp()
        testKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        testKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testRestoreClipboardDefaultsToTrue() {
        UserDefaults.standard.removeObject(forKey: "restore_clipboard")
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

    func testCloudTranscriptionModelDefaultsToAutomatic() {
        XCTAssertEqual(AppSettings.shared.cloudTranscriptionModel, .automatic)
        XCTAssertEqual(AppSettings.cloudTranscriptionModelID(), "gpt-4o-transcribe")
    }

    func testCloudTranscriptionCustomModelPersists() {
        AppSettings.shared.cloudTranscriptionModel = .custom
        AppSettings.shared.customCloudTranscriptionModelID = "  my-transcriber  "

        XCTAssertEqual(AppSettings.shared.cloudTranscriptionModel, .custom)
        XCTAssertEqual(AppSettings.cloudTranscriptionModelID(), "my-transcriber")
    }

    func testAIPolishModelDefaultsToAutomatic() {
        XCTAssertEqual(AppSettings.shared.aiPolishModel, .automatic)
        XCTAssertEqual(AppSettings.aiPolishModelID(), "gpt-5.6-luna")
    }

    func testAIPolishCustomModelPersists() {
        AppSettings.shared.aiPolishModel = .custom
        AppSettings.shared.customAIPolishModelID = "my-polisher"

        XCTAssertEqual(AppSettings.shared.aiPolishModel, .custom)
        XCTAssertEqual(AppSettings.aiPolishModelID(), "my-polisher")
    }

    func testHotkeyPresetDefaultsToFnSpace() {
        XCTAssertEqual(AppSettings.shared.hotkeyPreset, .fnSpace)
    }

    func testHotkeyPresetPersistsSelection() {
        AppSettings.shared.hotkeyPreset = .optionSpace

        XCTAssertEqual(AppSettings.shared.hotkeyPreset, .optionSpace)
    }
}
