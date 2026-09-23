import Foundation

public struct UserCollection: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var shortcutIDs: Set<String>

    public init(id: String = UUID().uuidString, name: String, shortcutIDs: Set<String> = []) {
        self.id = id
        self.name = name
        self.shortcutIDs = shortcutIDs
    }
}

public struct UserLibraryState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var favourites: Set<String>
    public var toLearn: Set<String>
    public var notes: [String: String]
    public var collections: [String: UserCollection]
    public var recents: [String]
    public var practiceSnapshot: DailyPracticeSnapshot

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        favourites: Set<String> = [],
        toLearn: Set<String> = [],
        notes: [String: String] = [:],
        collections: [String: UserCollection] = [:],
        recents: [String] = [],
        practiceSnapshot: DailyPracticeSnapshot = DailyPracticeSnapshot(dayKey: DailyPracticeProgress.dayKey(for: Date()))
    ) {
        self.schemaVersion = schemaVersion
        self.favourites = favourites
        self.toLearn = toLearn
        self.notes = notes
        self.collections = collections
        self.recents = Array(recents.prefix(50))
        self.practiceSnapshot = practiceSnapshot
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion, favourites, toLearn, notes, collections, recents, practiceSnapshot
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        favourites = try container.decodeIfPresent(Set<String>.self, forKey: .favourites) ?? []
        toLearn = try container.decodeIfPresent(Set<String>.self, forKey: .toLearn) ?? []
        notes = try container.decodeIfPresent([String: String].self, forKey: .notes) ?? [:]
        collections = try container.decodeIfPresent([String: UserCollection].self, forKey: .collections) ?? [:]
        recents = Array((try container.decodeIfPresent([String].self, forKey: .recents) ?? []).prefix(50))
        practiceSnapshot = try container.decodeIfPresent(DailyPracticeSnapshot.self, forKey: .practiceSnapshot)
            ?? DailyPracticeSnapshot(dayKey: DailyPracticeProgress.dayKey(for: Date()))
    }
}

public struct UserLibraryBackup: Codable, Equatable, Sendable {
    public static let format = "shortcut-coach-personal-state"

    public let format: String
    public let schemaVersion: Int
    public let exportedAt: Date
    public let state: UserLibraryState

    public init(state: UserLibraryState, exportedAt: Date = Date()) {
        self.format = Self.format
        self.schemaVersion = UserLibraryState.currentSchemaVersion
        self.exportedAt = exportedAt
        self.state = state
    }
}
