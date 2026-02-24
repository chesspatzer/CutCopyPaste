import SwiftUI

struct PinButton: View {
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isPinned ? .orange : .secondary)
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(isPinned ? Color.orange.opacity(0.1) : Color.primary.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
        .help(isPinned ? "Unpin" : "Pin to keep")
        .accessibilityLabel(isPinned ? "Unpin item" : "Pin item")
    }
}
