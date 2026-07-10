import Foundation

public struct SupportedApp: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String?
    public let aliases: [String]?
    
    public init(id: String, name: String, bundleIdentifier: String? = nil, aliases: [String]? = nil) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.aliases = aliases
    }
}
