import AppKit
import SwiftUI

@MainActor
final class MainWindowCoordinator {
    static let shared = MainWindowCoordinator()

    private var windowController: NSWindowController?

    private init() {}

    func show(store: ShortcutStore) {
        let controller: NSWindowController
        if let windowController {
            controller = windowController
        } else {
            let rootView = ShortcutCoachRootView(store: store)
                .frame(minWidth: 920, minHeight: 560)
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1180, height: 720),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "Shortcut Coach"
            window.minSize = NSSize(width: 920, height: 560)
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.tabbingMode = .disallowed

            let newController = NSWindowController(window: window)
            windowController = newController
            controller = newController

            if !window.setFrameUsingName("ShortcutCoach.MainWindow") {
                window.center()
            }
            window.setFrameAutosaveName("ShortcutCoach.MainWindow")
        }

        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
