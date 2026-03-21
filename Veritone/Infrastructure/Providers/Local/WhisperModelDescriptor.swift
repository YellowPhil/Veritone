//
//  WhisperModelDescriptor.swift
//  Veritone
//
//  Describes a Whisper model by its WhisperKit Hugging Face identifier,
//  display name, and approximate download size.
//

import Foundation

/// Where the model originates for display in the UI.
enum WhisperModelSource: Sendable {
    case downloaded
    case cached
}

/// Metadata for a local Whisper model known to the app.
struct WhisperModelDescriptor: Sendable {
    /// WhisperKit model identifier, e.g. "openai/whisper-tiny.en"
    let modelIdentifier: String
    let displayName: String
    let source: WhisperModelSource
    let approximateSizeMB: Int

    var sourceLabel: String {
        switch source {
        case .downloaded: return "Downloaded"
        case .cached: return "Cached"
        }
    }
}

/// Known Whisper models available for local inference via WhisperKit.
enum WhisperModelCatalog {
    struct Entry: Sendable, Equatable {
        /// WhisperKit / Hugging Face model ID.
        let modelIdentifier: String
        let displayName: String
        let approximateSizeMB: Int
    }

    static let whisperLarge = Entry(
        modelIdentifier: "large-v3",
        displayName: "Whisper Large (Multilingual)",
        approximateSizeMB: 3096
    )

    static let whisperMedium = Entry(
        modelIdentifier: "medium",
        displayName: "Whisper Medium (Multilingual)",
        approximateSizeMB: 1600
    )

    static let whisperSmall = Entry(
        modelIdentifier: "small",
        displayName: "Whisper Small (Multilingual)",
        approximateSizeMB: 486
    )

    static let all: [Entry] = [
        whisperSmall,
        whisperMedium,
        whisperLarge,
    ]

    /// Default model offered to the user on first run.
    static let `default` = whisperMedium

    static func entry(for modelIdentifier: String) -> Entry? {
        all.first { $0.modelIdentifier == modelIdentifier }
    }
}
