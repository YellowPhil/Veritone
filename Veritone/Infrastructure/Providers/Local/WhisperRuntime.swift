//
//  WhisperRuntime.swift
//  Veritone
//
//  Actor-isolated wrapper around WhisperKit.
//  Keeps a single loaded pipeline per model for the session lifetime,
//  so model weights are loaded only once per launch.
//

import Foundation
import WhisperKit

actor WhisperRuntime {
    private let modelIdentifier: String
    private var pipeline: WhisperKit?

    init(modelIdentifier: String) {
        self.modelIdentifier = modelIdentifier
    }

    /// Eagerly loads the pipeline so the first transcription does not pay the initialization cost.
    func warmUp() async throws {
        try await loadPipelineIfNeeded()
    }

    /// Transcribes the audio file at the given URL and returns the full text.
    func transcribe(audioURL: URL) async throws -> String {
        try Task.checkCancellation()
        let kit = try await loadPipelineIfNeeded()
        try Task.checkCancellation()
        let results = try await kit.transcribe(audioPath: audioURL.path)
        try Task.checkCancellation()
        return results
            .map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func loadPipelineIfNeeded() async throws -> WhisperKit {
        if let existing = pipeline { return existing }

        do {
            let kit = try await WhisperKit(model: modelIdentifier, verbose: false)
            pipeline = kit
            return kit
        } catch {
            throw WhisperRuntimeError.pipelineInitFailed(error.localizedDescription)
        }
    }
}
