import XCTest
@testable import VoiceScribe

final class LocalizationTests: XCTestCase {
    func testAllLocalizationKeysReturnNonEmptyStrings() {
        let localization = LocalizationHelper.shared

        let allKeys: [LocalizationKey] = [
            // Settings
            .settings, .openAIAPIKey, .apiKeySet, .show, .hide, .update, .save, .cancel,
            .enterAPIKey, .apiKeyDescription, .getAPIKey,
            // Transcription
            .transcriptionSettings, .transcriptionMode, .transcriptionLanguage, .transcriptionDescription,
            // AI Polish
            .aiPolish, .enableAIPolish, .aiPolishDescription,
            .currentPromptStatus, .defaultPromptLabel, .customPromptLabel,
            .customPromptHint, .customSystemPrompt, .resetToDefault, .advanced, .aiCleanupDetail,
            // Buttons
            .close, .paste, .changesSavedAutomatically, .back, .next, .finish,
            // Menu Bar
            .status, .idle, .recording, .processing, .lastTranscription, .settingsMenu, .about, .quit,
            // Window titles
            .settingsWindowTitle, .onboardingWindowTitle,
            // About
            .aboutTitle,
            // Onboarding
            .onboardingPermissionsTitle, .onboardingPermissionsDescription,
            .onboardingMicrophone, .onboardingAccessibility,
            .onboardingGrantMicrophone, .onboardingOpenAccessibility,
            .onboardingTryItTitle, .onboardingTryItPrompt, .onboardingTryItDescription,
            // Permissions
            .microphonePermissionTitle, .microphonePermissionMessage, .openSystemSettings,
            .accessibilityPermissionTitle, .accessibilityPermissionMessage,
            .accessibilityGrantedTitle, .accessibilityGrantedMessage,
            .restartNow, .restartLater,
            // Notifications
            .transcriptionFailed, .aiPolishFailed, .usingOriginalText,
            .modelDownloadFailed, .noNetworkConnection, .invalidAPIKey,
            .apiErrorPrefix, .apiKeyRequiredTitle, .apiKeyRequiredBody,
            // Accessibility
            .toggleAccessibilityHint, .aiPolishAccessibility,
            .apiKeyShowHideAccessibility, .apiKeySaveAccessibility,
            .settingsCloseAccessibility, .onboardingNextAccessibility,
            .onboardingBackAccessibility, .onboardingFinishAccessibility,
            .cancelButtonAccessibility, .menuBarStatusAccessibility,
            // Error messages
            .microphonePermissionDenied, .offlineCloudModeError,
            .networkErrorActionable, .invalidAPIKeyActionable, .processingTimeout,
            // Punctuation
            .punctuationStyle,
            // Error descriptions (Issue 4)
            .invalidAudioFile, .invalidAPIResponse,
            // Recording (Issue 5)
            .recordingTooShortTitle, .recordingTooShortBody,
            // Settings (Issue 5)
            .modelLoading, .toggleOn, .toggleOff,
            .deleteAPIKey, .deleteAPIKeyAccessibility,
            .deleteAPIKeyConfirmTitle, .delete, .deleteAPIKeyConfirmMessage,
            // About (Issue 5)
            .aboutVersion, .aboutTagline, .aboutFeaturesTitle,
            .aboutFeature1, .aboutFeature2, .aboutFeature3, .aboutFeature4,
            .aboutContact,
            // Accessibility guide
            .onboardingAccessibilityGuideIntro, .onboardingAccessibilityStep1,
            .onboardingAccessibilityStep2, .onboardingAccessibilityStep3,
            .onboardingAccessibilityNotFound,
            .onboardingAccessibilityAutoUpdate, .onboardingReopenSettings,
            // Restart
            .onboardingPermissionsComplete, .onboardingRestartingCountdown,
            .onboardingRestartHint,
        ]

        for key in allKeys {
            let value = localization.localized(key)
            XCTAssertFalse(value.isEmpty, "LocalizationKey.\(key) returned an empty string")
        }
    }
}
