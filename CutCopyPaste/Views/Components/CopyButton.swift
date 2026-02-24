import SwiftUI

struct CopyButton: View {
    let action: () -> Void

    @State private var showCheckmark = false

    var body: some View {
        Button {
            action()
            showCheckmark = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showCheckmark = false
            }
        } label: {
            Image(systemName: showCheckmark ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(showCheckmark ? .green : .secondary)
                .frame(width: 26, height: 26)
                .background {
                    Circle()
                        .fill(showCheckmark ? Color.green.opacity(0.1) : Color.primary.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
        .accessibilityLabel(showCheckmark ? "Copied" : "Copy to clipboard")
    }
}
