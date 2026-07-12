import Foundation

public struct CatalogLoader: Sendable {
    public init() {}

    public func load() throws -> LoadedCatalog {
        guard let url = Bundle.module.url(forResource: "mac-shortcuts", withExtension: "json") else {
            throw CatalogError.missingCatalog
        }

        do {
            let baseCatalog = try JSONDecoder().decode(ShortcutCatalog.self, from: Data(contentsOf: url))
            var allShortcuts = baseCatalog.shortcuts

            var environmentWarning: String? = nil
            if let envUrl = Bundle.module.url(forResource: "my-mac-environment", withExtension: "json") {
                do {
                    let envCatalog = try JSONDecoder().decode(EnvironmentCatalog.self, from: Data(contentsOf: envUrl))
                    try envCatalog.validate()
                    
                    let adds = Set(envCatalog.recommendedShortcutCoachChanges.add.map(\.bindingID))
                    let separates = Set(envCatalog.recommendedShortcutCoachChanges.keepSeparateFromBuiltInCatalog.map(\.bindingID))
                    
                    let envEntries = envCatalog.bindings.map { binding -> ShortcutCatalogEntry in
                        let status: String
                        if adds.contains(binding.id) { status = "add" }
                        else if separates.contains(binding.id) { status = "keepSeparateFromBuiltInCatalog" }
                        else { status = "custom" }
                        
                        let resolvedConflicts = binding.conflictIDs.compactMap { cid in 
                            envCatalog.conflicts.first(where: { $0.id == cid })?.summary 
                        }
                        
                        let sourceKind: SourceKind
                        if let stype = binding.source, stype.starts(with: "http") {
                            sourceKind = .officialDocumentation
                        } else {
                            sourceKind = .localConfiguration
                        }
                        
                        let guidance = binding.output?.summary ?? binding.caveat ?? "Local configuration"
                        
                        return ShortcutCatalogEntry(
                            id: binding.id,
                            appID: "my-mac",
                            title: binding.action,
                            keys: binding.keys,
                            displayText: binding.displayText,
                            taskTags: [],
                            category: binding.category,
                            guidance: guidance,
                            sourceReference: SourceReference(title: binding.source ?? "Local Configuration", kind: sourceKind),
                            validation: ValidationMetadata(macOSVersion: envCatalog.macOSVersion, verifiedAt: envCatalog.generatedAt, method: binding.confidence),
                            caveat: binding.caveat,
                            owner: binding.owner,
                            conflictIDs: resolvedConflicts,
                            defaultStatus: status,
                            outputSummary: binding.output?.summary
                        )
                    }
                    allShortcuts.append(contentsOf: envEntries)
                } catch {
                    environmentWarning = "Failed to load My Mac environment: \(error.localizedDescription)"
                }
            }

            let finalCatalog = ShortcutCatalog(
                schemaVersion: baseCatalog.schemaVersion,
                catalogVersion: baseCatalog.catalogVersion,
                publishedAt: baseCatalog.publishedAt,
                validatedMacOSVersion: baseCatalog.validatedMacOSVersion,
                apps: baseCatalog.apps,
                shortcuts: allShortcuts
            )

            return LoadedCatalog(catalog: finalCatalog, sourceDescription: "Built-in catalog v\(finalCatalog.catalogVersion)", environmentWarning: environmentWarning)
        } catch let DecodingError.dataCorrupted(context) {
            throw CatalogError.invalidCatalog(reason: "Data corrupted: \(context)")
        } catch let DecodingError.keyNotFound(key, context) {
            throw CatalogError.invalidCatalog(reason: "Key '\(key.stringValue)' not found: \(context.debugDescription) / codingPath: \(context.codingPath)")
        } catch let DecodingError.valueNotFound(value, context) {
            throw CatalogError.invalidCatalog(reason: "Value '\(value)' not found: \(context.debugDescription) / codingPath: \(context.codingPath)")
        } catch let DecodingError.typeMismatch(type, context) {
            throw CatalogError.invalidCatalog(reason: "Type '\(type)' mismatch: \(context.debugDescription) / codingPath: \(context.codingPath)")
        } catch {
            throw CatalogError.invalidCatalog(reason: error.localizedDescription)
        }
    }
}

public struct LoadedCatalog: Sendable {
    public let catalog: ShortcutCatalog
    public let sourceDescription: String
    public let environmentWarning: String?
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
