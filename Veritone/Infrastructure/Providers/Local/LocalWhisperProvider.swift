//
//  LocalWhisperProvider.swift
//  Veritone
//
//  Real local speech-to-text provider backed by WhisperKit.
//  Runs Whisper inference fully on-device using Core ML / Accelerate.
//

import Foundation

struct LocalWhisperProvider: SpeechToTextProvider {
    let id: SpeechToTextProviderID = .localWhisper
    private let modelDescriptor: WhisperModelDescriptor
    private let runtime: WhisperRuntime

    init(modelDescriptor: WhisperModelDescriptor) {
        self.modelDescriptor = modelDescriptor
        self.runtime = WhisperRuntime(modelIdentifier: modelDescriptor.modelIdentifier)
    }

    var availability: ProviderAvailability {
        .available(detail: "\(modelDescriptor.displayName) · \(modelDescriptor.sourceLabel)")
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        let text = try await runtime.transcribe(audioURL: request.audioFileURL)
        return TranscriptionResult(
            text: text,
            hasTimestamps: false,
            providerID: id,
            modelUsed: modelDescriptor.modelIdentifier
        )
    }
}
