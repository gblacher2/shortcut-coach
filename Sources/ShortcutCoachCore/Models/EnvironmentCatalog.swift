import Foundation

public struct EnvironmentCatalog: Codable, Sendable {
    public let format: String
    public let schemaVersion: Int
    public let bindings: [EnvironmentBinding]
    public let conflicts: [EnvironmentConflict]
    public let recommendedShortcutCoachChanges: EnvironmentChanges
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
