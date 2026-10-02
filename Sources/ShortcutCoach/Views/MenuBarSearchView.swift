import AppKit
import ShortcutCoachCore
import SwiftUI

struct MenuBarSearchView: View {
    @Bindable var store: ShortcutStore
    @State private var query = ""
    @State private var selectedAppID: String?
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Picker("Scope", selection: $selectedAppID) {
                    Text("Everything").tag(String?.none)
                    if store.environmentState == .loaded {
                        Text("My Mac").tag(Optional(ShortcutQueryScopeAdapter.myMacAppID))
                    }
                    Divider()
                    ForEach(store.apps) { app in Text(app.name).tag(Optional(app.id)) }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Shortcut scope")
                .accessibilityHint("Choose Everything, My Mac, or one supported app")

                TextField("Search shortcuts", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .focused($searchFocused)
                    .accessibilityLabel("Search shortcuts")
                    .accessibilityHint("Matches actions, apps, keys, outputs, sources, categories, and guidance")
                    .overlay(alignment: .trailing) {
                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 6)
                            .accessibilityLabel("Clear search")
                            .help("Clear search")
                        }
                    }

                if let notice = store.environmentNotice {
                    Label("My Mac unavailable; apps work", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .help(notice.detail)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(notice.title). \(notice.detail)")
                }
            }
            .padding(12)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if favourites.isEmpty && recents.isEmpty {
                            ContentUnavailableView(
                                "No Saved Shortcuts Yet",
                                systemImage: "star",
                                description: Text("Favourites and recently viewed shortcuts appear here.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                        } else {
                            resultSection("Favourites", icon: "star.fill", entries: favourites)
                            resultSection("Recently Viewed", icon: "clock", entries: recents)
                        }
                    } else if searchResults.isEmpty {
                        ContentUnavailableView.search(text: query)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    } else {
                        resultSection("Results", icon: "magnifyingglass", entries: searchResults)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()
            Button {
                showMainWindow()
            } label: {
                Label("Open Shortcut Coach", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .padding(12)
            .keyboardShortcut("o", modifiers: .command)
        }
        .background(.regularMaterial)
        .task { searchFocused = true }
        .onKeyPress(.escape, phases: .down) { _ in
            guard !query.isEmpty else { return .ignored }
            query = ""
            return .handled
        }
        .onChange(of: store.environmentState) { _, state in
            if state != .loaded, selectedAppID == ShortcutQueryScopeAdapter.myMacAppID {
                selectedAppID = nil
            }
        }
    }

    private var searchResults: [ShortcutCatalogEntry] {
        store.menuBarResults(text: query, appID: selectedAppID)
    }

    private var favourites: [ShortcutCatalogEntry] {
        Array(store.menuBarResults(text: "", appID: selectedAppID, section: .favourites).prefix(6))
    }

    private var recents: [ShortcutCatalogEntry] {
        Array(store.menuBarResults(text: "", appID: selectedAppID, section: .recentlyViewed).prefix(6))
    }

    @ViewBuilder
    private func resultSection(_ title: String, icon: String, entries: [ShortcutCatalogEntry]) -> some View {
        if !entries.isEmpty {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 7)
            ForEach(entries) { shortcut in
                Button {
                    store.openShortcut(shortcut)
                    showMainWindow()
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(CoachFormatters.shortAction(shortcut.title))
                                .lineLimit(1)
                            Text(shortcut.owner ?? shortcut.appName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(shortcut.displayText)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(shortcut.title) in Shortcut Coach, \(shortcut.displayText)")
            }
        }
    }

    private func showMainWindow() {
        MainWindowCoordinator.shared.show(store: store)
    }
}
