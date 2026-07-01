import Foundation

public struct CatalogLoader {
    public static let liveGuideDirectoryURL = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Projects/mac-shortcuts-guide", isDirectory: true)
    public static let liveCatalogURL = liveGuideDirectoryURL.appendingPathComponent("mac-shortcuts.json")
    public static let fullGuideURL = liveGuideDirectoryURL.appendingPathComponent("mac-shortcuts.html")

    public init() {}

    public func load() throws -> LoadedCatalog {
        // Allow overriding the live catalog path via environment variable.
        // Used by --verify to test bundled fallback without touching the real file.
        let catalogURL: URL
        if let override = ProcessInfo.processInfo.environment["SHORTCUTCOACH_CATALOG_OVERRIDE"] {
            catalogURL = URL(fileURLWithPath: override)
        } else {
            catalogURL = Self.liveCatalogURL
        }

        let liveData: Data
        do {
            liveData = try Data(contentsOf: catalogURL)
        } catch {
            return try loadFallbackCatalog()
        }

        do {
            return try LoadedCatalog(
                catalog: decode(liveData),
                sourceDescription: "Live guide JSON"
            )
        } catch {
            throw CatalogError.invalidLiveCatalog(path: catalogURL.path, reason: error.localizedDescription)
        }
    }

    private func loadFallbackCatalog() throws -> LoadedCatalog {
        guard let fallbackURL = Bundle.module.url(forResource: "mac-shortcuts", withExtension: "json") else {
            throw CatalogError.missingFallback
        }

        let data = try Data(contentsOf: fallbackURL)
        do {
            return try LoadedCatalog(
                catalog: decode(data),
                sourceDescription: "Bundled fallback JSON"
            )
        } catch {
            throw CatalogError.invalidBundledCatalog(reason: error.localizedDescription)
        }
    }

    private func decode(_ data: Data) throws -> ShortcutCatalog {
        try JSONDecoder().decode(ShortcutCatalog.self, from: data)
    }
}

public struct LoadedCatalog: Sendable {
    public let catalog: ShortcutCatalog
    public let sourceDescription: String
}

public enum CatalogError: LocalizedError {
    case missingFallback
    case invalidLiveCatalog(path: String, reason: String)
    case invalidBundledCatalog(reason: String)

    public var errorDescription: String? {
        switch self {
        case .missingFallback:
            "Bundled shortcut catalog is missing."
        case let .invalidLiveCatalog(path, reason):
            "Live shortcut catalog at \(path) is invalid: \(reason)"
        case let .invalidBundledCatalog(reason):
            "Bundled shortcut catalog is invalid: \(reason)"
        }
    }
}
