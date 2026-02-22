import SwiftUI

struct PinButton: View {
    let isPinned: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(Constants.Animation.bouncy) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(Constants.Animation.quick) {
                    isPressed = false
                }
            }
            action()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isPinned ? .orange : .secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(isPinned ? Color.orange.opacity(0.1) : Color.primary.opacity(0.06))
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)
                .rotationEffect(.degrees(isPinned ? 0 : -20))
        }
        .buttonStyle(.plain)
        .help(isPinned ? "Unpin" : "Pin to keep")
        .accessibilityLabel(isPinned ? "Unpin item" : "Pin item")
        .animation(Constants.Animation.bouncy, value: isPinned)
    }
}
