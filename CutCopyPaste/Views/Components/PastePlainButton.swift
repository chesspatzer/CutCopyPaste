import SwiftUI

struct PastePlainButton: View {
    let action: () -> Void

    @State private var showCheckmark = false
    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button {
            action()
            withAnimation(Constants.Animation.bouncy) {
                showCheckmark = true
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(Constants.Animation.quick) {
                    isPressed = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(Constants.Animation.smooth) {
                    showCheckmark = false
                }
            }
        } label: {
            Image(systemName: showCheckmark ? "checkmark.circle.fill" : "doc.plaintext")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(showCheckmark ? .green : (isHovered ? .teal : .secondary))
                .contentTransition(.symbolEffect(.replace.downUp))
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(showCheckmark ? Color.green.opacity(0.1) : (isHovered ? Color.teal.opacity(0.08) : Color.primary.opacity(0.06)))
                }
                .scaleEffect(isPressed ? 0.85 : (isHovered ? 1.08 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Constants.Animation.quick) {
                isHovered = hovering
            }
        }
        .help("Paste as plain text")
        .accessibilityLabel(showCheckmark ? "Pasted as plain text" : "Paste as plain text")
    }
}
