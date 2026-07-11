import Foundation

public struct CatalogLoader: Sendable {
    public init() {}

    public func load() throws -> LoadedCatalog {
        guard let url = Bundle.module.url(forResource: "mac-shortcuts", withExtension: "json") else {
            throw CatalogError.missingCatalog
        }

        do {
            let catalog = try JSONDecoder().decode(ShortcutCatalog.self, from: Data(contentsOf: url))
            return LoadedCatalog(catalog: catalog, sourceDescription: "Built-in catalog v\(catalog.catalogVersion)")
        } catch {
            throw CatalogError.invalidCatalog(reason: error.localizedDescription)
        }
    }
}

public struct LoadedCatalog: Sendable {
    public let catalog: ShortcutCatalog
    public let sourceDescription: String
}

public enum CatalogError: LocalizedError {
    case missingCatalog
    case invalidCatalog(reason: String)

    public var errorDescription: String? {
        switch self {
        case .missingCatalog: "The immutable built-in shortcut catalog is missing."
        case let .invalidCatalog(reason): "The built-in shortcut catalog is invalid: \(reason)"
        }
    }
}
