import SwiftUI

struct SearchView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search shortcut or action", text: $store.query)
                        .textFieldStyle(.plain)

                    if !store.query.isEmpty {
                        Button {
                            store.query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Clear search")
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(8)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Picker("Context", selection: $store.selectedContext) {
                            ForEach(store.contexts, id: \.self) { value in
                                Text(value).tag(value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.small)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.circle")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Picker("Source", selection: $store.selectedSource) {
                            ForEach(store.sources, id: \.self) { value in
                                Text(value).tag(value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.small)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Picker("Priority", selection: $store.selectedPriority) {
                            ForEach(store.priorities, id: \.self) { value in
                                Text(value).tag(value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .controlSize(.small)
                    }

                    Spacer()
                    
                    Text("\(store.filteredShortcuts.count) results")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()

            ScrollView {
                if store.filteredShortcuts.isEmpty {
                    ContentUnavailableView(
                        "No results found",
                        systemImage: "magnifyingglass",
                        description: Text("Try adjusting your search or filters.")
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(store.filteredShortcuts) { shortcut in
                            ShortcutRow(shortcut: shortcut, showNotes: true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

