import AppKit
import ShortcutCoachCore
import SwiftUI

struct InspectorView: View {
    let shortcut: ShortcutCatalogEntry?
    @Bindable var store: ShortcutStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let shortcut {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header(shortcut)
                    KeyCapRow(keys: shortcut.keys)
                    savedControls(shortcut)

                    inspectorSection("When to use this") {
                        Text(shortcut.guidance)
                    }

                    if let menuPath = shortcut.menuPath {
                        inspectorSection("Menu path") {
                            Text(menuPath.joined(separator: "  ›  "))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }

                    if let output = shortcut.outputSummary {
                        inspectorSection("Output") {
                            Text(output)
                        }
                    }

                    if !shortcut.relatedIDs.isEmpty {
                        inspectorSection("Related shortcuts") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(shortcut.relatedIDs, id: \.self) { id in
                                    if let related = store.shortcut(withID: id) {
                                        Button {
                                            store.select(related)
                                        } label: {
                                            HStack {
                                                Text(related.title)
                                                Spacer()
                                                KeyCapRow(keys: related.keys, compact: true)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Open related shortcut \(related.title), \(related.displayText)")
                                    }
                                }
                            }
                        }
                    }

                    notesSection(shortcut)
                    collectionsSection(shortcut)

                    if let caveat = shortcut.caveat {
                        Label(caveat, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }

                    if let conflictIDs = shortcut.conflictIDs, !conflictIDs.isEmpty {
                        ForEach(conflictIDs, id: \.self) { conflictSummary in
                            Label("Conflict/Interception warning: \(conflictSummary)", systemImage: "exclamationmark.octagon.fill")
                                .font(.callout)
                                .foregroundStyle(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.red, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    verificationSection(shortcut)
                }
                .padding(24)
                .frame(maxWidth: 620, alignment: .leading)
            }
            .navigationTitle(shortcut.title)
            .toolbar { inspectorToolbar(shortcut) }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: shortcut.id)
        } else {
            ContentUnavailableView(
                "Select a Shortcut",
                systemImage: "command",
                description: Text("Choose a result to see guidance, notes, collections, and verification details.")
            )
        }
    }

    private func header(_ shortcut: ShortcutCatalogEntry) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(shortcut.owner ?? shortcut.appName, systemImage: shortcut.owner != nil ? "desktopcomputer" : (SupportedApp.app(withID: shortcut.appID)?.symbolName ?? "macwindow"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(shortcut.title)
                .font(.largeTitle.weight(.semibold))
                .textSelection(.enabled)
            HStack(spacing: 6) {
                Text(shortcut.category)
                ForEach(shortcut.taskTags, id: \.self) { tag in
                    Text(tag)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func savedControls(_ shortcut: ShortcutCatalogEntry) -> some View {
        HStack {
            Toggle(isOn: Binding(
                get: { store.favourites.contains(shortcut.id) },
                set: { _ in store.toggleFavourite(shortcut) }
            )) { Label("Favourite", systemImage: "star") }
                .toggleStyle(.button)
                .keyboardShortcut("f", modifiers: [.command, .shift])

            Toggle(isOn: Binding(
                get: { store.toLearn.contains(shortcut.id) },
                set: { _ in store.toggleToLearn(shortcut) }
            )) { Label("To Learn", systemImage: "graduationcap") }
                .toggleStyle(.button)
                .keyboardShortcut("l", modifiers: [.command, .shift])
        }
    }

    private func notesSection(_ shortcut: ShortcutCatalogEntry) -> some View {
        inspectorSection("Personal note") {
            TextEditor(text: Binding(
                get: { store.note(for: shortcut) },
                set: { store.setNote($0, for: shortcut) }
            ))
            .font(.body)
            .frame(minHeight: 90)
            .padding(6)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Personal note for \(shortcut.title)")
        }
    }

    private func collectionsSection(_ shortcut: ShortcutCatalogEntry) -> some View {
        inspectorSection("Collections") {
            if store.collections.isEmpty {
                Text("Create a collection from the sidebar, then add this shortcut here.")
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 7) {
                    ForEach(store.collections) { collection in
                        Toggle(collection.name, isOn: Binding(
                            get: { store.contains(shortcut, in: collection.id) },
                            set: { _ in store.toggle(shortcut, in: collection.id) }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }
        }
    }

    private func verificationSection(_ shortcut: ShortcutCatalogEntry) -> some View {
        inspectorSection("Verification") {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                metadataRow("Stability", shortcut.stability.rawValue.replacingOccurrences(of: "-", with: " ").capitalized)
                metadataRow("Verified", shortcut.validation.verifiedAt)
                metadataRow("macOS", shortcut.validation.macOSVersion)
                if let version = shortcut.validation.appVersion { metadataRow("App version", version) }
                metadataRow("Method", shortcut.validation.method)
                GridRow {
                    Text("Source").foregroundStyle(.secondary)
                    if let rawURL = shortcut.sourceReference.url, let url = URL(string: rawURL) {
                        Link(shortcut.sourceReference.title, destination: url)
                    } else {
                        Text(shortcut.sourceReference.title)
                    }
                }
            }
            .font(.callout)
            .textSelection(.enabled)
        }
    }

    @ToolbarContentBuilder
    private func inspectorToolbar(_ shortcut: ShortcutCatalogEntry) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(shortcut.displayText, forType: .string)
            } label: {
                Label("Copy Shortcut", systemImage: "doc.on.doc")
            }
            .help("Copy \(shortcut.displayText)")
            .keyboardShortcut("c", modifiers: [.command, .shift])
        }
    }

    private func inspectorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).font(.headline)
            content()
        }
    }

    private func metadataRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(value)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var points: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (CGSize(width: width.isFinite ? width : x, height: y + lineHeight), points)
    }
}
