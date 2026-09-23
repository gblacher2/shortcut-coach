import Foundation

/// The versioned, read-only inventory used to add shortcuts from this Mac without
/// changing the immutable application catalog.
public struct EnvironmentCatalog: Codable, Equatable, Sendable {
    public let format: String
    public let schemaVersion: Int
    public let generatedAt: String
    public let macOSVersion: String
    public let macOSBuild: String
    public let architecture: String
    public let currentKeyboardLayout: String
    public let inputSources: [String]
    public let privacyNote: String
    public let bindings: [EnvironmentBinding]
    public let conflicts: [EnvironmentConflict]
    public let unresolved: [EnvironmentUnresolvedRecord]
    public let recommendedShortcutCoachChanges: EnvironmentChanges

    public func validate() throws {
        guard format == "shortcut-coach-environment/v1" else {
            throw EnvironmentCatalogValidationError.invalid("Unsupported environment format '\(format)'.")
        }
        guard schemaVersion == 1 else {
            throw EnvironmentCatalogValidationError.invalid("Unsupported environment schema version \(schemaVersion).")
        }

        try requireNonblank(generatedAt, field: "generatedAt")
        guard ISO8601DateFormatter().date(from: generatedAt) != nil else {
            throw EnvironmentCatalogValidationError.invalid("generatedAt must be an ISO-8601 date.")
        }
        try requireNonblank(macOSVersion, field: "macOSVersion")
        let macOSVersionComponents = macOSVersion.split(separator: ".", omittingEmptySubsequences: false)
        guard
            macOSVersionComponents.count >= 2,
            macOSVersionComponents.allSatisfy({ Int($0) != nil })
        else {
            throw EnvironmentCatalogValidationError.invalid("macOSVersion must be a numeric dotted version.")
        }
        try requireNonblank(macOSBuild, field: "macOSBuild")
        try requireNonblank(architecture, field: "architecture")
        try requireNonblank(currentKeyboardLayout, field: "currentKeyboardLayout")
        try requireNonblank(privacyNote, field: "privacyNote")
        guard !inputSources.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid("inputSources must contain at least one entry.")
        }
        try requireNonblankElements(inputSources, field: "inputSources")
        guard unresolved.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid(
                "Environment schema v1 cannot load unresolved shortcut records."
            )
        }

        guard bindings.count == 37 else {
            throw EnvironmentCatalogValidationError.invalid("Environment schema v1 requires exactly 37 bindings.")
        }
        guard conflicts.count == 3 else {
            throw EnvironmentCatalogValidationError.invalid("Environment schema v1 requires exactly 3 conflicts.")
        }

        let bindingIDs = try uniqueIDs(bindings.map(\.id), kind: "binding")
        let conflictIDs = try uniqueIDs(conflicts.map(\.id), kind: "conflict")

        for binding in bindings {
            try binding.validate(validConflictIDs: conflictIDs)
        }
        for conflict in conflicts {
            try conflict.validate(validBindingIDs: bindingIDs)

            let bindingReferences = Set(bindings.filter { $0.conflictIDs.contains(conflict.id) }.map(\.id))
            guard bindingReferences == Set(conflict.bindingIDs) else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Conflict '\(conflict.id)' and its bindings must reference each other exactly."
                )
            }
        }

        try recommendedShortcutCoachChanges.validate(bindings: bindings, validBindingIDs: bindingIDs)
    }
}

/// The audited v1 resource requires this collection to be empty. The marker is
/// intentionally payload-agnostic so any unresolved object decodes and is then
/// rejected semantically rather than failing with an opaque decoder error.
public struct EnvironmentUnresolvedRecord: Codable, Equatable, Sendable {
    public init() {}
}

public enum EnvironmentDefaultStatus: String, Codable, CaseIterable, Sendable {
    case custom
    case systemConfigured = "system-configured"
    case systemDefault = "system-default"
}

public enum EnvironmentSourceType: String, Codable, CaseIterable, Sendable {
    case officialDocumentation = "official-documentation"
    case systemPreference = "system-preference"
    case toolConfiguration = "tool-config"
}

