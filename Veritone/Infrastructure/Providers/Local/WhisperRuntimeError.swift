//
//  WhisperRuntimeError.swift
//  Veritone
//
//  Errors surfaced by the local Whisper runtime layer.
//

import Foundation

enum WhisperRuntimeError: Error, LocalizedError {
    case pipelineInitFailed(String)
    case transcriptionReturnedEmpty

    var errorDescription: String? {
        switch self {
        case .pipelineInitFailed(let reason):
            return "Failed to initialise Whisper pipeline: \(reason)"
        case .transcriptionReturnedEmpty:
            return "Transcription produced no text."
        }
    }
}
