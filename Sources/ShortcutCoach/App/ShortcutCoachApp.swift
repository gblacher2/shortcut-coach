import AppKit
import SwiftUI

@main
struct ShortcutCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = ShortcutStore.shared

    var body: some Scene {
        MenuBarExtra("Shortcut Coach", systemImage: "command.circle") {
            MenuBarSearchView(store: store)
                .frame(width: 380, height: 520)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandMenu("Library") {
                Button("Open Shortcut Coach") { MainWindowCoordinator.shared.show(store: store) }
                    .keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button("Export Personal State…") { store.exportBackup() }
                    .keyboardShortcut("e", modifiers: [.command, .option])
                Button("Import Personal State…") { store.importBackup() }
                    .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        MainWindowCoordinator.shared.show(store: .shared)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag { MainWindowCoordinator.shared.show(store: .shared) }
        return true
    }
}
