//
//  TranscriptDeliveryMode.swift
//  Veritone
//
//  Controls how finished transcripts are delivered to other apps.
//

import Foundation

enum TranscriptDeliveryMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case pasteAndKeepClipboard
    case pasteOrCopyOnlyIfNoFocusedInput

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pasteAndKeepClipboard:
            return "Paste and Keep Clipboard"
        case .pasteOrCopyOnlyIfNoFocusedInput:
            return "Paste, Copy Only If No Input"
        }
    }

    var detailText: String {
        switch self {
        case .pasteAndKeepClipboard:
            return "Paste into the focused text input when available, and also keep the transcript on the clipboard."
        case .pasteOrCopyOnlyIfNoFocusedInput:
            return "Paste into the focused text input when available. If no editable input is focused, copy the transcript to the clipboard instead."
        }
    }
}
