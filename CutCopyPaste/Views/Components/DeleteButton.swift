import SwiftUI

struct DeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
        .help("Delete")
        .accessibilityLabel("Delete item")
    }
}
