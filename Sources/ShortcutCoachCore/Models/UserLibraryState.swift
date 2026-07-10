import Foundation

public struct UserCollection: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var shortcutIDs: Set<String>
    
    public init(id: String, name: String, shortcutIDs: Set<String> = []) {
        self.id = id
        self.name = name
        self.shortcutIDs = shortcutIDs
    }
}

public struct UserLibraryState: Codable, Equatable, Sendable {
    public var favourites: Set<String> = []
    public var toLearn: Set<String> = []
    public var notes: [String: String] = [:] // shortcutID -> note
    public var collections: [String: UserCollection] = [:]
    public var recents: [String] = [] // max 50 items
    public var practiceSnapshot: DailyPracticeSnapshot = DailyPracticeSnapshot(dayKey: DailyPracticeProgress.dayKey(for: Date()))
    
    public init() {}
}
