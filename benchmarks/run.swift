import AVFoundation
import Foundation

struct Clip {
    let sampleID: String
    let audio: String
    let transcript: String
    let durationSeconds: Double
}

func loadClips(from manifest: URL) throws -> [Clip] {
    let lines = try String(contentsOf: manifest, encoding: .utf8).split(whereSeparator: \.isNewline)
    return try lines.map { line in
        guard let object = try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
              let sampleID = object["sample_id"] as? String,
              let audio = object["audio"] as? String,
              let transcript = object["transcript"] as? String,
              let duration = object["duration_seconds"] as? NSNumber else {
            throw NSError(domain: "LaSayBenchmark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid manifest: \(manifest.path)"])
        }
        return Clip(sampleID: sampleID, audio: audio, transcript: transcript, durationSeconds: duration.doubleValue)
    }
}

func jsonLine(_ object: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    return String(decoding: data, as: UTF8.self) + "\n"
}

func category(for sampleID: String) -> String {
    ["english_clean", "english_other", "chinese", "mixed"].first { sampleID.hasPrefix("\($0)-") } ?? "unknown"
}

func run() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    guard CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--output" else {
        throw NSError(domain: "LaSayBenchmark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Usage: LaSayBenchmark --output <results.jsonl>"])
    }

    let manifests = ["chinese", "english_clean", "english_other", "mixed"].map {
        root.appendingPathComponent("benchmarks/data/\($0).jsonl")
    }
    let clips = try manifests.flatMap(loadClips)
    let output = URL(fileURLWithPath: CommandLine.arguments[2], relativeTo: root)
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)

    let modelDirectory = root.appendingPathComponent("LaSay/LaSay/Resources/SenseVoiceModel")
    let modelStart = Date()
    guard let recognizer = SenseVoiceCppWrapper(modelDir: modelDirectory.path) else {
        throw NSError(domain: "LaSayBenchmark", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not load bundled SenseVoice model"])
    }
    let modelLoadSeconds = Date().timeIntervalSince(modelStart)
    var lines = [try jsonLine([
        "type": "run", "model": "SenseVoice model.int8.onnx", "model_load_seconds": modelLoadSeconds,
        "clip_count": clips.count, "started_at": ISO8601DateFormatter().string(from: Date()),
    ])]

    for (index, clip) in clips.enumerated() {
        let audioURL = root.appendingPathComponent("benchmarks/\(clip.audio)")
        let pipelineStart = Date()
        var convertedURL: URL?
        let wavURL: URL
        if audioURL.pathExtension.lowercased() == "wav" {
            wavURL = audioURL
        } else if let converted = AudioConverter.convertToWAV(inputURL: audioURL) {
            wavURL = converted
            convertedURL = converted
        } else {
            lines.append(try jsonLine(["type": "clip", "sample_id": clip.sampleID,
                                       "category": category(for: clip.sampleID), "reference": clip.transcript,
                                       "error": "audio conversion failed"]))
            continue
        }
        defer {
            if let convertedURL { try? FileManager.default.removeItem(at: convertedURL) }
        }

        let transcriptionStart = Date()
        let rawHypothesis = recognizer.transcribe(wavURL: wavURL)
        // The app normalizes SenseVoice's Simplified Chinese output before showing it.
        let hypothesis = rawHypothesis?.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? rawHypothesis
        let transcriptionSeconds = Date().timeIntervalSince(transcriptionStart)
        let pipelineSeconds = Date().timeIntervalSince(pipelineStart)
        lines.append(try jsonLine([
            "type": "clip", "sample_id": clip.sampleID, "category": category(for: clip.sampleID),
            "reference": clip.transcript,
            "normalized_reference": clip.transcript.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? clip.transcript,
            "raw_hypothesis": rawHypothesis ?? "", "hypothesis": hypothesis ?? "",
            "duration_seconds": clip.durationSeconds, "transcription_seconds": transcriptionSeconds,
            "pipeline_seconds": pipelineSeconds,
            "error": hypothesis == nil ? "transcription failed" : "",
        ]))
        print("[\(index + 1)/\(clips.count)] \(clip.sampleID) \(String(format: "%.2f", pipelineSeconds))s")
    }

    try lines.joined().write(to: output, atomically: true, encoding: .utf8)
    print("Wrote \(output.path)")
}

@main
struct LaSayBenchmark {
    static func main() {
        do {
            try run()
        } catch {
            fputs("LaSay benchmark failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