public enum EnvironmentConfidence: String, Codable, CaseIterable, Sendable {
    case official
    case verified
}

public enum EnvironmentScope: String, Codable, CaseIterable, Sendable {
    case global
}

public enum EnvironmentOutputType: String, Codable, CaseIterable, Sendable {
    case appAction = "app-action"
    case keyChord = "key-chord"
    case systemAction = "system-action"
}

public struct EnvironmentInput: Codable, Equatable, Sendable {
    public let keyCode: String?
    public let consumerKeyCode: String?
    public let pointingButton: String?
    public let mandatoryModifiers: [String]
    public let optionalModifiers: [String]
    public let simultaneousKeys: [String]

    fileprivate func validate(bindingID: String) throws {
        try requireNonblankIfPresent(keyCode, field: "binding '\(bindingID)' input.keyCode")
        try requireNonblankIfPresent(consumerKeyCode, field: "binding '\(bindingID)' input.consumerKeyCode")
        try requireNonblankIfPresent(pointingButton, field: "binding '\(bindingID)' input.pointingButton")
        try requireNonblankElements(mandatoryModifiers, field: "binding '\(bindingID)' input.mandatoryModifiers")
        try requireNonblankElements(optionalModifiers, field: "binding '\(bindingID)' input.optionalModifiers")
        try requireNonblankElements(simultaneousKeys, field: "binding '\(bindingID)' input.simultaneousKeys")

        let hasTrigger = keyCode != nil || consumerKeyCode != nil || pointingButton != nil || !simultaneousKeys.isEmpty
        guard hasTrigger else {
            throw EnvironmentCatalogValidationError.invalid("Binding '\(bindingID)' has no input trigger.")
        }
    }
}

public struct EnvironmentOutput: Codable, Equatable, Sendable {
    public let type: EnvironmentOutputType
    public let summary: String
    public let keys: [String]

    fileprivate func validate(bindingID: String) throws {
        try requireNonblank(summary, field: "binding '\(bindingID)' output.summary")
        try requireNonblankElements(keys, field: "binding '\(bindingID)' output.keys")

        switch type {
        case .keyChord:
            guard !keys.isEmpty else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Binding '\(bindingID)' has a key-chord output without ordered output keys."
                )
            }
        case .appAction, .systemAction:
            guard keys.isEmpty else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Binding '\(bindingID)' has output keys for a non-key-chord action."
                )
            }
        }
    }
}

public struct EnvironmentBinding: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let category: String
    public let action: String
    public let keys: [String]
    public let displayText: String
    public let owner: String
    public let scope: EnvironmentScope
    public let enabled: Bool
    public let defaultStatus: EnvironmentDefaultStatus
    public let sourceType: EnvironmentSourceType
    public let source: String
    public let input: EnvironmentInput
    public let output: EnvironmentOutput
    public let confidence: EnvironmentConfidence
    public let caveat: String?
    public let conflictIDs: [String]

    fileprivate func validate(validConflictIDs: Set<String>) throws {
        try requireNonblank(id, field: "binding id")
        try requireNonblank(category, field: "binding '\(id)' category")
        try requireNonblank(action, field: "binding '\(id)' action")
        try requireNonblank(owner, field: "binding '\(id)' owner")
        try requireNonblank(displayText, field: "binding '\(id)' displayText")
        try requireNonblank(source, field: "binding '\(id)' source")
        try requireNonblankIfPresent(caveat, field: "binding '\(id)' caveat")

        guard !keys.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid("Binding '\(id)' must have ordered keys.")
        }
        try requireNonblankElements(keys, field: "binding '\(id)' keys")
        guard Set(keys).count == keys.count else {
            throw EnvironmentCatalogValidationError.invalid("Binding '\(id)' contains duplicate ordered keys.")
        }
        guard displayText == keys.joined(separator: " + ") else {
            throw EnvironmentCatalogValidationError.invalid(
                "Binding '\(id)' displayText must exactly match its ordered keys."
            )
        }

        try input.validate(bindingID: id)
        try output.validate(bindingID: id)

        guard Set(conflictIDs).count == conflictIDs.count else {
            throw EnvironmentCatalogValidationError.invalid("Binding '\(id)' contains duplicate conflict references.")
        }
        for conflictID in conflictIDs {
            try requireNonblank(conflictID, field: "binding '\(id)' conflict ID")
            guard validConflictIDs.contains(conflictID) else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Binding '\(id)' references missing conflict '\(conflictID)'."
                )
            }
        }

        if sourceType == .officialDocumentation {
            guard
                let url = URL(string: source),
                url.scheme?.lowercased() == "https",
                url.host != nil
            else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Binding '\(id)' official documentation source must be a valid HTTPS URL."
                )
            }
        }
    }
}

