import SwiftUI

struct CopyButton: View {
    let action: () -> Void

    @State private var showCheckmark = false
    @State private var isPressed = false

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
            Image(systemName: showCheckmark ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(showCheckmark ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace.downUp))
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(showCheckmark ? Color.green.opacity(0.1) : Color.primary.opacity(0.06))
                }
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }
}
