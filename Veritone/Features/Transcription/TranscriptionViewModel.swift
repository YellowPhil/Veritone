//
//  TranscriptionViewModel.swift
//  Veritone
//
//  View model for the transcription screen.
//

import Foundation
import KeyboardShortcuts
import SwiftUI

// MARK: - UI State

enum TranscriptionUIState: Equatable {
    case idle
    case recording
    case transcribing
    case success(transcript: String)
    case failure(message: String)
}

// MARK: - View Model

@MainActor
@Observable
final class TranscriptionViewModel {
    // MARK: Provider selection

    private enum DefaultsKey {
        static let selectedProvider = "selected_stt_provider"
        static let selectedLocalWhisperModel = "selected_local_whisper_model"
        static let transcriptDeliveryMode = "transcript_delivery_mode"
    }

    var selectedProviderID: SpeechToTextProviderID {
        didSet {
            UserDefaults.standard.set(selectedProviderID.rawValue, forKey: DefaultsKey.selectedProvider)
            refreshConfig()
        }
    }

    var selectedLocalModelIdentifier: String {
        didSet {
            UserDefaults.standard.set(
                selectedLocalModelIdentifier,
                forKey: DefaultsKey.selectedLocalWhisperModel
            )
            downloader.reset()
        }
    }

    var recordingShortcutMode: RecordingShortcutMode {
        didSet {
            UserDefaults.standard.set(
                recordingShortcutMode.rawValue,
                forKey: RecordingShortcutDefaults.modeStorageKey
            )
        }
    }

    var transcriptDeliveryMode: TranscriptDeliveryMode {
        didSet {
            UserDefaults.standard.set(
                transcriptDeliveryMode.rawValue,
                forKey: DefaultsKey.transcriptDeliveryMode
            )
        }
    }

    private(set) var recordingShortcutDisplayLabel: String
    private(set) var lastDeliveryStatusMessage: String?

    // MARK: Transcription state

    var uiState: TranscriptionUIState = .idle
    var transcript: String = ""

    // MARK: Model download

    let downloader = WhisperModelDownloader()

    // MARK: Private

    private let recorder = AudioRecorder()
    private let transcriptDeliveryService = TranscriptDeliveryService()
    private var config: TranscriptionConfig
    private var isShortcutHandlingEnabled = true
    private var activeTranscriptionTask: Task<Void, Never>?
    private var activeTranscriptionRunID: UUID?

    // MARK: Init

    init() {
        let raw = UserDefaults.standard.string(forKey: DefaultsKey.selectedProvider)
            ?? SpeechToTextProviderID.openAIWhisper.rawValue
        selectedProviderID = SpeechToTextProviderID(rawValue: raw) ?? .openAIWhisper
        selectedLocalModelIdentifier = UserDefaults.standard.string(
            forKey: DefaultsKey.selectedLocalWhisperModel
        ) ?? WhisperModelCatalog.default.modelIdentifier
        recordingShortcutMode = Self.loadRecordingShortcutMode()
        transcriptDeliveryMode = Self.loadTranscriptDeliveryMode()
        recordingShortcutDisplayLabel = Self.recordingShortcutLabel()
        lastDeliveryStatusMessage = nil
        config = TranscriptionConfig.load()

        recorder.onStateChange = { [weak self] state in
            Task { @MainActor in
                self?.handleRecorderState(state)
            }
        }

        if selectedProviderID == .localWhisper {
            Task { [weak self] in
                guard let self else { return }
                if let provider = ProviderRegistry.makeProvider(
                    id: .localWhisper,
                    config: config,
                    localModelEntry: selectedLocalModel
                ) as? LocalWhisperProvider {
                    try? await provider.warmUp()
                }
            }
        }

        Task { [weak self] in
            for await _ in KeyboardShortcuts.events(.keyDown, for: .recordingShortcut) {
                self?.handleShortcutPress()
            }
        }

        Task { [weak self] in
            for await _ in KeyboardShortcuts.events(.keyUp, for: .recordingShortcut) {
                self?.handleShortcutRelease()
            }
        }
    }

    // MARK: - Computed

    var statusMessage: String { statusMessageForState(uiState) }

