//
//  ParakeetProvider.swift
//  Veritone
//
//  Placeholder for NVIDIA Parakeet (NeMo on Linux/NVIDIA).
//  Ready for future external runtime integration.
//

import Foundation

struct ParakeetProvider: SpeechToTextProvider, Sendable {
    let id: SpeechToTextProviderID = .parakeet

    var availability: ProviderAvailability {
        .unavailable(reason: "Not yet implemented (NeMo / NVIDIA GPU required)")
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        throw TranscriptionError.providerNotImplemented(provider: id.displayName)
    }
}
