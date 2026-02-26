import XCTest
@testable import VoiceScribe

final class ErrorLocalizationTests: XCTestCase {
    func testWhisperErrorLocalizedDescriptionSurvivesCast() {
        let errors: [WhisperError] = [
            .noAPIKey,
            .invalidAudioFile,
            .invalidResponse,
            .modelDownloadFailed,
        ]

        for whisperError in errors {
            let genericError: Error = whisperError
            let description = genericError.localizedDescription
            XCTAssertFalse(
                description.contains("The operation couldn"),
                "WhisperError.\(whisperError) lost its custom description after casting to Error: \(description)"
            )
            XCTAssertFalse(description.isEmpty)
        }
    }

    func testOpenAIErrorLocalizedDescriptionSurvivesCast() {
        let errors: [OpenAIError] = [
            .noAPIKey,
            .invalidResponse,
        ]

        for openAIError in errors {
            let genericError: Error = openAIError
            let description = genericError.localizedDescription
            XCTAssertFalse(
                description.contains("The operation couldn"),
                "OpenAIError.\(openAIError) lost its custom description after casting to Error: \(description)"
            )
            XCTAssertFalse(description.isEmpty)
        }
    }
}
