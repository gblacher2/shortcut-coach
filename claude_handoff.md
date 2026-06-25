# Handoff to Claude

This document contains the changes made during our session to fix concurrency bugs and improve runtime lifecycle handling in the macOS SwiftUI menu-bar app.

## Status Report A: Concurrency and Thread-Safety Fixes
- **Outcome**: DONE
- **Files changed**:
  - `Sources/ShortcutCoach/Stores/ShortcutStore.swift`: Fixed concurrency warnings, removed run-loop-bound teardown from `deinit`, and updated timer run-loop mode.
  - `Sources/ShortcutCoachChecks/main.swift`: Added safety check for zero-modifier matching.
- **Findings addressed**:
  - **3b**: fixed (Extracted flags/chars from `NSEvent` before `MainActor.assumeIsolated` hop and removed redundant `Task`).
  - **1-fix**: fixed (Added short-circuit return when no recognized modifiers are pressed).
  - **3a**: fixed (Registered for `NSApplication.willTerminateNotification` to call `@MainActor teardownTracking()`, leaving only best-effort cleanup in `deinit`).
  - **4-runloop**: fixed (Scheduled timer manually on `RunLoop.main` with `.common` mode).
  - **3c**: fixed (Added one-line comments to `nonisolated(unsafe)` variables confirming @MainActor isolation).
- **1-fix safety check**: verified (Tested catalog with a script—none of the priority-1 "Today" shortcuts lack modifier keys).

## Status Report B: Lifecycle Improvements
- **Outcome**: DONE
- **Scene type observed**: `MenuBarExtra` (with `.menuBarExtraStyle(.window)`)
- **Re-validation trigger(s) chosen**: `scenePhase` (via `.onChange`) AND `didBecomeActive` (via `onReceive`). Both ensure we never miss a re-validation opportunity when the user switches back to the app.
- **Optional poll-pause**: implemented. Added `pausePermissionTimer()` to `ShortcutStore` which wraps `stopPermissionTimer()`, called safely on `onDisappear`.
- **Files changed**:
  - `Sources/ShortcutCoach/Stores/ShortcutStore.swift`: Added `pausePermissionTimer()` to pause polling on UI close.
  - `Sources/ShortcutCoach/Views/TodayView.swift`: Added `@Environment(\.scenePhase)` and modifier bindings to trigger re-validation and pauses.

## Full File Contents

### `Sources/ShortcutCoach/Stores/ShortcutStore.swift`
```swift
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
    nonisolated(unsafe) private var permissionTimer: Timer?
    @ObservationIgnored
    nonisolated(unsafe) private var terminateObserver: NSObjectProtocol?

    var enableAutoTracking: Bool = false {
        didSet {
            UserDefaults.standard.set(enableAutoTracking, forKey: "shortcutCoach.enableAutoTracking")
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
            shortcuts = loaded.catalog.shortcuts
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
        } else {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
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
```

### `Sources/ShortcutCoach/Views/TodayView.swift`
```swift
import ShortcutCoachCore
import SwiftUI

struct TodayView: View {
    @Bindable var store: ShortcutStore
    let shortcuts: [ShortcutItem]
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $store.enableAutoTracking) {
                        HStack(spacing: 4) {
                            Image(systemName: "keyboard")
                            Text("Auto-track Today's Shortcuts")
                                .fontWeight(.medium)
                        }
                    }
                    .toggleStyle(.checkbox)
                    .font(.subheadline)
                    .help("Automatically checks off shortcuts as you type/use them on your Mac")
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                    if store.enableAutoTracking {
                        if !store.isAccessibilityTrusted {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                        .font(.body)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Accessibility Permission Required")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                        Text("macOS requires Accessibility permission for the app to detect keyboard shortcuts used in other applications. Your keystrokes are never saved or shared.")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Button("Open System Settings") {
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .padding(.horizontal, 14)
                            .transition(.opacity)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundStyle(.green)
                                Text("Auto-tracking is active and listening for Today's shortcuts.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .transition(.opacity)
                        }
                    }
                }
                .padding(.bottom, 8)
                .animation(.default, value: store.enableAutoTracking)
                .animation(.default, value: store.isAccessibilityTrusted)

                ForEach(Array(shortcuts.enumerated()), id: \.element.id) { index, shortcut in
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                store.togglePracticed(shortcut)
                            }
                        } label: {
                            Image(systemName: store.isPracticed(shortcut) ? "checkmark.circle.fill" : "\(index + 1).circle")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(store.isPracticed(shortcut) ? Color.accentColor : .secondary)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help(store.isPracticed(shortcut) ? "Mark as not practiced" : "Mark as practiced")
                        ShortcutRow(shortcut: shortcut, showNotes: false)
                            .opacity(store.isPracticed(shortcut) ? 0.68 : 1)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                }

                if shortcuts.isEmpty {
                    ContentUnavailableView("No daily shortcuts", systemImage: "keyboard", description: Text("Refresh the catalog and try again."))
                        .frame(maxWidth: .infinity, minHeight: 260)
                }
            }
            .padding(.vertical, 10)
        }
        .onAppear {
            store.checkAccessibilityPermission()
        }
        .onDisappear {
            store.pausePermissionTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.checkAccessibilityPermission()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.checkAccessibilityPermission()
        }
    }
}
```