    var canStartRecording: Bool {
        guard currentAvailability.isReady else { return false }
        switch uiState {
        case .idle, .success, .failure: return true
        default: return false
        }
    }

    var canStopRecording: Bool { uiState == .recording }
    var hasTranscript: Bool { !transcript.isEmpty }
    var recordingShortcutSummary: String {
        "\(recordingShortcutDisplayLabel) · \(recordingShortcutMode.displayName)"
    }
    var transcriptDeliverySummary: String { transcriptDeliveryMode.displayName }

    var openAIAPIKey: String {
        get { config.openAIAPIKey ?? "" }
        set {
            TranscriptionConfig.setOpenAIAPIKey(newValue.isEmpty ? nil : newValue)
            config = TranscriptionConfig.load()
        }
    }

    var showAPIKeyField: Bool { selectedProviderID == .openAIWhisper }
    var showLocalModelPicker: Bool { selectedProviderID == .localWhisper }
    var availableLocalModels: [WhisperModelCatalog.Entry] { WhisperModelCatalog.all }
    var selectedLocalModel: WhisperModelCatalog.Entry {
        WhisperModelCatalog.entry(for: selectedLocalModelIdentifier) ?? WhisperModelCatalog.default
    }

    // MARK: - Availability

    /// Live availability for the currently selected provider.
    var currentAvailability: ProviderAvailability {
        ProviderRegistry.availability(
            for: selectedProviderID,
            config: config,
            localModelEntry: selectedLocalModel
        )
    }

    /// Human-readable detail line shown below the provider picker.
    var providerDetailText: String {
        switch selectedProviderID {
        case .localWhisper:
            switch downloader.state {
            case .downloading:
                return "Downloading \(selectedLocalModel.displayName)…"
            case .done:
                return WhisperModelLocator.cachedModel(for: selectedLocalModel)
                    .map { "\($0.displayName) · \($0.sourceLabel)" }
                    ?? "Model installed – restart to use"
            case .failed(let msg):
                return "Download failed: \(msg)"
            case .idle:
                return currentAvailability.statusText
            }
        default:
            return currentAvailability.statusText
        }
    }

    var showDownloadButton: Bool {
        guard selectedProviderID == .localWhisper else { return false }
        if case .requiresLocalModel = currentAvailability { return !downloader.isDownloading }
        return false
    }

    var downloadCatalogEntry: WhisperModelCatalog.Entry { selectedLocalModel }

    // MARK: - Actions

    func refreshConfig() {
        config = TranscriptionConfig.load()
    }

    func requestPermissionAndRecord() async {
        guard currentAvailability.isReady else { return }

        if uiState == .transcribing {
            cancelActiveTranscription(resetStateToIdle: true)
        }

        guard canStartRecording else { return }
        refreshConfig()
        let granted = await recorder.requestPermission()
        guard granted else {
            uiState = .failure(message: "Microphone access denied.")
            return
        }
        recorder.reset()
        recorder.startRecording()
    }

    func stopRecordingAndTranscribe() {
        guard canStopRecording else { return }
        guard let url = recorder.stopRecording() else { return }
        transcribe(url: url)
    }

    func downloadModel() {
        Task {
            await downloader.download(downloadCatalogEntry)
        }
    }

    func clear() {
        cancelActiveTranscription(resetStateToIdle: false)
        transcript = ""
        uiState = .idle
        lastDeliveryStatusMessage = nil
        recorder.reset()
    }

    func setShortcutHandlingEnabled(_ isEnabled: Bool) {
        isShortcutHandlingEnabled = isEnabled
    }

    func resetRecordingShortcutToDefault() {
        recordingShortcutMode = .toggleRecording
        KeyboardShortcuts.Name.recordingShortcut.shortcut = RecordingShortcutDefaults.initialShortcut
        refreshRecordingShortcutDisplay()
    }

    func refreshRecordingShortcutDisplay() {
        recordingShortcutDisplayLabel = Self.recordingShortcutLabel()
    }

    // MARK: - Private

    private func handleRecorderState(_ state: AudioRecorderState) {
        switch state {
        case .idle: break
        case .recording: uiState = .recording
        case .stopped: break
        case .failed(let msg): uiState = .failure(message: msg)
        }
    }

