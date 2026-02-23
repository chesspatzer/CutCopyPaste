import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "clipboard.fill",
            iconColor: .blue,
            title: "Welcome to CutCopyPaste",
            subtitle: "Your intelligent clipboard manager",
            description: "Everything you copy is saved, searchable, and organized. Never lose a clipboard item again."
        ),
        OnboardingPage(
            icon: "magnifyingglass",
            iconColor: .orange,
            title: "Smart Search",
            subtitle: "Find anything instantly",
            description: "Search by content, type, or source app. Natural language queries like \"links from Safari\" just work."
        ),
        OnboardingPage(
            icon: "keyboard",
            iconColor: .purple,
            title: "Quick Access",
            subtitle: "Always one shortcut away",
            description: "Press \u{21E7}\u{2318}V to toggle the panel from any app. Double-click or press Return to paste instantly."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .green,
            title: "100% Private",
            subtitle: "Everything stays on your Mac",
            description: "No cloud sync, no analytics, no tracking. Your clipboard data never leaves your device."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .frame(height: 320)

            Spacer()

            // Bottom controls
            HStack {
                // Page dots
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.primary.opacity(0.15))
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation(Constants.Animation.snappy) {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                } else {
                    Button("Get Started") {
                        appState.preferences.hasCompletedOnboarding = true
                        withAnimation(Constants.Animation.snappy) {
                            appState.showOnboarding = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 380, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: page.icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(page.iconColor)
            }

            Text(page.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.system(size: 12.5, weight: .regular))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

}

// MARK: - Model

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}
