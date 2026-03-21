//
//  WhisperModelDownloader.swift
//  Veritone
//
//  Downloads a Whisper model by initialising WhisperKit with the model identifier.
//  WhisperKit pulls the CoreML model files from Hugging Face and caches them
//  under ~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/<variant>/.
//  Exposes Observable state for SwiftUI progress binding.
//

import Foundation
import Observation
import WhisperKit

@MainActor
@Observable
final class WhisperModelDownloader {
    enum DownloadState: Equatable {
        case idle
        case downloading
        case done
        case failed(String)
    }

    private(set) var state: DownloadState = .idle

    var isDownloading: Bool { state == .downloading }

    /// Triggers a WhisperKit model download for the given catalog entry.
    func download(_ entry: WhisperModelCatalog.Entry) async {
        guard !isDownloading else { return }
        state = .downloading

        do {
            _ = try await WhisperKit(
                model: entry.modelIdentifier,
                verbose: false,
                logLevel: .none,
                prewarm: false,
                load: false,
                download: true
            )
            WhisperModelLocator.markDownloaded(entry)
            state = .done
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reset() {
        state = .idle
    }
}
