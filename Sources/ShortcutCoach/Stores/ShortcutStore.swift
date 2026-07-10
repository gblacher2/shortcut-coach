import AppKit
import Foundation
import ShortcutCoachCore
import SwiftUI

@Observable
@MainActor
final class ShortcutStore {
    var catalog: ShortcutCatalog?
    var shortcuts: [ShortcutCatalogEntry] = []
    var sourceDescription = "Not loaded"
    var lastLoadedAt: Date?
    var errorMessage: String?
    var selectedTab: ShortcutTab = .today
    var query = ""
    var selectedContext = "All"
    var selectedSource = "All"
    var selectedPriority = "All"
    var revealedPracticeIDs: Set<String> = []
    
    // UI State
    var selectedSidebarItem: SidebarSelection? = .all
    var selectedShortcut: ShortcutCatalogEntry?
    
    // User metadata
    var favourites: Set<String> = []
    var toLearn: Set<String> = []
    var recentlyViewed: [String] = []
    var collections: [String: [String]] = [:] // Collection name -> [Shortcut IDs]
    
    var practiceSnapshot = DailyPracticeSnapshot(dayKey: DailyPracticeProgress.dayKey(for: Date()))
    var isAccessibilityTrusted = AXIsProcessTrusted()
    // Every non-deinit access is @MainActor-isolated and deinit cannot overlap live references, so there is no race today.
    @ObservationIgnored
    nonisolated(unsafe) private var eventMonitor: Any?
    @ObservationIgnored
    nonisolated(unsafe) private var localEventMonitor: Any?
    @ObservationIgnored
    nonisolated(unsafe) private var permissionTimer: Timer?
    @ObservationIgnored
    nonisolated(unsafe) private var terminateObserver: NSObjectProtocol?

    var enableAutoTracking: Bool = false {
        didSet {
            UserDefaults.standard.set(enableAutoTracking, forKey: "shortcutCoach.enableAutoTracking")
            if enableAutoTracking && !isAccessibilityTrusted {
                requestAccessibilityPermission()
            }
            checkAccessibilityPermission()
        }
    }

    private let loader: CatalogLoader
    @ObservationIgnored
    @AppStorage("shortcutCoach.dailyPracticeSnapshot") private var storedPracticeData = Data()
    @ObservationIgnored
    @AppStorage("shortcutCoach.userMetadata") private var storedUserMetadata = Data()