public enum EnvironmentConflictSeverity: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

public enum EnvironmentConflictType: String, Codable, CaseIterable, Sendable {
    case globalShadow = "global-shadow"
    case intentionalInterception = "intentional-interception"
    case mouseButtonShadow = "mouse-button-shadow"
}

public struct EnvironmentConflict: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let bindingIDs: [String]
    public let severity: EnvironmentConflictSeverity
    public let type: EnvironmentConflictType
    public let summary: String
    public let evidence: String
    public let recommendedNonDestructiveTest: String

    fileprivate func validate(validBindingIDs: Set<String>) throws {
        try requireNonblank(id, field: "conflict id")
        try requireNonblank(summary, field: "conflict '\(id)' summary")
        try requireNonblank(evidence, field: "conflict '\(id)' evidence")
        try requireNonblank(
            recommendedNonDestructiveTest,
            field: "conflict '\(id)' recommendedNonDestructiveTest"
        )
        guard !bindingIDs.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid("Conflict '\(id)' must reference at least one binding.")
        }
        try requireNonblankElements(bindingIDs, field: "conflict '\(id)' bindingIDs")
        guard Set(bindingIDs).count == bindingIDs.count else {
            throw EnvironmentCatalogValidationError.invalid("Conflict '\(id)' contains duplicate binding references.")
        }
        for bindingID in bindingIDs where !validBindingIDs.contains(bindingID) {
            throw EnvironmentCatalogValidationError.invalid(
                "Conflict '\(id)' references missing binding '\(bindingID)'."
            )
        }
    }
}

public enum EnvironmentClassification: String, Codable, CaseIterable, Hashable, Sendable {
    case add
    case update
    case keepSeparateFromBuiltInCatalog
    case omit
}

public struct EnvironmentChanges: Codable, Equatable, Sendable {
    public let add: [EnvironmentChangeRecommendation]
    public let update: [EnvironmentChangeRecommendation]
    public let keepSeparateFromBuiltInCatalog: [EnvironmentChangeRecommendation]
    public let omit: [EnvironmentChangeRecommendation]

    public func classification(for bindingID: String) -> EnvironmentClassification? {
        if add.contains(where: { $0.bindingID == bindingID }) { return .add }
        if update.contains(where: { $0.bindingID == bindingID }) { return .update }
        if keepSeparateFromBuiltInCatalog.contains(where: { $0.bindingID == bindingID }) {
            return .keepSeparateFromBuiltInCatalog
        }
        if omit.contains(where: { $0.bindingID == bindingID }) { return .omit }
        return nil
    }

