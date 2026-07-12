import Foundation

public struct ShortcutSearchQuery: Equatable, Sendable {
    public var text: String
    public var sidebar: SidebarSelection
    public var appID: String?
    public var tags: Set<String>

    public init(text: String = "", sidebar: SidebarSelection = .all, appID: String? = nil, tags: Set<String> = []) {
        self.text = text
        self.sidebar = sidebar
        self.appID = appID
        self.tags = tags
    }
}

public struct ShortcutSearchService: Sendable {
    public init() {}

    public func results(
        in entries: [ShortcutCatalogEntry],
        query: ShortcutSearchQuery,
        userState: UserLibraryState
    ) -> [ShortcutCatalogEntry] {
        var filtered = entries
        switch query.sidebar {
        case .all: break
        case .favourites: filtered.removeAll { !userState.favourites.contains($0.id) }
        case .toLearn: filtered.removeAll { !userState.toLearn.contains($0.id) }
        case .recentlyViewed:
            let order = Dictionary(uniqueKeysWithValues: userState.recents.enumerated().map { ($1, $0) })
            filtered = filtered.filter { order[$0.id] != nil }.sorted { order[$0.id]! < order[$1.id]! }
        case .myMacSystem: filtered.removeAll { $0.defaultStatus != "add" }
        case .myMacPersonal: filtered.removeAll { $0.defaultStatus != "keepSeparateFromBuiltInCatalog" }
        case let .app(appID): filtered.removeAll { $0.appID != appID }
        case let .tag(tag): filtered.removeAll { !$0.taskTags.contains(tag) }
        case let .category(cat): filtered.removeAll { $0.category != cat }
        case let .collection(collectionID):
            let IDs = userState.collections[collectionID]?.shortcutIDs ?? []
            filtered.removeAll { !IDs.contains($0.id) }
        }

        if let appID = query.appID { filtered.removeAll { $0.appID != appID } }
        if !query.tags.isEmpty { filtered.removeAll { !query.tags.isSubset(of: Set($0.taskTags)) } }

        let terms = query.text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        if !terms.isEmpty {
            filtered.removeAll { entry in
                let haystack = entry.searchableText.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                return !terms.allSatisfy(haystack.contains)
            }
        }

        if case .recentlyViewed = query.sidebar { return filtered }
        return filtered.sorted {
            if $0.appName != $1.appName { return $0.appName.localizedStandardCompare($1.appName) == .orderedAscending }
            return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }
}

public enum ShortcutFilters {
    private static let search = ShortcutSearchService()

    public static func today(_ shortcuts: [ShortcutCatalogEntry]) -> [ShortcutCatalogEntry] {
        Array(shortcuts.prefix(10))
    }

    public static func practice(_ shortcuts: [ShortcutCatalogEntry]) -> [ShortcutCatalogEntry] {
        Array(shortcuts.prefix(18))
    }

    public static func filter(
        _ shortcuts: [ShortcutCatalogEntry],
        query: String = "",
        context: String = "All",
        source: String = "All",
        priority: String = "All",
        tags: [String] = [],
        favouritesOnly: Bool = false,
        toLearnOnly: Bool = false,
        userState: UserLibraryState? = nil
    ) -> [ShortcutCatalogEntry] {
        let state = userState ?? UserLibraryState()
        let sidebar: SidebarSelection = favouritesOnly ? .favourites : (toLearnOnly ? .toLearn : .all)
        var results = search.results(
            in: shortcuts,
            query: ShortcutSearchQuery(
                text: query,
                sidebar: sidebar,
                appID: context == "All" ? nil : SupportedApp.launchApps.first(where: { $0.name == context })?.id,
                tags: Set(tags)
            ),
            userState: state
        )
        if source != "All" { results.removeAll { $0.source != source } }
        if priority != "All" { results.removeAll { $0.priorityLabel != priority } }
        return results
    }
}
