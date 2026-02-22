import SwiftUI

struct EmptyStateView: View {
    let category: CategoryFilter

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [iconColor.opacity(0.1), iconColor.opacity(0.02)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(appeared ? 1.0 : 0.5)

                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(iconColor.opacity(0.5))
                    .scaleEffect(appeared ? 1.0 : 0.3)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(Constants.Animation.smooth.delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }

    private var iconName: String {
        switch category {
        case .all:      return "clipboard"
        case .text:     return "doc.text"
        case .images:   return "photo.on.rectangle"
        case .links:    return "link.circle"
        case .pinned:   return "pin.circle"
        case .snippets: return "text.badge.plus"
        }
    }

    private var iconColor: Color {
        switch category {
        case .all:      return .accentColor
        case .text:     return .secondary
        case .images:   return .blue
        case .links:    return .green
        case .pinned:   return .orange
        case .snippets: return .purple
        }
    }

    private var title: String {
        switch category {
        case .all:      return "No clips yet"
        case .text:     return "No text clips"
        case .images:   return "No images"
        case .links:    return "No links"
        case .pinned:   return "Nothing pinned"
        case .snippets: return "No snippets"
        }
    }

    private var subtitle: String {
        switch category {
        case .all:      return "Copy something to get started.\nYour history will appear here."
        case .text:     return "Text you copy will show up here."
        case .images:   return "Images you copy will show up here."
        case .links:    return "URLs you copy will show up here."
        case .pinned:   return "Pin important clips to keep\nthem at your fingertips."
        case .snippets: return "Create reusable text snippets\nwith templates."
        }
    }
}
