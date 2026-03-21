//
//  AudioPCMConverter.swift
//  Veritone
//
//  Converts any audio file to 16 kHz mono Float32 PCM samples,
//  which is the exact format required by whisper.cpp.
//

import AVFoundation
import Foundation

enum AudioPCMConverterError: Error, LocalizedError {
    case noAudioTrack
    case readerStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No audio track found in the recorded file."
        case .readerStartFailed(let reason):
            return "Audio reader could not start: \(reason)"
        }
    }
}

enum AudioPCMConverter {
    /// Reads an audio file and returns 16 kHz mono Float32 PCM samples.
    static func toMonoFloat32(_ url: URL, sampleRate: Double = 16_000) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw AudioPCMConverterError.noAudioTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)

        guard reader.startReading() else {
            throw AudioPCMConverterError.readerStartFailed(
                reader.error?.localizedDescription ?? "unknown reason"
            )
        }

        var samples: [Float] = []
        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            let byteCount = CMBlockBufferGetDataLength(blockBuffer)
            var data = Data(count: byteCount)
            _ = data.withUnsafeMutableBytes { ptr in
                CMBlockBufferCopyDataBytes(
                    blockBuffer, atOffset: 0, dataLength: byteCount,
                    destination: ptr.baseAddress!
                )
            }
            data.withUnsafeBytes { ptr in
                samples.append(contentsOf: ptr.bindMemory(to: Float.self))
            }
            CMSampleBufferInvalidate(sampleBuffer)
        }

        return samples
    }
}
