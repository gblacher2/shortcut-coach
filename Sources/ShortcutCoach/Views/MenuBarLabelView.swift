import SwiftUI

struct MenuBarLabelView: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: completed == total && total > 0 ? "command.circle.fill" : "command.circle")
                .symbolRenderingMode(.hierarchical)
            Text("\(completed)/\(total)")
                .font(.system(.caption, design: .rounded).monospacedDigit().weight(.semibold))
                .frame(minWidth: 34, alignment: .leading)
        }
        .frame(width: 58, alignment: .leading)
        .accessibilityLabel("Shortcut Coach, \(completed) of \(total) practiced")
    }
}
