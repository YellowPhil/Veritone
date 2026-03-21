//
//  TranscriptDeliveryService.swift
//  Veritone
//
//  Delivers transcript text to the focused input or clipboard.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

enum TranscriptDeliveryResult: Equatable, Sendable {
    case pastedAndCopied
    case pasted
    case copiedToClipboard
    case copiedToClipboardAccessibilityUnavailable
    case copiedToClipboardPasteFailed

    var statusMessage: String {
        switch self {
        case .pastedAndCopied:
            return "Transcribed, pasted, and copied to the clipboard."
        case .pasted:
            return "Transcribed and pasted into the focused input."
        case .copiedToClipboard:
            return "Transcribed and copied to the clipboard."
        case .copiedToClipboardAccessibilityUnavailable:
            return "Transcribed and copied to the clipboard. Enable Accessibility access to paste into other apps."
        case .copiedToClipboardPasteFailed:
            return "Transcribed and copied to the clipboard because paste was unavailable."
        }
    }
}

@MainActor
final class TranscriptDeliveryService {
    func deliverTranscript(_ text: String, mode: TranscriptDeliveryMode) -> TranscriptDeliveryResult {
        switch mode {
        case .pasteAndKeepClipboard:
            copyToClipboard(text)

            guard isAccessibilityTrusted(promptIfNeeded: true) else {
                return .copiedToClipboardAccessibilityUnavailable
            }

            guard hasFocusedEditableTextInput() else {
                return .copiedToClipboard
            }

            return simulatePaste() ? .pastedAndCopied : .copiedToClipboardPasteFailed

        case .pasteOrCopyOnlyIfNoFocusedInput:
            guard isAccessibilityTrusted(promptIfNeeded: true) else {
                copyToClipboard(text)
                return .copiedToClipboardAccessibilityUnavailable
            }

            guard hasFocusedEditableTextInput() else {
                copyToClipboard(text)
                return .copiedToClipboard
            }

            let snapshot = snapshotClipboard()
            copyToClipboard(text)

            guard simulatePaste() else {
                restoreClipboard(snapshot)
                copyToClipboard(text)
                return .copiedToClipboardPasteFailed
            }

            restoreClipboard(snapshot)
            return .pasted
        }
    }

    private func isAccessibilityTrusted(promptIfNeeded: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: promptIfNeeded] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func hasFocusedEditableTextInput() -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElementValue: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementValue
        )

        guard focusedResult == .success, let focusedElementValue else {
            return false
        }

        let focusedElement = focusedElementValue as! AXUIElement

        if boolAttribute("AXEditable" as CFString, for: focusedElement) == true {
            return true
        }

        if supportsAttribute("AXSelectedTextRange" as CFString, for: focusedElement) {
            return true
        }

        guard let role = stringAttribute("AXRole" as CFString, for: focusedElement) else {
            return false
        }

        return editableRoles.contains(role)
    }

    private func stringAttribute(_ attribute: CFString, for element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        return value as? String
    }

    private func boolAttribute(_ attribute: CFString, for element: AXUIElement) -> Bool? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let number = value as? NSNumber else { return nil }
        return number.boolValue
    }

    private func supportsAttribute(_ attribute: CFString, for element: AXUIElement) -> Bool {
        var names: CFArray?
        let result = AXUIElementCopyAttributeNames(element, &names)
        guard result == .success, let names = names as? [String] else { return false }
        return names.contains(attribute as String)
    }

    private func simulatePaste() -> Bool {
        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let commandDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: true),
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true),
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false),
            let commandUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
        else {
            return false
        }

        vDown.flags = .maskCommand
        vUp.flags = .maskCommand

        commandDown.post(tap: .cghidEventTap)
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        commandUp.post(tap: .cghidEventTap)
        return true
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func snapshotClipboard() -> [NSPasteboardItem] {
        NSPasteboard.general.pasteboardItems?.map { $0.copy() as! NSPasteboardItem } ?? []
    }

    private func restoreClipboard(_ items: [NSPasteboardItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard !items.isEmpty else { return }
        pasteboard.writeObjects(items)
    }

    private let editableRoles: Set<String> = [
        kAXTextFieldRole as String,
        kAXTextAreaRole as String,
        kAXComboBoxRole as String,
        "AXSearchField",
    ]
}
