import ShortcutCoachCore
import SwiftUI

struct SidebarView: View {
    @Bindable var store: ShortcutStore
    @Binding var selection: SidebarSelection
    @State private var isCreatingCollection = false
    @State private var collectionName = ""

    var body: some View {
        List(selection: $selection) {
            Section("Library") {
                sidebarRow("All Shortcuts", symbol: "tray.full", value: .all)
                sidebarRow("Favourites", symbol: "star", value: .favourites)
                sidebarRow("To Learn", symbol: "graduationcap", value: .toLearn)
                sidebarRow("Recently Viewed", symbol: "clock", value: .recentlyViewed)
            }

            Section("My Mac") {
                sidebarRow("All My Mac Shortcuts", symbol: "macbook", value: .app("my-mac"))
                sidebarRow("macOS System", symbol: "applelogo", value: .myMacSystem)
                sidebarRow("Personal Setup", symbol: "person.crop.circle", value: .myMacPersonal)
                sidebarRow("Window Management", symbol: "macwindow", value: .category("window-management"))
                sidebarRow("Spaces & Mission Control", symbol: "square.grid.3x3", value: .category("spaces-mission-control"))
                sidebarRow("Text Editing", symbol: "character.cursor.ibeam", value: .category("text-editing"))
                sidebarRow("Input Sources", symbol: "keyboard", value: .category("input-sources"))
            }

            Section("Apps") {
                ForEach(store.apps) { app in
                    sidebarRow(app.name, symbol: app.symbolName, value: .app(app.id))
                }
            }

            if !store.allTags.isEmpty {
                Section("Tasks") {
                    ForEach(store.allTags, id: \.self) { tag in
                        sidebarRow(tag, symbol: "tag", value: .tag(tag))
                    }
                }
            }

            Section("Collections") {
                ForEach(store.collections) { collection in
                    sidebarRow(collection.name, symbol: "folder", value: .collection(collection.id))
                        .contextMenu {
                            Button("Delete Collection", role: .destructive) {
                                store.removeCollection(id: collection.id)
                            }
                        }
                }
                Button {
                    collectionName = ""
                    isCreatingCollection = true
                } label: {
                    Label("New Collection", systemImage: "plus")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Creates a local collection for saved shortcuts")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Shortcut Coach")
        .alert("New Collection", isPresented: $isCreatingCollection) {
            TextField("Collection name", text: $collectionName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                if let id = store.addCollection(named: collectionName) { selection = .collection(id) }
            }
            .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Collections stay in the personal library on this Mac.")
        }
    }

    private func sidebarRow(_ title: String, symbol: String, value: SidebarSelection) -> some View {
        Label(title, systemImage: symbol)
            .tag(value)
            .accessibilityLabel(title)
    }
}