    fileprivate func validate(bindings: [EnvironmentBinding], validBindingIDs: Set<String>) throws {
        guard add.count == 23 else {
            throw EnvironmentCatalogValidationError.invalid(
                "Environment schema v1 requires exactly 23 add recommendations."
            )
        }
        guard keepSeparateFromBuiltInCatalog.count == 14 else {
            throw EnvironmentCatalogValidationError.invalid(
                "Environment schema v1 requires exactly 14 keep-separate recommendations."
            )
        }
        guard update.isEmpty, omit.isEmpty else {
            throw EnvironmentCatalogValidationError.invalid(
                "Environment schema v1 decodes update and omit groups, but this audited dataset requires both to be empty."
            )
        }

        let groups: [(EnvironmentClassification, [EnvironmentChangeRecommendation])] = [
            (.add, add),
            (.update, update),
            (.keepSeparateFromBuiltInCatalog, keepSeparateFromBuiltInCatalog),
            (.omit, omit)
        ]

        var classifiedIDs = Set<String>()
        for (classification, recommendations) in groups {
            let ids = recommendations.map(\.bindingID)
            guard Set(ids).count == ids.count else {
                throw EnvironmentCatalogValidationError.invalid(
                    "Recommendation group '\(classification.rawValue)' contains duplicate binding IDs."
                )
            }

            for recommendation in recommendations {
                try requireNonblank(
                    recommendation.bindingID,
                    field: "\(classification.rawValue) recommendation bindingID"
                )
                try requireNonblank(
                    recommendation.reason,
                    field: "\(classification.rawValue) recommendation reason for '\(recommendation.bindingID)'"
                )
                guard validBindingIDs.contains(recommendation.bindingID) else {
                    throw EnvironmentCatalogValidationError.invalid(
                        "Recommendation group '\(classification.rawValue)' references missing binding '\(recommendation.bindingID)'."
                    )
                }
                guard classifiedIDs.insert(recommendation.bindingID).inserted else {
                    throw EnvironmentCatalogValidationError.invalid(
                        "Binding '\(recommendation.bindingID)' appears in more than one recommendation group."
                    )
                }
            }
        }

        let enabledIDs = Set(bindings.filter(\.enabled).map(\.id))
        guard classifiedIDs == enabledIDs else {
            let missing = enabledIDs.subtracting(classifiedIDs).sorted()
            let disabled = classifiedIDs.subtracting(enabledIDs).sorted()
            var details: [String] = []
            if !missing.isEmpty { details.append("unclassified enabled IDs: \(missing.joined(separator: ", "))") }
            if !disabled.isEmpty { details.append("classified disabled IDs: \(disabled.joined(separator: ", "))") }
            throw EnvironmentCatalogValidationError.invalid(
                "Recommendation coverage must classify every enabled binding exactly once (\(details.joined(separator: "; ")))."
            )
        }

        for binding in bindings where binding.enabled {
            switch classification(for: binding.id) {
            case .add:
                guard binding.defaultStatus != .custom else {
                    throw EnvironmentCatalogValidationError.invalid(
                        "System binding '\(binding.id)' cannot use the custom default status."
                    )
                }
            case .keepSeparateFromBuiltInCatalog:
                guard binding.defaultStatus == .custom else {
                    throw EnvironmentCatalogValidationError.invalid(
                        "Personal binding '\(binding.id)' must use the custom default status."
                    )
                }
            case .update, .omit:
                break
            case nil:
                // Exact coverage above guarantees that this branch is unreachable.
                throw EnvironmentCatalogValidationError.invalid(
                    "Enabled binding '\(binding.id)' has no recommendation classification."
                )
            }
        }
    }
}

public struct EnvironmentChangeRecommendation: Codable, Equatable, Sendable {
    public let bindingID: String
    public let reason: String
}

public enum EnvironmentCatalogValidationError: LocalizedError, Equatable, Sendable {
    case invalid(String)

    public var errorDescription: String? {
        switch self {
        case let .invalid(reason): "The My Mac shortcut data is invalid: \(reason)"
        }
    }
}

private func requireNonblank(_ value: String, field: String) throws {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw EnvironmentCatalogValidationError.invalid("\(field) must not be blank.")
    }
}

private func requireNonblankIfPresent(_ value: String?, field: String) throws {
    guard let value else { return }
    try requireNonblank(value, field: field)
}

private func requireNonblankElements(_ values: [String], field: String) throws {
    for value in values {
        try requireNonblank(value, field: field)
    }
}

private func uniqueIDs(_ ids: [String], kind: String) throws -> Set<String> {
    try requireNonblankElements(ids, field: "\(kind) ID")
    guard Set(ids).count == ids.count else {
        throw EnvironmentCatalogValidationError.invalid("Duplicate \(kind) IDs are not allowed.")
    }
    return Set(ids)
}
