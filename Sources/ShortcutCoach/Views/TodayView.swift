import ShortcutCoachCore
import SwiftUI

struct TodayView: View {
    @Bindable var store: ShortcutStore
    let shortcuts: [ShortcutCatalogEntry]

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
                                    store.requestAccessibilityPermission()
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.checkAccessibilityPermission()
        }
    }
}
