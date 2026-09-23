import AppKit
import Foundation
import Observation
import ShortcutCoachCore
import UniformTypeIdentifiers

@Observable
@MainActor
final class ShortcutStore {
    static let shared = ShortcutStore()

    private(set) var catalog: ShortcutCatalog?
    private(set) var shortcuts: [ShortcutCatalogEntry] = []
    private(set) var sourceDescription = "Loading…"
    private(set) var userState = UserLibraryState()
    private(set) var environmentConflictsByID: [String: EnvironmentConflict] = [:]

    var selectedSidebarItem: SidebarSelection = .all
    var selectedShortcutID: String?
    var query = ""
    var errorMessage: String?
    var statusMessage: String?
    private(set) var environmentState: EnvironmentState = .missing

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
        let personalStateError = loadPersonalState()
        refreshCatalog()
        if let personalStateError {
            errorMessage = personalStateError
        }
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

    var environmentNotice: EnvironmentAvailabilityNotice? {
        switch environmentState {
        case .loaded:
            nil
        case .missing:
            EnvironmentAvailabilityNotice(
                title: "My Mac setup not found",
                detail: "The nine-app library remains available. Add a valid local environment file to restore My Mac shortcuts."
            )
        case let .rejected(reason):
            EnvironmentAvailabilityNotice(
                title: "My Mac setup could not be loaded",
                detail: "The nine-app library remains available. Reason: \(Self.safeEnvironmentReason(reason))."
            )
        }
    }

    var filteredShortcuts: [ShortcutCatalogEntry] {
        results(matching: ShortcutQueryScopeAdapter.fullWindow(text: query, sidebar: selectedSidebarItem))
    }

    func results(matching query: ShortcutSearchQuery) -> [ShortcutCatalogEntry] {
        searchService.results(
            in: shortcuts,
            query: query,
            userState: userState
        )
    }

    func menuBarResults(
        text: String,
        appID: String?,
        section: SidebarSelection = .all
    ) -> [ShortcutCatalogEntry] {
        results(matching: ShortcutQueryScopeAdapter.menuBar(text: text, appID: appID, section: section))
    }

    func shortcut(withID id: String) -> ShortcutCatalogEntry? {
        shortcuts.first { $0.id == id }
    }

    func environmentConflict(withID id: String) -> EnvironmentConflict? {
        environmentConflictsByID[id]
    }

    func refreshCatalog() {
        do {
            let loaded = try loader.load()
            catalog = loaded.catalog
            shortcuts = loaded.catalog.shortcuts
            sourceDescription = loaded.sourceDescription
            environmentState = loaded.environmentState
            environmentConflictsByID = loaded.environmentConflictsByID
            errorMessage = nil

            if environmentState != .loaded,
               ShortcutQueryScopeAdapter.isMyMacSelection(selectedSidebarItem) {
                selectedSidebarItem = .all
            }

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

    func reconcileSelectedShortcut() {
        let visibleShortcuts = filteredShortcuts
        let visibleIDs = Set(visibleShortcuts.map(\.id))
        if let selectedShortcutID, visibleIDs.contains(selectedShortcutID) {
            return
        }
        selectedShortcutID = visibleShortcuts.first?.id
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
            errorMessage = nil
            statusMessage = "Personal state exported."
        } catch {
            statusMessage = nil
            errorMessage = error.localizedDescription
        }
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
            errorMessage = nil
            statusMessage = "Personal state imported."
        } catch {
            statusMessage = nil
            errorMessage = error.localizedDescription
        }
    }

    private func loadPersonalState() -> String? {
        do {
            userState = try libraryManager.load()
            return nil
        } catch {
            return error.localizedDescription
        }
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

    private static func safeEnvironmentReason(_ rawReason: String) -> String {
        let reason = rawReason.lowercased()

        if reason.contains("unsupported") && reason.contains("format") {
            return "the environment format is unsupported"
        }
        if reason.contains("unsupported") && reason.contains("schema") {
            return "the environment schema version is unsupported"
        }
        if reason.contains("duplicate") {
            return "the environment contains duplicate identifiers"
        }
        if reason.contains("collid") {
            return "an environment identifier conflicts with the built-in library"
        }
        if reason.contains("dangling") || reason.contains("references") {
            return "the environment contains an invalid reference"
        }
        if reason.contains("overlap") || reason.contains("classification") || reason.contains("coverage") {
            return "the environment classifications are inconsistent"
        }
        if reason.contains("display text") || reason.contains("displaytext") || reason.contains("ordered keys") {
            return "a shortcut chord does not match its ordered keys"
        }
        if reason.contains("missing required") || reason.contains("blank") || reason.contains("nonblank") {
            return "required shortcut metadata is incomplete"
        }
        if reason.contains("decode") || reason.contains("data corrupted") || reason.contains("not valid")
            || reason.contains("malformed") || reason.contains("could not be read") {
            return "the environment file is malformed"
        }

        return "the local environment did not pass validation"
    }
}

struct EnvironmentAvailabilityNotice: Equatable {
    let title: String
    let detail: String
}
