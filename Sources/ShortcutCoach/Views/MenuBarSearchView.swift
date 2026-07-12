import AppKit
import ShortcutCoachCore
import SwiftUI

struct MenuBarSearchView: View {
    @Bindable var store: ShortcutStore
    @Environment(\.openWindow) private var openWindow
    @State private var query = ""
    @State private var selectedAppID: String?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Picker("Scope", selection: $selectedAppID) {
                    Text("Everything").tag(String?.none)
                    Text("My Mac").tag(Optional("my-mac"))
                    Divider()
                    ForEach(store.apps) { app in Text(app.name).tag(Optional(app.id)) }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Manual scope filter")

                TextField("Search shortcuts", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityHint("Matches actions, apps, keys, menu paths, categories, and guidance")
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
    }

    private var searchResults: [ShortcutCatalogEntry] {
        store.results(text: query, appID: selectedAppID)
    }

    private var favourites: [ShortcutCatalogEntry] {
        Array(store.results(text: "", sidebar: .favourites, appID: selectedAppID).prefix(6))
    }

    private var recents: [ShortcutCatalogEntry] {
        Array(store.results(text: "", sidebar: .recentlyViewed, appID: selectedAppID).prefix(6))
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
        openWindow(id: "main")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
