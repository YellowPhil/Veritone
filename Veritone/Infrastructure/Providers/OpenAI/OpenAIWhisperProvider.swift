//
//  OpenAIWhisperProvider.swift
//  Veritone
//
//  Speech-to-text via OpenAI Audio Transcriptions API.
//

import Alamofire
import Foundation

struct OpenAIWhisperProvider: SpeechToTextProvider, Sendable {
    let id: SpeechToTextProviderID = .openAIWhisper
    private let apiKey: String?

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    var availability: ProviderAvailability {
        guard let key = apiKey, !key.isEmpty else { return .requiresAPIKey }
        return .available(detail: "OpenAI API · whisper-1")
    }

    func transcribe(_ request: TranscriptionRequest) async throws -> TranscriptionResult {
        guard let apiKey, !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey(provider: id.displayName)
        }

        let url = "https://api.openai.com/v1/audio/transcriptions"
        let headers: HTTPHeaders = [
            .authorization(bearerToken: apiKey),
        ]

        let audioData = try Data(contentsOf: request.audioFileURL)
        let fileName = request.audioFileURL.lastPathComponent
        let mimeType = mimeTypeForFileExtension(request.audioFileURL.pathExtension)

        let uploadRequest = AF.upload(
            multipartFormData: { formData in
                formData.append(audioData, withName: "file", fileName: fileName, mimeType: mimeType)
                formData.append("whisper-1".data(using: .utf8)!, withName: "model")
                if let lang = request.languageHint, !lang.isEmpty {
                    formData.append(lang.data(using: .utf8)!, withName: "language")
                }
            },
            to: url,
            headers: headers
        )

        let dataResponse = await withTaskCancellationHandler {
            await uploadRequest
                .serializingData()
                .response
        } onCancel: {
            uploadRequest.cancel()
        }

        try Task.checkCancellation()

        if let statusCode = dataResponse.response?.statusCode, statusCode != 200 {
            let message = String(data: dataResponse.data ?? Data(), encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.apiError(statusCode: statusCode, message: message)
        }

        if let error = dataResponse.error {
            throw TranscriptionError.apiError(statusCode: 0, message: error.localizedDescription)
        }

        guard let data = dataResponse.data else {
            throw TranscriptionError.unknown
        }

        struct OpenAIResponse: Decodable {
            let text: String
        }
        let decoded = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        return TranscriptionResult(
            text: decoded.text,
            hasTimestamps: false,
            providerID: id,
            modelUsed: "whisper-1"
        )
    }

    private func mimeTypeForFileExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "m4a", "mp4": return "audio/mp4"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        case "webm": return "audio/webm"
        default: return "audio/mp4"
        }
    }
}

enum TranscriptionError: Error, LocalizedError {
    case missingAPIKey(provider: String)
    case apiError(statusCode: Int, message: String)
    case providerNotImplemented(provider: String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider): return "API key required for \(provider). Set OPENAI_API_KEY or add in settings."
        case .apiError(let code, let msg): return "API error (\(code)): \(msg)"
        case .providerNotImplemented(let provider): return "\(provider) is not yet implemented."
        case .unknown: return "Unknown transcription error"
        }
    }
}
