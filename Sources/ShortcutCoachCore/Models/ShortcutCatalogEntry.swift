import AppKit
import Foundation

public enum EntryStability: String, Codable, CaseIterable, Sendable {
    case stable
    case versionSensitive = "version-sensitive"
    case contextual
}

public enum SourceKind: String, Codable, Sendable {
    case officialDocumentation = "official-documentation"
    case installedAppMenu = "installed-app-menu"
}

public struct SourceReference: Codable, Equatable, Hashable, Sendable {
    public let title: String
    public let url: String?
    public let kind: SourceKind

    public init(title: String, url: String? = nil, kind: SourceKind) {
        self.title = title
        self.url = url
        self.kind = kind
    }
}

public struct ValidationMetadata: Codable, Equatable, Hashable, Sendable {
    public let appVersion: String?
    public let macOSVersion: String
    public let verifiedAt: String
    public let method: String

    public init(appVersion: String? = nil, macOSVersion: String, verifiedAt: String, method: String) {
        self.appVersion = appVersion
        self.macOSVersion = macOSVersion
        self.verifiedAt = verifiedAt
        self.method = method
    }
}

public struct ShortcutCatalogEntry: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let appID: String
    public let title: String
    public let keys: [String]
    public let displayText: String
    public let taskTags: [String]
    public let category: String
    public let guidance: String
    public let menuPath: [String]?
    public let relatedIDs: [String]
    public let sourceReference: SourceReference
    public let validation: ValidationMetadata
    public let stability: EntryStability
    public let caveat: String?

    enum CodingKeys: String, CodingKey {
        case id, title, keys, category, guidance, stability, caveat
        case appID = "app"
        case displayText
        case taskTags
        case menuPath
        case relatedIDs
        case sourceReference = "source"
        case validation
    }

    public init(
        id: String,
        appID: String,
        title: String,
        keys: [String],
        displayText: String,
        taskTags: [String],
        category: String,
        guidance: String,
        menuPath: [String]? = nil,
        relatedIDs: [String] = [],
        sourceReference: SourceReference,
        validation: ValidationMetadata,
        stability: EntryStability = .stable,
        caveat: String? = nil
    ) {
        self.id = id
        self.appID = appID
        self.title = title
        self.keys = keys
        self.displayText = displayText
        self.taskTags = taskTags
        self.category = category
        self.guidance = guidance
        self.menuPath = menuPath
        self.relatedIDs = relatedIDs
        self.sourceReference = sourceReference
        self.validation = validation
        self.stability = stability
        self.caveat = caveat
    }

    public var appName: String {
        SupportedApp.app(withID: appID)?.name ?? appID
    }

    public var searchableText: String {
        ([title, appName, displayText, category, guidance]
            + keys
            + taskTags
            + (menuPath ?? [])
            + [sourceReference.title]
            + [caveat].compactMap { $0 })
            .joined(separator: " ")
    }

    // Compatibility properties retained for the legacy practice views while the
    // catalog itself uses the explicit, versioned v1 contract above.
    public var shortcut: String { displayText }
    public var action: String { title }
    public var source: String { sourceReference.title }
    public var scope: String { "App specific" }
    public var priority: Int { 1 }
    public var context: String { appName }
    public var active: Bool { true }
    public var sends: String { menuPath?.joined(separator: " > ") ?? "" }
    public var notes: String { caveat ?? "" }
    public var practicePrompt: String { guidance }
    public var tags: [String] { taskTags }
    public var priorityLabel: String { "Daily" }
}

public extension ShortcutCatalogEntry {
    func matches(flags: NSEvent.ModifierFlags, charsIgnoringModifiers chars: String) -> Bool {
        var expectedModifiers = NSEvent.ModifierFlags()
        for key in keys.dropLast() {
            switch key.lowercased() {
            case "command", "cmd", "⌘": expectedModifiers.insert(.command)
            case "shift", "⇧": expectedModifiers.insert(.shift)
            case "option", "alt", "⌥": expectedModifiers.insert(.option)
            case "control", "ctrl", "⌃": expectedModifiers.insert(.control)
            case "fn": expectedModifiers.insert(.function)
            default: break
            }
        }

        var cleanFlags = NSEvent.ModifierFlags()
        if flags.contains(.command) { cleanFlags.insert(.command) }
        if flags.contains(.shift) { cleanFlags.insert(.shift) }
        if flags.contains(.option) { cleanFlags.insert(.option) }
        if flags.contains(.control) { cleanFlags.insert(.control) }
        if flags.contains(.function) { cleanFlags.insert(.function) }
        guard cleanFlags == expectedModifiers, let expectedKey = keys.last?.lowercased() else { return false }

        guard let firstCharacter = chars.lowercased().first else { return false }
        switch expectedKey {
        case "left arrow", "left", "←": return firstCharacter == Character(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case "right arrow", "right", "→": return firstCharacter == Character(UnicodeScalar(NSRightArrowFunctionKey)!)
        case "up arrow", "up", "↑": return firstCharacter == Character(UnicodeScalar(NSUpArrowFunctionKey)!)
        case "down arrow", "down", "↓": return firstCharacter == Character(UnicodeScalar(NSDownArrowFunctionKey)!)
        case "space", "spacebar": return firstCharacter == " "
        case "return", "enter": return firstCharacter == "\r" || firstCharacter == "\n"
        case "tab": return firstCharacter == "\t"
        case "escape", "esc": return firstCharacter == "\u{001B}"
        case "backspace", "delete": return firstCharacter == "\u{007F}" || firstCharacter == "\u{0008}"
        default: return expectedKey.count == 1 && String(firstCharacter) == expectedKey
        }
    }
}
