import Foundation

public struct CatalogLoader: Sendable {
    public init() {}

    public func load(environmentData: Data? = nil) throws -> LoadedCatalog {
        guard let url = Bundle.module.url(forResource: "mac-shortcuts", withExtension: "json") else {
            throw CatalogError.missingCatalog
        }

        do {
            let baseCatalog = try JSONDecoder().decode(ShortcutCatalog.self, from: Data(contentsOf: url))
            var allShortcuts = baseCatalog.shortcuts

            var environmentState: EnvironmentState = .missing
            
            let envData: Data?
            if let provided = environmentData {
                envData = provided
            } else if let envUrl = Bundle.module.url(forResource: "my-mac-environment", withExtension: "json") {
                envData = try? Data(contentsOf: envUrl)
            } else {
                envData = nil
            }
            
            if let data = envData {
                do {
                    let envCatalog = try JSONDecoder().decode(EnvironmentCatalog.self, from: data)
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
                        var sourceTitle = binding.source ?? "Local Configuration"
                        var sourceUrl: String? = nil
                        
                        if binding.sourceType == "official-documentation" {
                            sourceKind = .officialDocumentation
                            sourceTitle = "Apple Support"
                            sourceUrl = binding.source
                        } else if binding.sourceType == "system-preference" {
                            sourceKind = .systemPreference
                        } else if binding.sourceType == "tool-config" {
                            sourceKind = .toolConfiguration
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
                            sourceReference: SourceReference(title: sourceTitle, url: sourceUrl, kind: sourceKind),
                            validation: ValidationMetadata(macOSVersion: envCatalog.macOSVersion, verifiedAt: envCatalog.generatedAt, method: binding.confidence),
                            caveat: binding.caveat,
                            owner: binding.owner,
                            conflictIDs: resolvedConflicts,
                            defaultStatus: status,
                            outputSummary: binding.output?.summary
                        )
                    }
                    allShortcuts.append(contentsOf: envEntries)
                    environmentState = .loaded
                } catch {
                    environmentState = .rejected(reason: error.localizedDescription)
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

            return LoadedCatalog(catalog: finalCatalog, sourceDescription: "Built-in catalog v\(finalCatalog.catalogVersion)", environmentState: environmentState)
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

public enum EnvironmentState: Equatable, Sendable {
    case loaded
    case missing
    case rejected(reason: String)
}

public struct LoadedCatalog: Sendable {
    public let catalog: ShortcutCatalog
    public let sourceDescription: String
    public let environmentState: EnvironmentState
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
