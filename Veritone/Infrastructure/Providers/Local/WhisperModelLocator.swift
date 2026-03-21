//
//  WhisperModelLocator.swift
//  Veritone
//
//  Checks whether WhisperKit has already cached a given model on disk.
//  WhisperKit (via swift-transformers HubApi) stores CoreML models at:
//    ~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/<variant>/
//  where <variant> is the model ID with "/" replaced by "_".
//

import Foundation

enum WhisperModelLocator {
    private enum DefaultsKey {
        static let downloadedModelIdentifiers = "downloaded_local_whisper_models"
    }

    // MARK: - Root path

    /// Base directory where WhisperKit caches downloaded models.
    static var whisperKitCacheDirectory: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
        return documents.appendingPathComponent(
            "huggingface/models/argmaxinc/whisperkit-coreml", isDirectory: true
        )
    }

    // MARK: - Lookup

    /// Returns the cached descriptor for the selected entry, if present.
    static func cachedModel(for entry: WhisperModelCatalog.Entry) -> WhisperModelDescriptor? {
        if isCached(entry) {
            return WhisperModelDescriptor(
                modelIdentifier: entry.modelIdentifier,
                displayName: entry.displayName,
                source: .cached,
                approximateSizeMB: entry.approximateSizeMB
            )
        }

        guard isMarkedDownloaded(entry) else { return nil }
        return WhisperModelDescriptor(
            modelIdentifier: entry.modelIdentifier,
            displayName: entry.displayName,
            source: .downloaded,
            approximateSizeMB: entry.approximateSizeMB
        )
    }

    /// Returns the best locally cached model, checking preferred order.
    static func findCachedModel() -> WhisperModelDescriptor? {
        for entry in WhisperModelCatalog.all {
            if let model = cachedModel(for: entry) {
                return model
            }
        }
        return nil
    }

    /// Returns true when the given catalog entry's model is on disk.
    static func isCached(_ entry: WhisperModelCatalog.Entry) -> Bool {
        let variantName = entry.modelIdentifier.replacingOccurrences(of: "/", with: "_")
        let path = whisperKitCacheDirectory.appendingPathComponent(variantName)
        return FileManager.default.fileExists(atPath: path.path)
    }

    static func markDownloaded(_ entry: WhisperModelCatalog.Entry) {
        var identifiers = Set(
            UserDefaults.standard.stringArray(forKey: DefaultsKey.downloadedModelIdentifiers) ?? []
        )
        identifiers.insert(entry.modelIdentifier)
        UserDefaults.standard.set(Array(identifiers).sorted(), forKey: DefaultsKey.downloadedModelIdentifiers)
    }

    private static func isMarkedDownloaded(_ entry: WhisperModelCatalog.Entry) -> Bool {
        let identifiers = Set(
            UserDefaults.standard.stringArray(forKey: DefaultsKey.downloadedModelIdentifiers) ?? []
        )
        return identifiers.contains(entry.modelIdentifier)
    }
}
