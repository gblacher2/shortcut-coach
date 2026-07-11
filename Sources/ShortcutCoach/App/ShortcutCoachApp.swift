import AppKit
import SwiftUI

@main
struct ShortcutCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = ShortcutStore()

    var body: some Scene {
        WindowGroup("Shortcut Coach", id: "main") {
            ShortcutCoachRootView(store: store)
                .frame(minWidth: 920, minHeight: 560)
        }
        .defaultSize(width: 1180, height: 720)
        .commands {
            CommandMenu("Library") {
                Button("Export Personal State…") { store.exportBackup() }
                    .keyboardShortcut("e", modifiers: [.command, .option])
                Button("Import Personal State…") { store.importBackup() }
                    .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }

        MenuBarExtra("Shortcut Coach", systemImage: "command.circle") {
            MenuBarSearchView(store: store)
                .frame(width: 380, height: 520)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
