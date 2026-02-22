import SwiftUI

struct SensitiveDataBadge: View {
    let types: [String]?

    var isVisible: Bool {
        guard let types else { return false }
        return !types.isEmpty
    }

    private var tooltipText: String {
        guard let types, !types.isEmpty else { return "" }
        return "Sensitive: " + types.joined(separator: ", ")
    }

    var body: some View {
        if isVisible {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 2)
                .help(tooltipText)
        }
    }
}
