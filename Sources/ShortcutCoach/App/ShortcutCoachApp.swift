import AppKit
import SwiftUI

@main
struct ShortcutCoachApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = ShortcutStore()

    var body: some Scene {
        MenuBarExtra {
            ShortcutCoachRootView(store: store)
                .frame(width: 430, height: 560)
        } label: {
            Image(systemName: "command")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
