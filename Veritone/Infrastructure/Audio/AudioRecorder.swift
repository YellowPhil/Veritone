//
//  AudioRecorder.swift
//  Veritone
//
//  macOS microphone recording to a temp audio file.
//

import AVFoundation
import Foundation

/// State of the audio recorder.
enum AudioRecorderState: Equatable, Sendable {
    case idle
    case recording
    case stopped(url: URL)
    case failed(String)
}

/// Records microphone input to a temporary audio file.
@MainActor
final class AudioRecorder: NSObject, Sendable {
    private var audioEngine: AVAudioEngine?
    private var outputFile: AVAudioFile?
    private var tempFileURL: URL?

    private(set) var state: AudioRecorderState = .idle {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((AudioRecorderState) -> Void)?

    /// Request microphone permission. Call before recording.
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Start recording to a temp file.
    func startRecording() {
        guard case .idle = state else { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(UUID().uuidString).m4a"
        let url = tempDir.appendingPathComponent(fileName)

        do {
            let file = try AVAudioFile(
                forWriting: url,
                settings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ]
            )
            outputFile = file
            tempFileURL = url
            audioEngine = engine

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                try? self?.outputFile?.write(from: buffer)
            }
            try engine.start()
            state = .recording
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Stop recording and return the file URL.
    func stopRecording() -> URL? {
        guard case .recording = state else { return nil }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        outputFile = nil

        guard let url = tempFileURL else {
            state = .failed("No recording file")
            return nil
        }
        tempFileURL = nil
        state = .stopped(url: url)
        return url
    }

    /// Reset to idle (e.g. after discarding the recording).
    func reset() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        outputFile = nil
        tempFileURL = nil
        state = .idle
    }
}
