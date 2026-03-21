//
//  ProviderRegistry.swift
//  Veritone
//
//  Factory and availability checker for speech-to-text providers.
//

import Foundation

// MARK: - Registry

enum ProviderRegistry {
    private static var localWhisperProviders: [String: LocalWhisperProvider] = [:]

    /// Returns an instantiated provider if the provider is ready, otherwise nil.
    static func makeProvider(
        id: SpeechToTextProviderID,
        config: TranscriptionConfig,
        localModelEntry: WhisperModelCatalog.Entry = WhisperModelCatalog.default
    ) -> (any SpeechToTextProvider)? {
        switch id {
        case .openAIWhisper:
            guard let key = config.openAIAPIKey, !key.isEmpty else { return nil }
            return OpenAIWhisperProvider(apiKey: key)
        case .localWhisper:
            guard let model = WhisperModelLocator.cachedModel(for: localModelEntry) else { return nil }
            if let existing = localWhisperProviders[model.modelIdentifier] {
                return existing
            }

            let provider = LocalWhisperProvider(modelDescriptor: model)
            localWhisperProviders[model.modelIdentifier] = provider
            return provider
        case .parakeet:
            return ParakeetProvider()
        }
    }

    /// Evaluates readiness without constructing the full provider object.
    static func availability(
        for id: SpeechToTextProviderID,
        config: TranscriptionConfig,
        localModelEntry: WhisperModelCatalog.Entry = WhisperModelCatalog.default
    ) -> ProviderAvailability {
        switch id {
        case .openAIWhisper:
            guard let key = config.openAIAPIKey, !key.isEmpty else {
                return .requiresAPIKey
            }
            return .available(detail: "OpenAI API · whisper-1")

        case .localWhisper:
            if let model = WhisperModelLocator.cachedModel(for: localModelEntry) {
                return .available(detail: "\(model.displayName) · \(model.sourceLabel)")
            }
            return .requiresLocalModel(
                displayName: localModelEntry.displayName,
                approximateSizeMB: localModelEntry.approximateSizeMB
            )

        case .parakeet:
            return .unavailable(reason: "Not yet implemented (NeMo / NVIDIA GPU required)")
        }
    }
}

// MARK: - Config

/// Lightweight configuration for transcription providers.
struct TranscriptionConfig: Sendable {
    var openAIAPIKey: String?

    static func load() -> TranscriptionConfig {
        let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? UserDefaults.standard.string(forKey: "openai_api_key")
        return TranscriptionConfig(openAIAPIKey: key?.isEmpty == true ? nil : key)
    }

    static func setOpenAIAPIKey(_ key: String?) {
        if let key, !key.isEmpty {
            UserDefaults.standard.set(key, forKey: "openai_api_key")
        } else {
            UserDefaults.standard.removeObject(forKey: "openai_api_key")
        }
    }
}
