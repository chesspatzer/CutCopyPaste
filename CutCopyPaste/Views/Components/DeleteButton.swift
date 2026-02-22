import SwiftUI

struct DeleteButton: View {
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isHovered ? .red : .secondary)
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(isHovered ? Color.red.opacity(0.1) : Color.primary.opacity(0.06))
                }
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Constants.Animation.quick) {
                isHovered = hovering
            }
        }
        .help("Delete")
        .accessibilityLabel("Delete item")
    }
}
