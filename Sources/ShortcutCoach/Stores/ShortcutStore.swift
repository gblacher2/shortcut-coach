import AppKit
import Foundation
import ShortcutCoachCore
import SwiftUI

@Observable
@MainActor
final class ShortcutStore {
    var catalog: ShortcutCatalog?
    var shortcuts: [ShortcutItem] = []
    var sourceDescription = "Not loaded"
    var lastLoadedAt: Date?
    var errorMessage: String?
    var selectedTab: ShortcutTab = .today
    var query = ""
    var selectedContext = "All"
    var selectedSource = "All"
    var selectedPriority = "All"
    var revealedPracticeIDs: Set<String> = []
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

    init(loader: CatalogLoader = CatalogLoader()) {
        self.loader = loader
        self.enableAutoTracking = UserDefaults.standard.bool(forKey: "shortcutCoach.enableAutoTracking")
        practiceSnapshot = DailyPracticeProgress.currentSnapshot(from: storedPracticeData)
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

    var priorities: [String] {
        ["All", "Daily", "Weekly", "Reference"]
    }

    var todayShortcuts: [ShortcutItem] {
        ShortcutFilters.today(shortcuts)
    }

    var filteredShortcuts: [ShortcutItem] {
        ShortcutFilters.filter(
            shortcuts,
            query: query,
            context: selectedContext,
            source: selectedSource,
            priority: selectedPriority
        )
    }

    var practiceShortcuts: [ShortcutItem] {
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
            shortcuts = loaded.catalog.shortcuts.filter {
                $0.source == "Karabiner" || $0.source == "macOS setting"
            }
            sourceDescription = loaded.sourceDescription
            lastLoadedAt = Date()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load shortcuts: \(error.localizedDescription)"
        }
    }

    func isPracticed(_ shortcut: ShortcutItem) -> Bool {
        practiceSnapshot.practicedIDs.contains(shortcut.id)
    }

    func togglePracticed(_ shortcut: ShortcutItem) {
        refreshPracticeSnapshot()
        practiceSnapshot = DailyPracticeProgress.toggled(shortcut.id, in: practiceSnapshot)
        storedPracticeData = DailyPracticeProgress.encoded(practiceSnapshot)
    }

    func togglePracticeAnswer(for shortcut: ShortcutItem) {
        if revealedPracticeIDs.contains(shortcut.id) {
            revealedPracticeIDs.remove(shortcut.id)
        } else {
            revealedPracticeIDs.insert(shortcut.id)
        }
    }

    func isPracticeAnswerRevealed(for shortcut: ShortcutItem) -> Bool {
        revealedPracticeIDs.contains(shortcut.id)
    }

    func openFullGuide() {
        NSWorkspace.shared.open(CatalogLoader.fullGuideURL)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func uniqueValues(_ keyPath: KeyPath<ShortcutItem, String>) -> [String] {
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
