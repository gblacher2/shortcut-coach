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
                    if shortcut.owner == nil {
                        KeyCapRow(keys: shortcut.keys)
                    } else {
                        localBindingSection(shortcut)
                    }
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
                        ForEach(conflictIDs, id: \.self) { conflictID in
                            if let conflict = store.environmentConflict(withID: conflictID) {
                                conflictWarning(conflict)
                            } else {
                                unresolvedConflictWarning(id: conflictID)
                            }
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

    private func localBindingSection(_ shortcut: ShortcutCatalogEntry) -> some View {
        inspectorSection("Local binding") {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Input").foregroundStyle(.secondary)
                    KeyCapRow(keys: shortcut.keys)
                }

                if let outputKeys = shortcut.outputKeys, !outputKeys.isEmpty {
                    GridRow {
                        Text("Output").foregroundStyle(.secondary)
                        KeyCapRow(keys: outputKeys)
                    }
                }

                if let outputSummary = shortcut.outputSummary {
                    metadataRow("Result", outputSummary)
                }
                if let outputType = shortcut.outputType {
                    metadataRow("Output type", humanized(outputType))
                }
                if let scope = shortcut.environmentScope {
                    metadataRow("Scope", humanized(scope))
                }
                if let defaultStatus = shortcut.defaultStatus {
                    metadataRow("Default status", humanized(defaultStatus))
                }
                if let classification = shortcut.environmentClassification {
                    metadataRow("Library classification", classificationLabel(classification))
                }
            }
            .font(.callout)
            .accessibilityElement(children: .contain)
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
                if let confidence = shortcut.environmentConfidence {
                    metadataRow("Confidence", humanized(confidence))
                } else {
                    metadataRow("Method", shortcut.validation.method)
                }
                metadataRow("Source type", humanized(shortcut.sourceReference.kind.rawValue))
                GridRow {
                    Text("Source").foregroundStyle(.secondary)
                    if let rawURL = shortcut.sourceReference.url,
                       let url = URL(string: rawURL),
                       ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                        Link(shortcut.sourceReference.title, destination: url)
                            .accessibilityHint("Opens the verification source in your browser")
                    } else {
                        Text(shortcut.sourceReference.title)
                    }
                }
            }
            .font(.callout)
            .textSelection(.enabled)
        }
    }

    private func conflictWarning(_ conflict: EnvironmentConflict) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Interception warning", systemImage: "exclamationmark.octagon.fill")
                .font(.callout.bold())
                .foregroundStyle(.red)
            Text(conflict.summary)
                .font(.callout.weight(.medium))
            Text("\(humanized(conflict.severity.rawValue)) severity · \(humanized(conflict.type.rawValue))")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Evidence: \(conflict.evidence)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Safe check: \(conflict.recommendedNonDestructiveTest)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.red.opacity(0.55), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Interception warning. \(conflict.summary). "
            + "\(humanized(conflict.severity.rawValue)) severity. "
            + "Safe check: \(conflict.recommendedNonDestructiveTest)"
        )
    }

    private func unresolvedConflictWarning(id: String) -> some View {
        Label(
            "Interception warning details are unavailable (\(id)).",
            systemImage: "exclamationmark.octagon.fill"
        )
        .font(.callout.bold())
        .foregroundStyle(.red)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityLabel("Interception warning details are unavailable. Reference \(id).")
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
            .accessibilityLabel("Copy Shortcut")
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

    private func humanized(_ value: String) -> String {
        value
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private func classificationLabel(_ value: EnvironmentClassification) -> String {
        switch value {
        case .add: "macOS System"
        case .keepSeparateFromBuiltInCatalog: "Personal Setup"
        case .update: "Catalog Update"
        case .omit: "Omitted"
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