    private func handleShortcutPress() {
        guard isShortcutHandlingEnabled else { return }

        if uiState == .transcribing {
            Task { await requestPermissionAndRecord() }
            return
        }

        switch recordingShortcutMode {
        case .pushToTalk:
            guard canStartRecording else { return }
            Task { await requestPermissionAndRecord() }
        case .toggleRecording:
            if canStopRecording {
                stopRecordingAndTranscribe()
            } else if canStartRecording {
                Task { await requestPermissionAndRecord() }
            }
        }
    }

    private func handleShortcutRelease() {
        guard isShortcutHandlingEnabled else { return }
        guard recordingShortcutMode == .pushToTalk else { return }
        guard canStopRecording else { return }
        stopRecordingAndTranscribe()
    }

    private static func loadRecordingShortcutMode() -> RecordingShortcutMode {
        guard
            let rawValue = UserDefaults.standard.string(forKey: RecordingShortcutDefaults.modeStorageKey),
            let mode = RecordingShortcutMode(rawValue: rawValue)
        else {
            return .toggleRecording
        }

        return mode
    }

    private static func recordingShortcutLabel() -> String {
        KeyboardShortcuts.Name.recordingShortcut.shortcut?.description ?? "Not Set"
    }

    private static func loadTranscriptDeliveryMode() -> TranscriptDeliveryMode {
        guard
            let rawValue = UserDefaults.standard.string(forKey: DefaultsKey.transcriptDeliveryMode),
            let mode = TranscriptDeliveryMode(rawValue: rawValue)
        else {
            return .pasteAndKeepClipboard
        }

        return mode
    }

    private func transcribe(url: URL) {
        cancelActiveTranscription(resetStateToIdle: false)

        uiState = .transcribing
        let runID = UUID()
        activeTranscriptionRunID = runID

        activeTranscriptionTask = Task { [weak self] in
            guard let self else {
                try? FileManager.default.removeItem(at: url)
                return
            }

            defer {
                try? FileManager.default.removeItem(at: url)
            }

            do {
                guard let provider = ProviderRegistry.makeProvider(
                    id: selectedProviderID,
                    config: config,
                    localModelEntry: selectedLocalModel
                ) else {
                    guard activeTranscriptionRunID == runID else { return }
                    uiState = .failure(message: currentAvailability.statusText)
                    activeTranscriptionTask = nil
                    activeTranscriptionRunID = nil
                    return
                }

                let result = try await provider.transcribe(
                    TranscriptionRequest(audioFileURL: url)
                )

                guard !Task.isCancelled, activeTranscriptionRunID == runID else { return }

                transcript = result.text
                let deliveryResult = transcriptDeliveryService.deliverTranscript(
                    result.text,
                    mode: transcriptDeliveryMode
                )
                lastDeliveryStatusMessage = deliveryResult.statusMessage
                uiState = .success(transcript: result.text)
                activeTranscriptionTask = nil
                activeTranscriptionRunID = nil
            } catch is CancellationError {
                guard activeTranscriptionRunID == runID else { return }
                activeTranscriptionTask = nil
                activeTranscriptionRunID = nil
            } catch {
                guard activeTranscriptionRunID == runID else { return }
                uiState = .failure(message: error.localizedDescription)
                activeTranscriptionTask = nil
                activeTranscriptionRunID = nil
            }
        }
    }

    private func cancelActiveTranscription(resetStateToIdle: Bool) {
        activeTranscriptionTask?.cancel()
        activeTranscriptionTask = nil
        activeTranscriptionRunID = nil

        if resetStateToIdle {
            lastDeliveryStatusMessage = nil
            uiState = .idle
        }
    }

    private func statusMessageForState(_ state: TranscriptionUIState) -> String {
        switch state {
        case .idle:
            return currentAvailability.isReady
                ? "Ready. Use the buttons or your recording shortcut."
                : providerDetailText
        case .recording: return "Recording…"
        case .transcribing: return "Transcribing…"
        case .success: return lastDeliveryStatusMessage ?? "Done."
        case .failure(let msg): return msg
        }
    }
}
