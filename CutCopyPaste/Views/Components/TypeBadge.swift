import SwiftUI

struct TypeBadge: View {
    let type: ClipboardItemType

    var body: some View {
        Image(systemName: type.systemImage)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(color.opacity(0.15), lineWidth: 0.5)
                    }
            }
    }

    private var color: Color {
        switch type {
        case .text:     return .secondary
        case .richText: return .purple
        case .image:    return .blue
        case .file:     return .orange
        case .link:     return .green
        }
    }
}
