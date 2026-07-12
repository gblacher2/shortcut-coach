import Foundation

public struct EnvironmentCatalog: Codable, Sendable {
    public let format: String
    public let schemaVersion: Int
    public let generatedAt: String
    public let macOSVersion: String
    public let bindings: [EnvironmentBinding]
    public let conflicts: [EnvironmentConflict]
    public let recommendedShortcutCoachChanges: EnvironmentChanges
    
    public func validate() throws {
        if format != "shortcut-coach-environment/v1" {
            throw CatalogError.invalidCatalog(reason: "Unsupported environment format: \(format)")
        }
        if schemaVersion != 1 {
            throw CatalogError.invalidCatalog(reason: "Unsupported schema version: \(schemaVersion)")
        }
        
        let bindingIDs = bindings.map(\.id)
        if Set(bindingIDs).count != bindings.count {
            throw CatalogError.invalidCatalog(reason: "Duplicate binding IDs found")
        }
        
        let conflictIDs = conflicts.map(\.id)
        if Set(conflictIDs).count != conflicts.count {
            throw CatalogError.invalidCatalog(reason: "Duplicate conflict IDs found")
        }
        
        let validConflictIDs = Set(conflictIDs)
        for binding in bindings {
            for cid in binding.conflictIDs {
                if !validConflictIDs.contains(cid) {
                    throw CatalogError.invalidCatalog(reason: "Binding \(binding.id) references dangling conflict ID: \(cid)")
                }
            }
            if !binding.action.isEmpty == false || !binding.owner.isEmpty == false || !binding.category.isEmpty == false || (binding.source?.isEmpty ?? true) || binding.keys.isEmpty || binding.displayText.isEmpty || binding.output == nil || binding.confidence.isEmpty {
                throw CatalogError.invalidCatalog(reason: "Binding \(binding.id) is missing required fields")
            }
            if binding.input == nil && binding.displayText != binding.keys.joined(separator: " + ") {
                throw CatalogError.invalidCatalog(reason: "Binding \(binding.id) display text does not match ordered keys")
            }
        }
        
        let addIDs = recommendedShortcutCoachChanges.add.map(\.bindingID)
        let sepIDs = recommendedShortcutCoachChanges.keepSeparateFromBuiltInCatalog.map(\.bindingID)
        
        if Set(addIDs).count != addIDs.count {
            throw CatalogError.invalidCatalog(reason: "Duplicate recommendation IDs in add")
        }
        if Set(sepIDs).count != sepIDs.count {
            throw CatalogError.invalidCatalog(reason: "Duplicate recommendation IDs in keepSeparateFromBuiltInCatalog")
        }
        
        let addSet = Set(addIDs)
        let sepSet = Set(sepIDs)
        if !addSet.isDisjoint(with: sepSet) {
            throw CatalogError.invalidCatalog(reason: "Overlapping classifications between add and keepSeparateFromBuiltInCatalog")
        }
        
        let allValidBindingIDs = Set(bindingIDs)
        for rid in addSet.union(sepSet) {
            if !allValidBindingIDs.contains(rid) {
                throw CatalogError.invalidCatalog(reason: "Recommendation references dangling binding ID: \(rid)")
            }
        }
        
        let enabledBindingIDs = Set(bindings.filter(\.enabled).map(\.id))
        let unionRecs = addSet.union(sepSet)
        if !enabledBindingIDs.isSubset(of: unionRecs) {
            throw CatalogError.invalidCatalog(reason: "Some enabled bindings are missing from classifications")
        }
    }
}

public struct EnvironmentConflict: Codable, Sendable {
    public let id: String
    public let summary: String
}

public struct EnvironmentChanges: Codable, Sendable {
    public let add: [EnvironmentChangeRecommendation]
    public let keepSeparateFromBuiltInCatalog: [EnvironmentChangeRecommendation]
}

public struct EnvironmentChangeRecommendation: Codable, Sendable {
    public let bindingID: String
    public let reason: String
}

public struct EnvironmentInput: Codable, Sendable {
    public let keyCode: String?
    public let mandatoryModifiers: [String]?
    public let optionalModifiers: [String]?
}

public struct EnvironmentOutput: Codable, Sendable {
    public let summary: String
}

public struct EnvironmentBinding: Codable, Identifiable, Sendable {
    public let id: String
    public let category: String
    public let action: String
    public let keys: [String]
    public let displayText: String
    public let owner: String
    public let scope: String
    public let enabled: Bool
    public let input: EnvironmentInput?
    public let output: EnvironmentOutput?
    public let confidence: String
    public let caveat: String?
    public let conflictIDs: [String]
    public let source: String?
}
