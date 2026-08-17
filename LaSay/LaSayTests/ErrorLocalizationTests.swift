import XCTest
@testable import LaSay

final class ErrorLocalizationTests: XCTestCase {
    func testWhisperErrorLocalizedDescriptionSurvivesCast() {
        let errors: [WhisperError] = [.noAPIKey, .invalidAudioFile, .invalidResponse, .modelDownloadFailed]

        for error in errors {
            XCTAssertFalse((error as Error).localizedDescription.isEmpty)
        }
    }

    func testOpenAIErrorLocalizedDescriptionSurvivesCast() {
        let errors: [OpenAIError] = [.noAPIKey, .invalidResponse]

        for error in errors {
            XCTAssertFalse((error as Error).localizedDescription.isEmpty)
        }
    }
}
