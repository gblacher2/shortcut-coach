import Foundation

public enum UserLibraryManagerError: LocalizedError, Equatable {
    case corruptedData
    case unsupportedBackup
    case invalidState(String)
    case ioError(String)

    public var errorDescription: String? {
        switch self {
        case .corruptedData: "The personal library file is malformed."
        case .unsupportedBackup: "This is not a Shortcut Coach personal-state backup."
        case let .invalidState(reason): "The backup contains invalid personal state: \(reason)"
        case let .ioError(message): "File system error: \(message)"
        }
    }
}

public final class UserLibraryManager: @unchecked Sendable {
    public static let shared = UserLibraryManager()

    public let stateURL: URL
    public let recoveryURL: URL
    public let migrationBackupURL: URL
    private let defaults: UserDefaults
    private let fileManager: FileManager

    public init(
        fileURL: URL? = nil,
        defaults: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.stateURL = fileURL ?? appSupport
            .appendingPathComponent("ShortcutCoach", isDirectory: true)
            .appendingPathComponent("UserLibraryState.json")
        self.recoveryURL = stateURL.deletingLastPathComponent().appendingPathComponent("UserLibraryState.recovery.json")
        self.migrationBackupURL = stateURL.deletingLastPathComponent().appendingPathComponent("LegacyUserDefaults.backup.json")
        self.defaults = defaults
        self.fileManager = fileManager
    }

    public func load() throws -> UserLibraryState {
        try ensureDirectory()
        if !fileManager.fileExists(atPath: stateURL.path) {
            return try migrateLegacyStateIfNeeded()
        }

        do {
            return try decodeState(at: stateURL)
        } catch {
            guard fileManager.fileExists(atPath: recoveryURL.path) else {
                throw UserLibraryManagerError.corruptedData
            }
            let recovered = try decodeState(at: recoveryURL)
            try writeState(recovered, to: stateURL, updateRecovery: false)
            return recovered
        }
    }

    public func save(_ state: UserLibraryState) throws {
        try validate(state)
        try ensureDirectory()
        try writeState(state, to: stateURL, updateRecovery: true)
    }

    public func export(to url: URL, state: UserLibraryState) throws {
        try validate(state)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(UserLibraryBackup(state: state)).write(to: url, options: .atomic)
        } catch let error as UserLibraryManagerError {
            throw error
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }

    @discardableResult
    public func `import`(from url: URL) throws -> UserLibraryState {
        let imported: UserLibraryState
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backup = try decoder.decode(UserLibraryBackup.self, from: Data(contentsOf: url))
            guard backup.format == UserLibraryBackup.format,
                  backup.schemaVersion <= UserLibraryState.currentSchemaVersion else {
                throw UserLibraryManagerError.unsupportedBackup
            }
            imported = backup.state
            try validate(imported)
        } catch let error as UserLibraryManagerError {
            throw error
        } catch is DecodingError {
            throw UserLibraryManagerError.corruptedData
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }

        // Parsing and validation complete before the first write. The current
        // primary is copied to recovery, then the atomic replacement occurs.
        try ensureDirectory()
        if fileManager.fileExists(atPath: stateURL.path) {
            try copyReplacing(stateURL, to: recoveryURL)
        }
        try writeState(imported, to: stateURL, updateRecovery: false)
        return imported
    }

    private func migrateLegacyStateIfNeeded() throws -> UserLibraryState {
        let practiceData = defaults.data(forKey: "shortcutCoach.dailyPracticeSnapshot")
        let metadataData = defaults.data(forKey: "shortcutCoach.userMetadata")
        guard practiceData != nil || metadataData != nil else { return UserLibraryState() }

        // Back up the exact legacy blobs before attempting the atomic state write.
        let legacyBackup = LegacyDefaultsBackup(practiceData: practiceData, metadataData: metadataData)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            try encoder.encode(legacyBackup).write(to: migrationBackupURL, options: .atomic)

            var state = UserLibraryState()
            if let practiceData,
               let snapshot = try? JSONDecoder().decode(DailyPracticeSnapshot.self, from: practiceData) {
                state.practiceSnapshot = snapshot
            }
            if let metadataData {
                let metadata = try JSONDecoder().decode(LegacyUserMetadata.self, from: metadataData)
                state.favourites = metadata.favourites
                state.toLearn = metadata.toLearn
                state.recents = Array(metadata.recentlyViewed.prefix(50))
                state.collections = Dictionary(uniqueKeysWithValues: metadata.collections.map { name, ids in
                    let collection = UserCollection(name: name, shortcutIDs: Set(ids))
                    return (collection.id, collection)
                })
            }
            try validate(state)
            try writeState(state, to: stateURL, updateRecovery: true)
            return state
        } catch {
            // UserDefaults remains untouched, so the pre-migration state stays usable.
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }

    private func validate(_ state: UserLibraryState) throws {
        guard state.schemaVersion <= UserLibraryState.currentSchemaVersion else {
            throw UserLibraryManagerError.invalidState("newer schema version")
        }
        guard state.recents.count <= 50 else {
            throw UserLibraryManagerError.invalidState("more than 50 recent items")
        }
        guard state.collections.values.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw UserLibraryManagerError.invalidState("empty collection name")
        }
        guard state.notes.values.allSatisfy({ $0.count <= 20_000 }) else {
            throw UserLibraryManagerError.invalidState("note is too long")
        }
    }

    private func decodeState(at url: URL) throws -> UserLibraryState {
        do {
            let state = try JSONDecoder().decode(UserLibraryState.self, from: Data(contentsOf: url))
            try validate(state)
            return state
        } catch let error as UserLibraryManagerError {
            throw error
        } catch {
            throw UserLibraryManagerError.corruptedData
        }
    }

    private func writeState(_ state: UserLibraryState, to url: URL, updateRecovery: Bool) throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            if updateRecovery, fileManager.fileExists(atPath: url.path) {
                try copyReplacing(url, to: recoveryURL)
            }
            try data.write(to: url, options: .atomic)
        } catch let error as UserLibraryManagerError {
            throw error
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }

    private func ensureDirectory() throws {
        do {
            try fileManager.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }

    private func copyReplacing(_ source: URL, to destination: URL) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }
}

private struct LegacyUserMetadata: Codable {
    var favourites: Set<String> = []
    var toLearn: Set<String> = []
    var recentlyViewed: [String] = []
    var collections: [String: [String]] = [:]
}

private struct LegacyDefaultsBackup: Codable {
    let format: String
    let createdAt: Date
    let practiceData: Data?
    let metadataData: Data?

    init(practiceData: Data?, metadataData: Data?) {
        self.format = "shortcut-coach-legacy-userdefaults"
        self.createdAt = Date()
        self.practiceData = practiceData
        self.metadataData = metadataData
    }
}
