import AppKit
import Foundation

public enum EntryStability: String, Codable, Sendable {
    case stable
    case beta
    case experimental
}

public struct ValidationMetadata: Codable, Equatable, Hashable, Sendable {
    public let lastVerifiedAppVersion: String?
    public let lastVerifiedMacOSVersion: String?
    public let verificationStatus: String
    
    public init(lastVerifiedAppVersion: String? = nil, lastVerifiedMacOSVersion: String? = nil, verificationStatus: String) {
        self.lastVerifiedAppVersion = lastVerifiedAppVersion
        self.lastVerifiedMacOSVersion = lastVerifiedMacOSVersion
        self.verificationStatus = verificationStatus
    }
}

public struct ShortcutCatalogEntry: Codable, Identifiable, Hashable, Sendable {
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

    // New metadata fields
    public let stability: EntryStability
    public let validation: ValidationMetadata?
    public let tags: [String]

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
    
    public init(
        id: String,
        shortcut: String,
        action: String,
        source: String,
        scope: String,
        priority: Int,
        context: String,
        active: Bool,
        sends: String,
        notes: String,
        practicePrompt: String,
        stability: EntryStability = .stable,
        validation: ValidationMetadata? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.shortcut = shortcut
        self.action = action
        self.source = source
        self.scope = scope
        self.priority = priority
        self.context = context
        self.active = active
        self.sends = sends
        self.notes = notes
        self.practicePrompt = practicePrompt
        self.stability = stability
        self.validation = validation
        self.tags = tags
    }
    
    // Custom decoder to handle older json format that lacks the new fields
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.shortcut = try container.decode(String.self, forKey: .shortcut)
        self.action = try container.decode(String.self, forKey: .action)
        self.source = try container.decode(String.self, forKey: .source)
        self.scope = try container.decode(String.self, forKey: .scope)
        self.priority = try container.decode(Int.self, forKey: .priority)
        self.context = try container.decode(String.self, forKey: .context)
        self.active = try container.decode(Bool.self, forKey: .active)
        self.sends = try container.decodeIfPresent(String.self, forKey: .sends) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.practicePrompt = try container.decodeIfPresent(String.self, forKey: .practicePrompt) ?? ""
        
        self.stability = try container.decodeIfPresent(EntryStability.self, forKey: .stability) ?? .stable
        self.validation = try container.decodeIfPresent(ValidationMetadata.self, forKey: .validation)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

public extension ShortcutCatalogEntry {
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
