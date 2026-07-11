import ShortcutCoachCore
import SwiftUI

struct ResultsListView: View {
    @Bindable var store: ShortcutStore
    @FocusState private var searchFocused: Bool

    var body: some View {
        Group {
            if store.filteredShortcuts.isEmpty {
                ContentUnavailableView.search(text: store.query)
            } else {
                List(selection: $store.selectedShortcutID) {
                    ForEach(store.filteredShortcuts) { shortcut in
                        ResultRowView(shortcut: shortcut, store: store)
                            .tag(shortcut.id)
                    }
                }
                .listStyle(.inset)
                .onChange(of: store.selectedShortcutID) { _, id in
                    guard let id, let shortcut = store.shortcut(withID: id) else { return }
                    store.select(shortcut)
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $store.query, placement: .toolbar, prompt: "Action, app, keys, menu path, or task")
        .searchFocused($searchFocused)
        .onKeyPress("f", phases: .down) { press in
            guard press.modifiers == .command else { return .ignored }
            searchFocused = true
            return .handled
        }
        .accessibilityLabel("Shortcut results")
    }

    private var title: String {
        switch store.selectedSidebarItem {
        case .all: "All Shortcuts"
        case .favourites: "Favourites"
        case .toLearn: "To Learn"
        case .recentlyViewed: "Recently Viewed"
        case let .app(id): store.apps.first(where: { $0.id == id })?.name ?? "App"
        case let .tag(tag): tag
        case let .collection(id): store.userState.collections[id]?.name ?? "Collection"
        }
    }
}

private struct ResultRowView: View {
    let shortcut: ShortcutCatalogEntry
    let store: ShortcutStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: SupportedApp.app(withID: shortcut.appID)?.symbolName ?? "macwindow")
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.title)
                    .lineLimit(1)
                Text("\(shortcut.appName) · \(shortcut.category)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
            if store.favourites.contains(shortcut.id) {
                Image(systemName: "star.fill").foregroundStyle(.yellow).accessibilityLabel("Favourite")
            }
            if store.toLearn.contains(shortcut.id) {
                Image(systemName: "graduationcap.fill").foregroundStyle(.tint).accessibilityLabel("To Learn")
            }
            KeyCapRow(keys: shortcut.keys, compact: true)
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shortcut.appName), \(shortcut.title), \(shortcut.displayText)")
    }
}

struct KeyCapRow: View {
    let keys: [String]
    var compact = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: compact ? 2 : 5) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                Text(glyph(for: key))
                    .font(.system(compact ? .caption2 : .body, design: .rounded, weight: .medium))
                    .padding(.horizontal, compact ? 4 : 8)
                    .padding(.vertical, compact ? 2 : 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: compact ? 4 : 6))
                    .overlay {
                        if contrast == .increased {
                            RoundedRectangle(cornerRadius: compact ? 4 : 6).stroke(.secondary, lineWidth: 1)
                        }
                    }
                    .accessibilityLabel(accessibleName(for: key))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(keys.map(accessibleName).joined(separator: " plus "))
    }

    private func glyph(for key: String) -> String {
        switch key.lowercased() {
        case "command": "⌘"
        case "shift": "⇧"
        case "option": "⌥"
        case "control": "⌃"
        case "left arrow": "←"
        case "right arrow": "→"
        case "up arrow": "↑"
        case "down arrow": "↓"
        case "space": "Space"
        case "return": "↩"
        case "delete": "⌫"
        default: key.uppercased()
        }
    }

    private func accessibleName(for key: String) -> String { key }
}
