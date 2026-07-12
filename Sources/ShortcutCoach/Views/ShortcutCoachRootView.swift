import SwiftUI

struct ShortcutCoachRootView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, selection: $store.selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 190, ideal: 225, max: 280)
        } content: {
            ResultsListView(store: store)
                .navigationSplitViewColumnWidth(min: 360, ideal: 430, max: 560)
        } detail: {
            InspectorView(shortcut: store.selectedShortcut, store: store)
                .navigationSplitViewColumnWidth(min: 330, ideal: 430)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: store.selectedSidebarItem) { _, _ in
            // Preserve a shortcut opened from MenuBarExtra when moving back to
            // All Shortcuts. Only replace selections that are outside the new scope.
            store.reconcileSelectedShortcut()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Export Personal State…", systemImage: "square.and.arrow.up") { store.exportBackup() }
                    Button("Import Personal State…", systemImage: "square.and.arrow.down") { store.importBackup() }
                } label: {
                    Label("Backup", systemImage: "externaldrive")
                }
                .help("Export or import favourites, To Learn, collections, notes, and recents")
            }
        }
        .alert("Shortcut Coach", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "Unknown error")
        }
        .alert("Shortcut Coach", isPresented: Binding(
            get: { store.statusMessage != nil },
            set: { if !$0 { store.statusMessage = nil } }
        )) {
            Button("OK") { store.statusMessage = nil }
        } message: {
            Text(store.statusMessage ?? "Operation completed.")
        }
    }
}
