//
//  SenseVoiceService.swift
//  LaSay
//
//  Created by Tamio Tsiu on 2026/2/16.
//

import Foundation
import os.log

final class SenseVoiceService {
    static let shared = SenseVoiceService()

    private let modelQueue = DispatchQueue(label: "com.lasay.sensevoice.model")
    private var wrapper: SenseVoiceCppWrapper?
    private(set) var isModelLoaded: Bool = false
    private var isLoadingModel: Bool = false

    private init() {}

    // MARK: - Public

    /// Pre-load model into memory (call on app launch).
    func preloadModel(completion: ((Bool) -> Void)? = nil) {
        guard !isModelLoaded, !isLoadingModel else {
            completion?(isModelLoaded)
            return
        }
        guard let modelDir = Bundle.main.resourcePath else {
            AppLogger.transcription.error("SenseVoiceService: bundled model directory not found")
            completion?(false)
            return
        }

        AppLogger.transcription.info("SenseVoiceService: starting model preload")
        isLoadingModel = true
        modelQueue.async { [weak self] in
            guard let self = self else { return }
            let loaded = self.loadModelIfNeeded(from: modelDir) != nil
            DispatchQueue.main.async {
                if loaded {
                    AppLogger.transcription.info("SenseVoiceService: model loaded successfully")
                } else {
                    AppLogger.transcription.error("SenseVoiceService: model load failed")
                }
                self.isModelLoaded = loaded
                self.isLoadingModel = false
                completion?(loaded)
            }
        }
    }

    func transcribe(
        audioFileURL: URL,
        completion: @escaping (Result<String, WhisperError>) -> Void
    ) {
        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            completion(.failure(.invalidAudioFile))
            return
        }

        guard let modelDir = Bundle.main.resourcePath else {
            AppLogger.transcription.error("SenseVoiceService: bundled model directory not found")
            completion(.failure(.modelDownloadFailed))
            return
        }

        AppLogger.transcription.info("SenseVoiceService: starting transcription")
        modelQueue.async { [weak self] in
            guard let self = self else { return }

            // Convert to WAV if needed
            let wavURL: URL
            if audioFileURL.pathExtension.lowercased() != "wav" {
                guard let converted = AudioConverter.convertToWAV(inputURL: audioFileURL) else {
                    AppLogger.transcription.error("SenseVoiceService: audio conversion to WAV failed")
                    DispatchQueue.main.async { completion(.failure(.invalidAudioFile)) }
                    return
                }
                wavURL = converted
            } else {
                wavURL = audioFileURL
            }
            defer {
                if wavURL != audioFileURL {
                    try? FileManager.default.removeItem(at: wavURL)
                }
            }

            guard let wrapper = self.loadModelIfNeeded(from: modelDir) else {
                DispatchQueue.main.async { completion(.failure(.modelDownloadFailed)) }
                return
            }

            guard let text = wrapper.transcribe(wavURL: wavURL) else {
                AppLogger.transcription.error("SenseVoiceService: transcription returned nil result")
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }

            AppLogger.transcription.info("SenseVoiceService: transcription succeeded, length=\(text.count, privacy: .public) chars")
            DispatchQueue.main.async {
                self.isModelLoaded = true
                completion(.success(text))
            }
        }
    }

    private func loadModelIfNeeded(from modelDir: String) -> SenseVoiceCppWrapper? {
        if wrapper == nil {
            wrapper = SenseVoiceCppWrapper(modelDir: modelDir)
        }
        return wrapper
    }
}
