import Foundation

public enum UserLibraryManagerError: LocalizedError {
    case corruptedData
    case ioError(String)
    
    public var errorDescription: String? {
        switch self {
        case .corruptedData:
            return "The user library data is corrupted or invalid."
        case .ioError(let message):
            return "File system error: \(message)"
        }
    }
}

public final class UserLibraryManager: Sendable {
    public static let shared = UserLibraryManager()
    
    public let defaultFileURL: URL
    
    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.defaultFileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("ShortcutCoach")
            self.defaultFileURL = appDir.appendingPathComponent("UserLibraryState.json")
        }
        
        let dir = defaultFileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    public func load() throws -> UserLibraryState {
        migrateIfNeeded()
        
        guard FileManager.default.fileExists(atPath: defaultFileURL.path) else {
            return UserLibraryState()
        }
        
        do {
            let data = try Data(contentsOf: defaultFileURL)
            return try JSONDecoder().decode(UserLibraryState.self, from: data)
        } catch {
            throw UserLibraryManagerError.corruptedData
        }
    }
    
    public func save(_ state: UserLibraryState) throws {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: defaultFileURL, options: .atomic)
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }
    
    public func export(to url: URL, state: UserLibraryState) throws {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: .atomic)
        } catch {
            throw UserLibraryManagerError.ioError(error.localizedDescription)
        }
    }
    
    public func `import`(from url: URL) throws -> UserLibraryState {
        let data = try Data(contentsOf: url)
        do {
            let importedState = try JSONDecoder().decode(UserLibraryState.self, from: data)
            try? backupCurrentState()
            try save(importedState)
            return importedState
        } catch {
            throw UserLibraryManagerError.corruptedData
        }
    }
    
    private func backupCurrentState() throws {
        guard FileManager.default.fileExists(atPath: defaultFileURL.path) else { return }
        let backupURL = defaultFileURL.deletingLastPathComponent().appendingPathComponent("UserLibraryState_backup.json")
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        try FileManager.default.copyItem(at: defaultFileURL, to: backupURL)
    }
    
    public func migrateIfNeeded() {
        guard !FileManager.default.fileExists(atPath: defaultFileURL.path) else { return }
        
        guard let data = UserDefaults.standard.data(forKey: "shortcutCoach.dailyPracticeSnapshot"),
              let snapshot = try? JSONDecoder().decode(DailyPracticeSnapshot.self, from: data) else {
            return
        }
        
        var state = UserLibraryState()
        state.practiceSnapshot = snapshot
        
        let backupURL = defaultFileURL.deletingLastPathComponent().appendingPathComponent("UserLibraryState_migration_backup.json")
        try? data.write(to: backupURL)
        
        try? save(state)
    }
}
