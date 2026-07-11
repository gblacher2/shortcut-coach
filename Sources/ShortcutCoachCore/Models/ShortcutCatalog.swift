import Foundation

public struct ShortcutCatalog: Codable, Sendable {
    public let schemaVersion: Int
    public let catalogVersion: String
    public let publishedAt: String
    public let validatedMacOSVersion: String
    public let apps: [SupportedApp]
    public let shortcuts: [ShortcutCatalogEntry]

    public init(
        schemaVersion: Int,
        catalogVersion: String,
        publishedAt: String,
        validatedMacOSVersion: String,
        apps: [SupportedApp],
        shortcuts: [ShortcutCatalogEntry]
    ) {
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.publishedAt = publishedAt
        self.validatedMacOSVersion = validatedMacOSVersion
        self.apps = apps
        self.shortcuts = shortcuts
    }
}
