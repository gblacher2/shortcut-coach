import ShortcutCoachCore
import SwiftUI

struct ShortcutRow: View {
    let shortcut: ShortcutItem
    let showNotes: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ShortcutChordView(shortcut: shortcut.shortcut)
                Spacer(minLength: 8)
                Text(shortcut.priorityLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(priorityColor)
            }
            Text(shortcut.action)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            HStack(spacing: 6) {
                Text(shortcut.context)
                Text("·")
                Text(shortcut.source)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if showNotes, !shortcut.notes.isEmpty {
                Text(shortcut.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .opacity(shortcut.active ? 1 : 0.55)
    }

    private var priorityColor: Color {
        switch shortcut.priority {
        case 1:
            .green
        case 2:
            .blue
        default:
            .orange
        }
    }
}

struct ShortcutChordView: View {
    let shortcut: String

    var body: some View {
        HStack(spacing: 3) {
            ForEach(parts, id: \.self) { part in
                Text(part)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(.separator.opacity(0.65), lineWidth: 0.5)
                    )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var parts: [String] {
        shortcut.components(separatedBy: " + ")
    }
}
