//
//  TranscriptionModels.swift
//  Veritone
//
//  Shared request/result models for speech-to-text transcription.
//

import Foundation

/// Normalized request passed to any speech-to-text provider.
struct TranscriptionRequest: Sendable {
    /// URL to the audio file (local temp file or imported file).
    let audioFileURL: URL
    /// Optional language hint (e.g. "en", "en-US").
    let languageHint: String?
    /// Optional model identifier for providers that support multiple models.
    let modelHint: String?

    init(audioFileURL: URL, languageHint: String? = nil, modelHint: String? = nil) {
        self.audioFileURL = audioFileURL
        self.languageHint = languageHint
        self.modelHint = modelHint
    }
}

/// Result returned by a speech-to-text provider.
struct TranscriptionResult: Sendable {
    /// The transcribed text.
    let text: String
    /// Duration of the audio in seconds, if known.
    let durationSeconds: Double?
    /// Whether word-level or segment-level timestamps are available.
    let hasTimestamps: Bool
    /// Provider identifier used.
    let providerID: SpeechToTextProviderID
    /// Model identifier used, if applicable.
    let modelUsed: String?

    init(
        text: String,
        durationSeconds: Double? = nil,
        hasTimestamps: Bool = false,
        providerID: SpeechToTextProviderID,
        modelUsed: String? = nil
    ) {
        self.text = text
        self.durationSeconds = durationSeconds
        self.hasTimestamps = hasTimestamps
        self.providerID = providerID
        self.modelUsed = modelUsed
    }
}
