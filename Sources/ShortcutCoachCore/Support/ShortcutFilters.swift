import Foundation

public enum ShortcutFilters {
    public static func today(_ shortcuts: [ShortcutCatalogEntry]) -> [ShortcutCatalogEntry] {
        shortcuts
            .filter { $0.active && $0.priority == 1 }
            .sorted { first, second in
                let firstSourceRank = sourceRank(first.source)
                let secondSourceRank = sourceRank(second.source)
                if firstSourceRank != secondSourceRank {
                    return firstSourceRank < secondSourceRank
                }
                if first.context != second.context {
                    return first.context < second.context
                }
                return first.shortcut < second.shortcut
            }
            .prefix(10)
            .map { $0 }
    }

    public static func practice(_ shortcuts: [ShortcutCatalogEntry]) -> [ShortcutCatalogEntry] {
        shortcuts
            .filter { $0.active && $0.priority <= 2 }
            .sorted { first, second in
                if first.priority != second.priority {
                    return first.priority < second.priority
                }
                if first.context != second.context {
                    return first.context < second.context
                }
                return first.shortcut < second.shortcut
            }
            .prefix(18)
            .map { $0 }
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
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return shortcuts.filter { shortcut in
            let matchesQuery: Bool
            if normalizedQuery.isEmpty {
                matchesQuery = true
            } else {
                let searchable = [
                    shortcut.shortcut,
                    shortcut.action,
                    shortcut.source,
                    shortcut.scope,
                    shortcut.context,
                    shortcut.notes
                ].joined(separator: " ").lowercased()
                matchesQuery = searchable.contains(normalizedQuery)
            }

            let matchesContext = context == "All" || shortcut.context == context
            let matchesSource = source == "All" || shortcut.source == source
            let matchesPriority = priority == "All" || shortcut.priorityLabel == priority
            
            let matchesTags = tags.isEmpty || tags.allSatisfy { shortcut.tags.contains($0) }
            
            let matchesFavs = !favouritesOnly || (userState?.favourites.contains(shortcut.id) == true)
            let matchesToLearn = !toLearnOnly || (userState?.toLearn.contains(shortcut.id) == true)
            
            return matchesQuery && matchesContext && matchesSource && matchesPriority && matchesTags && matchesFavs && matchesToLearn
        }
    }

    private static func sourceRank(_ source: String) -> Int {
        switch source {
        case "Karabiner":
            0
        case "macOS setting":
            1
        case "macOS default":
            2
        case "macOS/app default":
            3
        default:
            9
        }
    }
}
