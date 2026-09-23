import Foundation

public struct DailyPracticeSnapshot: Codable, Equatable, Sendable {
    public let dayKey: String
    public var practicedIDs: Set<String>

    public init(dayKey: String, practicedIDs: Set<String> = []) {
        self.dayKey = dayKey
        self.practicedIDs = practicedIDs
    }
}

public enum DailyPracticeProgress {
    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func currentSnapshot(
        from storedData: Data?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DailyPracticeSnapshot {
        let todayKey = dayKey(for: now, calendar: calendar)
        guard
            let storedData,
            let decoded = try? JSONDecoder().decode(DailyPracticeSnapshot.self, from: storedData),
            decoded.dayKey == todayKey
        else {
            return DailyPracticeSnapshot(dayKey: todayKey)
        }
        return decoded
    }

    public static func encoded(_ snapshot: DailyPracticeSnapshot) -> Data {
        (try? JSONEncoder().encode(snapshot)) ?? Data()
    }

    public static func toggled(
        _ shortcutID: String,
        in snapshot: DailyPracticeSnapshot
    ) -> DailyPracticeSnapshot {
        var updated = snapshot
        if updated.practicedIDs.contains(shortcutID) {
            updated.practicedIDs.remove(shortcutID)
        } else {
            updated.practicedIDs.insert(shortcutID)
        }
        return updated
    }

    public static func completedCount(todayShortcuts: [ShortcutCatalogEntry], snapshot: DailyPracticeSnapshot) -> Int {
        todayShortcuts.filter { snapshot.practicedIDs.contains($0.id) }.count
    }
}
