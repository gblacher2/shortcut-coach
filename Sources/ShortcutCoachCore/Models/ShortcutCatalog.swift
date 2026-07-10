import AppKit
import Foundation

public struct ShortcutCatalog: Decodable, Sendable {
    public let metadata: CatalogMetadata
    public let shortcuts: [ShortcutCatalogEntry]
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

public enum ShortcutTab: String, CaseIterable, Identifiable, Sendable {
    case today = "Today"
    case search = "Search"
    case practice = "Practice"

    public var id: String { rawValue }
}
