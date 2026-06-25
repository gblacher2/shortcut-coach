import AppKit
import Foundation

public struct ShortcutCatalog: Decodable, Sendable {
    public let metadata: CatalogMetadata
    public let shortcuts: [ShortcutItem]
}

public struct CatalogMetadata: Decodable, Sendable {
    public let generatedAt: String
    public let macOSVersion: String
    public let selectedKarabinerProfile: String?
    public let counts: CatalogCounts
}

public struct CatalogCounts: Decodable, Sendable {
    public let total: Int
    public let karabiner: Int
    public let priority1: Int
}

public struct ShortcutItem: Decodable, Identifiable, Hashable, Sendable {
    public let id: String
    public let shortcut: String
    public let action: String
    public let source: String
    public let scope: String
    public let priority: Int
    public let context: String
    public let active: Bool
    public let sends: String
    public let notes: String
    public let practicePrompt: String

    public var priorityLabel: String {
        switch priority {
        case 1:
            "Daily"
        case 2:
            "Weekly"
        default:
            "Reference"
        }
    }
}

public extension ShortcutItem {
    func matches(flags: NSEvent.ModifierFlags, charsIgnoringModifiers chars: String) -> Bool {
        let parts = shortcut.components(separatedBy: "+").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var expectedModifiers = NSEvent.ModifierFlags()
        var expectedKey = ""

        for part in parts {
            let lower = part.lowercased()
            if lower == "command" || lower == "cmd" || lower == "⌘" {
                expectedModifiers.insert(.command)
            } else if lower == "shift" || lower == "⇧" {
                expectedModifiers.insert(.shift)
            } else if lower == "option" || lower == "alt" || lower == "⌥" {
                expectedModifiers.insert(.option)
            } else if lower == "control" || lower == "ctrl" || lower == "⌃" {
                expectedModifiers.insert(.control)
            } else if lower == "fn" {
                expectedModifiers.insert(.function)
            } else {
                expectedKey = lower
            }
        }

        var cleanFlags = NSEvent.ModifierFlags()
        if flags.contains(.command) { cleanFlags.insert(.command) }
        if flags.contains(.shift) { cleanFlags.insert(.shift) }
        if flags.contains(.option) { cleanFlags.insert(.option) }
        if flags.contains(.control) { cleanFlags.insert(.control) }
        if flags.contains(.function) { cleanFlags.insert(.function) }

        guard cleanFlags == expectedModifiers else {
            return false
        }

        guard let firstChar = chars.lowercased().first else {
            return false
        }

        switch expectedKey {
        case "left arrow", "left", "←":
            return firstChar == Character(UnicodeScalar(NSLeftArrowFunctionKey)!) ||
                   (expectedModifiers.contains(.function) && firstChar == Character(UnicodeScalar(NSHomeFunctionKey)!))
        case "right arrow", "right", "→":
            return firstChar == Character(UnicodeScalar(NSRightArrowFunctionKey)!) ||
                   (expectedModifiers.contains(.function) && firstChar == Character(UnicodeScalar(NSEndFunctionKey)!))
        case "up arrow", "up", "↑":
            return firstChar == Character(UnicodeScalar(NSUpArrowFunctionKey)!) ||
                   (expectedModifiers.contains(.function) && firstChar == Character(UnicodeScalar(NSPageUpFunctionKey)!))
        case "down arrow", "down", "↓":
            return firstChar == Character(UnicodeScalar(NSDownArrowFunctionKey)!) ||
                   (expectedModifiers.contains(.function) && firstChar == Character(UnicodeScalar(NSPageDownFunctionKey)!))
        case "space", "spacebar":
            return firstChar == " "
        case "return", "enter":
            return firstChar == "\r" || firstChar == "\n"
        case "tab":
            return firstChar == "\t"
        case "escape", "esc":
            return firstChar == "\u{001B}"
        case "backspace", "delete":
            return firstChar == "\u{007F}" || firstChar == "\u{0008}"
        default:
            if expectedKey.count == 1 {
                return String(firstChar) == expectedKey
            }
            return false
        }
    }
}

public enum ShortcutTab: String, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case search = "Search"
    case practice = "Practice"

    public var id: String { rawValue }
}
