import ShortcutCoachCore
import SwiftUI

struct PracticeView: View {
    @Bindable var store: ShortcutStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(store.practiceShortcuts) { shortcut in
                    PracticeCard(
                        shortcut: shortcut,
                        isRevealed: store.isPracticeAnswerRevealed(for: shortcut)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.togglePracticeAnswer(for: shortcut)
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }
            .padding(.vertical, 12)
        }
    }
}

private struct PracticeCard: View {
    let shortcut: ShortcutCatalogEntry
    let isRevealed: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(shortcut.practicePrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(isRevealed ? "Hide answer" : "Reveal answer", action: onToggle)
                .buttonStyle(.bordered)
                .controlSize(.small)
            if isRevealed {
                ShortcutRow(shortcut: shortcut, showNotes: false)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isRevealed)
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
}
