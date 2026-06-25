import ShortcutCoachCore
import SwiftUI

struct ShortcutCoachRootView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(store: store)

            Divider()

            SearchView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            FooterView(store: store)
        }
        .task {
            if store.shortcuts.isEmpty {
                store.refresh()
            }
        }
    }
}

private struct HeaderView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("app_logo", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Shortcut Coach")
                    .font(.headline)
                Text("Search keyboard shortcuts across macOS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh shortcuts")
        }
        .padding(14)
    }
}

private struct FooterView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        HStack(spacing: 8) {
            Text(compactMeta)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            Button("Full Guide") {
                store.openFullGuide()
            }
            .controlSize(.small)
            .help("Open the interactive HTML guide")
            Button("Quit") {
                store.quit()
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var compactMeta: String {
        guard let catalog = store.catalog else {
            return store.sourceDescription
        }
        let count = catalog.shortcuts.count
        let timePart: String
        if let loadedAt = store.lastLoadedAt {
            timePart = DateFormatter.localizedString(from: loadedAt, dateStyle: .none, timeStyle: .short)
        } else {
            timePart = "–"
        }
        return "\(count) shortcuts · \(timePart)"
    }
}
