//
//  SpeechToTextProvider.swift
//  Veritone
//
//  Protocol, provider ID, and availability model for pluggable STT backends.
//

import Foundation

// MARK: - Provider ID

/// Identifies a speech-to-text provider for selection in the UI.
enum SpeechToTextProviderID: String, CaseIterable, Sendable {
    case openAIWhisper = "openai_whisper"
    case localWhisper = "local_whisper"
    case parakeet = "parakeet"

    var displayName: String {
        switch self {
        case .openAIWhisper: return "OpenAI Whisper"
        case .localWhisper: return "Local Whisper"
        case .parakeet: return "NVIDIA Parakeet"
        }
    }
}

// MARK: - Availability

/// Whether a provider is ready to accept transcription requests.
enum ProviderAvailability: Equatable, Sendable {
    case available(detail: String)
    case requiresAPIKey
    /// Local model needs to be downloaded first.
    case requiresLocalModel(displayName: String, approximateSizeMB: Int)
    case unavailable(reason: String)

    var isReady: Bool {
        if case .available = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .available(let detail): return detail
        case .requiresAPIKey: return "API key required"
        case .requiresLocalModel(let name, let mb):
            return "Model not installed (\(name), ~\(mb) MB)"
        case .unavailable(let reason): return reason
        }
    }
}

// MARK: - Protocol

/// Protocol for pluggable speech-to-text providers.
protocol SpeechToTextProvider: Sendable {
    var id: SpeechToTextProviderID { get }
    /// Current readiness state of the provider.
    var availability: ProviderAvailability { get }
    /// Transcribe the given audio file.
    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult
}
