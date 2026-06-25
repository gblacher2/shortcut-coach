import Foundation

public enum CoachFormatters {
    public static func metadataLine(catalog: ShortcutCatalog?, source: String, loadedAt: Date?) -> String {
        guard let catalog else {
            return source
        }

        let profile = catalog.metadata.selectedKarabinerProfile ?? "Unknown profile"
        let timePart: String
        if let loadedAt {
            timePart = DateFormatter.localizedString(from: loadedAt, dateStyle: .none, timeStyle: .short)
        } else {
            timePart = "not loaded"
        }
        return "\(source) - \(catalog.shortcuts.count) shortcuts - \(profile) - \(timePart)"
    }

    public static func shortAction(_ action: String) -> String {
        if action.count <= 30 {
            return action
        }
        return String(action.prefix(27)) + "..."
    }
}
