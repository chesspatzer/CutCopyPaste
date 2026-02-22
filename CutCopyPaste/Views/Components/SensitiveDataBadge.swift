import SwiftUI

struct SensitiveDataBadge: View {
    let types: [String]?

    var isVisible: Bool {
        guard let types else { return false }
        return !types.isEmpty
    }

    var body: some View {
        if isVisible {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.3), radius: 2)
        }
    }
}
