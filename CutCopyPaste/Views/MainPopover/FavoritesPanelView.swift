import SwiftUI

struct FavoritesPanelView: View {
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState
    @State private var pinnedItems: [ClipboardItem] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
                Text("Favorites")
                    .font(.system(size: 13, weight: .semibold))

                Text("\(pinnedItems.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))

                Spacer()

                if !pinnedItems.isEmpty {
                    Button {
                        unpinAll()
                    } label: {
                        Text("Unpin All")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }

                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            if pinnedItems.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "pin.slash")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No pinned items")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Pin items from the clipboard list to keep them here")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(pinnedItems) { item in
                            FavoritesItemRow(item: item) {
                                appState.copyToClipboard(item)
                            } onAutoPaste: {
                                appState.copyToClipboard(item, autoPaste: true)
                            } onUnpin: {
                                appState.togglePin(item)
                                loadPinnedItems()
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            loadPinnedItems()
        }
    }

    private func loadPinnedItems() {
        pinnedItems = appState.clipboardItems
            .filter { $0.isPinned }
            .sorted { $0.pinnedOrder < $1.pinnedOrder }
    }

    private func unpinAll() {
        for item in pinnedItems {
            appState.togglePin(item)
        }
        loadPinnedItems()
    }
}

private struct FavoritesItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onAutoPaste: () -> Void
    let onUnpin: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Content type icon
            Image(systemName: item.contentType.systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.primary.opacity(0.04)))

            // Content preview
            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(2)
                    .foregroundStyle(.primary.opacity(0.9))

                HStack(spacing: 4) {
                    if let app = item.sourceAppName {
                        Text(app)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    if let lang = item.detectedLanguage {
                        Text(SyntaxHighlighter.displayName(for: lang))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(.blue.opacity(0.6))
                    }
                }
            }

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Copy")

                    Button(action: onUnpin) {
                        Image(systemName: "pin.slash.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.orange.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .help("Unpin")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) { isHovered = hovering }
        }
        .onTapGesture(count: 2) {
            onAutoPaste()
        }
    }
}
