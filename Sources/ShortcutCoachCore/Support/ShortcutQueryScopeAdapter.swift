import Foundation

/// Builds the canonical search query used by both the main window and MenuBarExtra.
///
/// Keeping surface-specific state conversion here prevents the two interfaces from
/// silently drifting into different search and filtering behavior.
public enum ShortcutQueryScopeAdapter {
    public static let myMacAppID = "my-mac"

    private static let myMacCategories: Set<String> = [
        "input-sources",
        "mission-control",
        "spaces",
        "spaces-mission-control",
        "text-editing",
        "window-management"
    ]

    public static func fullWindow(
        text: String = "",
        sidebar: SidebarSelection,
        tags: Set<String> = []
    ) -> ShortcutSearchQuery {
        ShortcutSearchQuery(
            text: text,
            sidebar: sidebar,
            appID: appIDRequiredBySidebar(sidebar),
            tags: tags
        )
    }

    public static func menuBar(
        text: String = "",
        appID: String?,
        section: SidebarSelection = .all,
        tags: Set<String> = []
    ) -> ShortcutSearchQuery {
        if section == .all, let appID {
            // Match the exact query shape produced by selecting the same app in
            // the main-window sidebar, not merely an equivalent result set.
            return fullWindow(text: text, sidebar: .app(appID), tags: tags)
        }

        return ShortcutSearchQuery(
            text: text,
            sidebar: section,
            appID: appID,
            tags: tags
        )
    }

    public static func isMyMacSelection(_ selection: SidebarSelection) -> Bool {
        switch selection {
        case .myMacSystem, .myMacPersonal:
            true
        case let .app(appID) where appID == myMacAppID:
            true
        case let .category(category):
            myMacCategories.contains(category)
        default:
            false
        }
    }

    private static func appIDRequiredBySidebar(_ sidebar: SidebarSelection) -> String? {
        switch sidebar {
        case .myMacSystem, .myMacPersonal:
            myMacAppID
        case let .category(category) where myMacCategories.contains(category):
            myMacAppID
        default:
            nil
        }
    }
}
