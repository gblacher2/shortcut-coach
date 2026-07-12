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

            if let envUrl = Bundle.module.url(forResource: "my-mac-environment", withExtension: "json") {
                let envCatalog = try JSONDecoder().decode(EnvironmentCatalog.self, from: Data(contentsOf: envUrl))
                
                let adds = Set(envCatalog.recommendedShortcutCoachChanges.add.map(\.bindingID))
                let separates = Set(envCatalog.recommendedShortcutCoachChanges.keepSeparateFromBuiltInCatalog.map(\.bindingID))
                let validConflictIDs = Set(envCatalog.conflicts.map(\.id))
                
                let envEntries = try envCatalog.bindings.map { binding -> ShortcutCatalogEntry in
                    let status: String
                    if adds.contains(binding.id) { status = "add" }
                    else if separates.contains(binding.id) { status = "keepSeparateFromBuiltInCatalog" }
                    else { status = "custom" }
                    
                    for conflictID in binding.conflictIDs {
                        if !validConflictIDs.contains(conflictID) {
                            throw CatalogError.invalidCatalog(reason: "Dangling conflict reference: \(conflictID)")
                        }
                    }
                    
                    // Actually, let's map conflictIDs to actual conflict summaries for the UI to display directly? 
                    // No, the UI can just show the conflict ID or we can map it to caveat! Wait, the brief says:
                    // "The inspector explains inputs and outputs and displays the three conflict/interception warnings on the correct records."
                    // Since we have the summary in EnvironmentConflict, let's pass the summary instead of ID!
                    let resolvedConflicts = binding.conflictIDs.compactMap { cid in 
                        envCatalog.conflicts.first(where: { $0.id == cid })?.summary 
                    }
                    
                    return ShortcutCatalogEntry(
                        id: binding.id,
                        appID: "my-mac",
                        title: binding.action,
                        keys: binding.keys,
                        displayText: binding.displayText,
                        taskTags: [],
                        category: binding.category,
                        guidance: "Local environment mapping.",
                        sourceReference: SourceReference(title: binding.source ?? "Local Configuration", kind: .installedAppMenu),
                        validation: ValidationMetadata(macOSVersion: "local", verifiedAt: "now", method: "local"),
                        caveat: binding.caveat,
                        owner: binding.owner,
                        conflictIDs: resolvedConflicts,
                        defaultStatus: status,
                        outputSummary: binding.output?.summary
                    )
                }
                allShortcuts.append(contentsOf: envEntries)
            }

            let finalCatalog = ShortcutCatalog(
                schemaVersion: baseCatalog.schemaVersion,
                catalogVersion: baseCatalog.catalogVersion,
                publishedAt: baseCatalog.publishedAt,
                validatedMacOSVersion: baseCatalog.validatedMacOSVersion,
                apps: baseCatalog.apps,
                shortcuts: allShortcuts
            )

            return LoadedCatalog(catalog: finalCatalog, sourceDescription: "Built-in catalog v\(finalCatalog.catalogVersion)")
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
