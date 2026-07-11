import AppKit
import Foundation
import Observation
import ShortcutCoachCore
import UniformTypeIdentifiers

@Observable
@MainActor
final class ShortcutStore {
    private(set) var catalog: ShortcutCatalog?
    private(set) var shortcuts: [ShortcutCatalogEntry] = []
    private(set) var sourceDescription = "Loading…"
    private(set) var userState = UserLibraryState()

    var selectedSidebarItem: SidebarSelection = .all
    var selectedShortcutID: String?
    var query = ""
    var errorMessage: String?
    var statusMessage: String?

    private let loader: CatalogLoader
    private let libraryManager: UserLibraryManager
    private let searchService: ShortcutSearchService

    init(
        loader: CatalogLoader = CatalogLoader(),
        libraryManager: UserLibraryManager = .shared,
        searchService: ShortcutSearchService = ShortcutSearchService()
    ) {
        self.loader = loader
        self.libraryManager = libraryManager
        self.searchService = searchService
        loadPersonalState()
        refreshCatalog()
    }

    var apps: [SupportedApp] { catalog?.apps ?? SupportedApp.launchApps }
    var selectedShortcut: ShortcutCatalogEntry? {
        shortcuts.first { $0.id == selectedShortcutID }
    }
    var allTags: [String] { Array(Set(shortcuts.flatMap(\.taskTags))).sorted() }
    var collections: [UserCollection] { userState.collections.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } }
    var favourites: Set<String> { userState.favourites }
    var toLearn: Set<String> { userState.toLearn }
    var recents: [String] { userState.recents }

    var filteredShortcuts: [ShortcutCatalogEntry] {
        results(text: query, sidebar: selectedSidebarItem)
    }

    func results(text: String, sidebar: SidebarSelection = .all, appID: String? = nil) -> [ShortcutCatalogEntry] {
        searchService.results(
            in: shortcuts,
            query: ShortcutSearchQuery(text: text, sidebar: sidebar, appID: appID),
            userState: userState
        )
    }

    func shortcut(withID id: String) -> ShortcutCatalogEntry? {
        shortcuts.first { $0.id == id }
    }

    func refreshCatalog() {
        do {
            let loaded = try loader.load()
            catalog = loaded.catalog
            shortcuts = loaded.catalog.shortcuts
            sourceDescription = loaded.sourceDescription
            errorMessage = nil
            if selectedShortcutID == nil || shortcut(withID: selectedShortcutID!) == nil {
                selectedShortcutID = filteredShortcuts.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func select(_ shortcut: ShortcutCatalogEntry) {
        selectedShortcutID = shortcut.id
        recordRecent(shortcut.id)
    }

    func openShortcut(_ shortcut: ShortcutCatalogEntry) {
        selectedSidebarItem = .all
        selectedShortcutID = shortcut.id
        recordRecent(shortcut.id)
    }

    func toggleFavourite(_ shortcut: ShortcutCatalogEntry) {
        if !userState.favourites.insert(shortcut.id).inserted { userState.favourites.remove(shortcut.id) }
        persist()
    }

    func toggleToLearn(_ shortcut: ShortcutCatalogEntry) {
        if !userState.toLearn.insert(shortcut.id).inserted { userState.toLearn.remove(shortcut.id) }
        persist()
    }

    func note(for shortcut: ShortcutCatalogEntry) -> String {
        userState.notes[shortcut.id] ?? ""
    }

    func setNote(_ note: String, for shortcut: ShortcutCatalogEntry) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { userState.notes.removeValue(forKey: shortcut.id) }
        else { userState.notes[shortcut.id] = String(note.prefix(20_000)) }
        persist()
    }

    @discardableResult
    func addCollection(named rawName: String) -> String? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !collections.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return nil }
        let collection = UserCollection(name: name)
        userState.collections[collection.id] = collection
        persist()
        return collection.id
    }

    func removeCollection(id: String) {
        userState.collections.removeValue(forKey: id)
        if selectedSidebarItem == .collection(id) { selectedSidebarItem = .all }
        persist()
    }

    func contains(_ shortcut: ShortcutCatalogEntry, in collectionID: String) -> Bool {
        userState.collections[collectionID]?.shortcutIDs.contains(shortcut.id) == true
    }

    func toggle(_ shortcut: ShortcutCatalogEntry, in collectionID: String) {
        guard var collection = userState.collections[collectionID] else { return }
        if !collection.shortcutIDs.insert(shortcut.id).inserted { collection.shortcutIDs.remove(shortcut.id) }
        userState.collections[collectionID] = collection
        persist()
    }

    func exportBackup() {
        let panel = NSSavePanel()
        panel.title = "Export Personal State"
        panel.nameFieldStringValue = "Shortcut-Coach-Personal-State.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try libraryManager.export(to: url, state: userState)
            statusMessage = "Personal state exported."
        } catch { errorMessage = error.localizedDescription }
    }

    func importBackup() {
        let panel = NSOpenPanel()
        panel.title = "Import Personal State"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            userState = try libraryManager.import(from: url)
            selectedSidebarItem = .all
            selectedShortcutID = filteredShortcuts.first?.id
            statusMessage = "Personal state imported."
        } catch { errorMessage = error.localizedDescription }
    }

    private func loadPersonalState() {
        do { userState = try libraryManager.load() }
        catch { errorMessage = error.localizedDescription }
    }

    private func recordRecent(_ id: String) {
        userState.recents.removeAll { $0 == id }
        userState.recents.insert(id, at: 0)
        userState.recents = Array(userState.recents.prefix(50))
        persist()
    }

    private func persist() {
        do { try libraryManager.save(userState) }
        catch { errorMessage = error.localizedDescription }
    }
}
