import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var headerHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 6)

            // Search
            SearchBarView(text: $appState.searchText)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

            // Category tabs
            CategoryTabBar(selection: $appState.selectedCategory)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            // Subtle separator
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 14)

            // Content
            if appState.clipboardItems.isEmpty {
                EmptyStateView(category: appState.selectedCategory)
                    .transition(.opacity)
            } else {
                ClipboardListView(
                    items: appState.clipboardItems,
                    displayMode: appState.preferences.displayMode,
                    showTimestamps: appState.preferences.showTimestamps,
                    showSourceApp: appState.preferences.showSourceApp,
                    onCopy: { item in appState.copyToClipboard(item) },
                    onPin: { item in appState.togglePin(item) },
                    onDelete: { item in appState.deleteItem(item) }
                )
                .transition(.opacity)
            }

            // Footer
            footer
        }
        .background {
            ZStack {
                // Base material
                Rectangle().fill(.ultraThinMaterial)

                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.02),
                        Color.clear,
                        Color.primary.opacity(0.01),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .animation(Constants.Animation.smooth, value: appState.clipboardItems.isEmpty)
        .animation(Constants.Animation.snappy, value: appState.selectedCategory)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.7))

                Text("CutCopyPaste")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 2) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .frame(width: 26, height: 26)
                        .background {
                            Circle()
                                .fill(Color.primary.opacity(0.04))
                        }
                }
                .buttonStyle(.plain)
                .help("Settings")

                Menu {
                    Button {
                        appState.clearAll()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 26, height: 26)
                        .background {
                            Circle()
                                .fill(Color.primary.opacity(0.04))
                        }
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 26)
                .help("More options")
            }
        }
    }

    // MARK: - Actions

    private func openSettings() {
        // Activate the app first so the Settings window can come to front
        NSApp.activate(ignoringOtherApps: true)
        // Use the standard macOS selector for opening the Settings scene
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)
                .padding(.horizontal, 14)
        }
        .overlay {
            HStack(spacing: 4) {
                let count = appState.clipboardItems.count
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.quaternary)
                Text(count == 1 ? "clip" : "clips")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.quaternary)

                Spacer()

                Text("Double-click to copy")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}
