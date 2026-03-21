//
//  RecordingShortcutConfiguration.swift
//  Veritone
//
//  Persisted recording shortcut mode plus KeyboardShortcuts registration.
//

import AppKit
import Foundation
import KeyboardShortcuts

enum RecordingShortcutDefaults {
    static let modeStorageKey = "recording_shortcut_mode"
    static let initialShortcut = KeyboardShortcuts.Shortcut(.space, modifiers: [.control, .option])
}

extension KeyboardShortcuts.Name {
    static let recordingShortcut = Self(
        "recordingShortcut",
        default: RecordingShortcutDefaults.initialShortcut
    )
}

enum RecordingShortcutMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case pushToTalk
    case toggleRecording

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pushToTalk:
            return "Push to Talk"
        case .toggleRecording:
            return "Toggle Recording"
        }
    }

    var detailText: String {
        switch self {
        case .pushToTalk:
            return "Hold the shortcut to record, then release it to stop and transcribe."
        case .toggleRecording:
            return "Press the shortcut once to start recording, then press it again to stop and transcribe."
        }
    }
}