    init(loader: CatalogLoader = CatalogLoader()) {
        self.loader = loader
        self.enableAutoTracking = UserDefaults.standard.bool(forKey: "shortcutCoach.enableAutoTracking")
        practiceSnapshot = DailyPracticeProgress.currentSnapshot(from: storedPracticeData)
        loadUserMetadata()
        refresh()
        checkAccessibilityPermission()
        
        terminateObserver = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.teardownTracking() }
        }
    }

    deinit {
        if let observer = terminateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        // NSEvent.removeMonitor must run on the main run loop where it was installed,
        // but deinit is nonisolated and may run on any thread. We do a best-effort removal here.
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @MainActor
    func teardownTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        stopPermissionTimer()
    }

    var contexts: [String] {
        ["All"] + uniqueValues(\.context)
    }

    var sources: [String] {
        ["All"] + uniqueValues(\.source)
    }

    var allTags: [String] {
        let set = Set(shortcuts.flatMap { $0.tags } + shortcuts.map { $0.context })
        return Array(set).sorted()
    }

    var priorities: [String] {
        ["All", "Daily", "Weekly", "Reference"]
    }

    var todayShortcuts: [ShortcutCatalogEntry] {
        ShortcutFilters.today(shortcuts)
    }
    
    var filteredBySidebarShortcuts: [ShortcutCatalogEntry] {
        var base = shortcuts
        switch selectedSidebarItem {
        case .all:
            break
        case .favourites:
            base = base.filter { favourites.contains($0.id) }
        case .toLearn:
            base = base.filter { toLearn.contains($0.id) }
        case .recentlyViewed:
            let recents = recentlyViewed
            base = base.filter { recents.contains($0.id) }
                .sorted {
                    (recents.firstIndex(of: $0.id) ?? 999) < (recents.firstIndex(of: $1.id) ?? 999)
                }
        case .app(let appName):
            base = base.filter { $0.source == appName }
        case .tag(let tagName):
            base = base.filter { $0.tags.contains(tagName) || $0.context == tagName }
        case .collection(let collectionName):
            if let ids = collections[collectionName] {
                base = base.filter { ids.contains($0.id) }
            } else {
                base = []
            }
        case .none:
            base = []
        }
        
        if !query.isEmpty {
            let lowerQuery = query.lowercased()
            base = base.filter {
                $0.action.lowercased().contains(lowerQuery) ||
                $0.shortcut.lowercased().contains(lowerQuery) ||
                $0.id.lowercased().contains(lowerQuery) ||
                $0.source.lowercased().contains(lowerQuery)
            }
        }
        return base
    }

    var filteredShortcuts: [ShortcutCatalogEntry] {
        ShortcutFilters.filter(
            shortcuts,
            query: query,
            context: selectedContext,
            source: selectedSource,
            priority: selectedPriority
        )
    }

    var practiceShortcuts: [ShortcutCatalogEntry] {
        ShortcutFilters.practice(shortcuts)
    }

    var completedDailyCount: Int {
        DailyPracticeProgress.completedCount(todayShortcuts: todayShortcuts, snapshot: practiceSnapshot)
    }

    var totalDailyCount: Int {
        todayShortcuts.count
    }

    var dailyProgressSummary: String {
        "\(completedDailyCount) of \(totalDailyCount) practiced today"
    }

    func refresh() {
        refreshPracticeSnapshot()
        do {
            let loaded = try loader.load()
            catalog = loaded.catalog
            shortcuts = loaded.catalog.shortcuts
            sourceDescription = loaded.sourceDescription
            lastLoadedAt = Date()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load shortcuts: \(error.localizedDescription)"
        }
    }

    func isPracticed(_ shortcut: ShortcutCatalogEntry) -> Bool {
        practiceSnapshot.practicedIDs.contains(shortcut.id)
    }

    func togglePracticed(_ shortcut: ShortcutCatalogEntry) {
        refreshPracticeSnapshot()
        practiceSnapshot = DailyPracticeProgress.toggled(shortcut.id, in: practiceSnapshot)
        storedPracticeData = DailyPracticeProgress.encoded(practiceSnapshot)
    }

    func togglePracticeAnswer(for shortcut: ShortcutCatalogEntry) {
        if revealedPracticeIDs.contains(shortcut.id) {
            revealedPracticeIDs.remove(shortcut.id)
        } else {
            revealedPracticeIDs.insert(shortcut.id)
        }
    }

    func isPracticeAnswerRevealed(for shortcut: ShortcutCatalogEntry) -> Bool {
        revealedPracticeIDs.contains(shortcut.id)
    }

    func openFullGuide() {
        NSWorkspace.shared.open(CatalogLoader.fullGuideURL)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - User Metadata Management
    
    func toggleFavourite(_ shortcut: ShortcutCatalogEntry) {
        if favourites.contains(shortcut.id) {
            favourites.remove(shortcut.id)
        } else {
            favourites.insert(shortcut.id)
        }
        saveUserMetadata()
    }
    
    func toggleToLearn(_ shortcut: ShortcutCatalogEntry) {
        if toLearn.contains(shortcut.id) {
            toLearn.remove(shortcut.id)
        } else {
            toLearn.insert(shortcut.id)
        }
        saveUserMetadata()
    }
    
    func addRecentlyViewed(_ shortcut: ShortcutCatalogEntry) {
        recentlyViewed.removeAll { $0 == shortcut.id }
        recentlyViewed.insert(shortcut.id, at: 0)
        if recentlyViewed.count > 50 {
            recentlyViewed.removeLast(recentlyViewed.count - 50)
        }
        saveUserMetadata()
    }
    
    func addCollection(_ name: String) {
        if collections[name] == nil {
            collections[name] = []
            saveUserMetadata()
        }
    }
    
    func removeCollection(_ name: String) {
        collections[name] = nil
        saveUserMetadata()
    }
    
    func toggleShortcutInCollection(_ shortcut: ShortcutCatalogEntry, collection: String) {
        guard var items = collections[collection] else { return }
        if let idx = items.firstIndex(of: shortcut.id) {
            items.remove(at: idx)
        } else {
            items.append(shortcut.id)
        }
        collections[collection] = items
        saveUserMetadata()
    }
    
    private struct UserMetadata: Codable {
        var favourites: Set<String> = []
        var toLearn: Set<String> = []
        var recentlyViewed: [String] = []
        var collections: [String: [String]] = [:]
    }
    
    private func loadUserMetadata() {
        guard let data = try? JSONDecoder().decode(UserMetadata.self, from: storedUserMetadata) else { return }
        self.favourites = data.favourites
        self.toLearn = data.toLearn
        self.recentlyViewed = data.recentlyViewed
        self.collections = data.collections
    }
    
    private func saveUserMetadata() {
        let metadata = UserMetadata(
            favourites: favourites,
            toLearn: toLearn,
            recentlyViewed: recentlyViewed,
            collections: collections
        )
        if let data = try? JSONEncoder().encode(metadata) {
            storedUserMetadata = data
        }
    }

    private func uniqueValues(_ keyPath: KeyPath<ShortcutCatalogEntry, String>) -> [String] {
        Array(Set(shortcuts.map { $0[keyPath: keyPath] })).sorted()
    }

    private func refreshPracticeSnapshot() {
        let current = DailyPracticeProgress.currentSnapshot(from: storedPracticeData)
        if current != practiceSnapshot {
            practiceSnapshot = current
            storedPracticeData = DailyPracticeProgress.encoded(current)
        }
    }

    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        if trusted != isAccessibilityTrusted {
            isAccessibilityTrusted = trusted
        }
        updateEventMonitor()

        if enableAutoTracking && !trusted {
            startPermissionTimer()
        } else {
            stopPermissionTimer()
        }
    }

    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted != isAccessibilityTrusted {
            isAccessibilityTrusted = trusted
        }
    }

    private func startPermissionTimer() {
        guard permissionTimer == nil else { return }
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkAccessibilityPermission() }
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionTimer = timer
    }

    private func stopPermissionTimer() {
        permissionTimer?.invalidate()
        permissionTimer = nil
    }

    func pausePermissionTimer() {
        stopPermissionTimer()
    }

    func updateEventMonitor() {
        if enableAutoTracking && AXIsProcessTrusted() {
            if eventMonitor == nil {
                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    let flags = event.modifierFlags
                    let chars = event.charactersIgnoringModifiers ?? ""
                    MainActor.assumeIsolated { self?.handleGlobalKeyDown(flags: flags, chars: chars) }
                }
            }
            if localEventMonitor == nil {
                localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    let flags = event.modifierFlags
                    let chars = event.charactersIgnoringModifiers ?? ""
                    MainActor.assumeIsolated { self?.handleGlobalKeyDown(flags: flags, chars: chars) }
                    return event
                }
            }
        } else {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
            if let monitor = localEventMonitor {
                NSEvent.removeMonitor(monitor)
                localEventMonitor = nil
            }
        }
    }

    private func handleGlobalKeyDown(flags: NSEvent.ModifierFlags, chars: String) {
        let recognized: NSEvent.ModifierFlags = [.command, .control, .option, .shift, .function]
        guard !flags.intersection(recognized).isEmpty else { return }

        let activeShortcuts = todayShortcuts
        for shortcut in activeShortcuts {
            if shortcut.matches(flags: flags, charsIgnoringModifiers: chars) {
                if !isPracticed(shortcut) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        togglePracticed(shortcut)
                    }
                }
                break
            }
        }
    }
}
