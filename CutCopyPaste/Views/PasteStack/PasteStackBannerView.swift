import SwiftUI

struct PasteStackBannerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)

            Text("\(appState.pasteStackManager.depth) in stack")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Mode toggle
            Button {
                appState.pasteStackManager.toggleMode()
            } label: {
                Text(appState.pasteStackManager.pasteMode.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            // Clear
            Button {
                appState.pasteStackManager.clearStack()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Clear Stack")

            // Deactivate
            Button {
                appState.pasteStackManager.deactivate()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Exit Stack Mode")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }
}
