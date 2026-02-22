import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var headerHovered = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                // Paste Stack Banner
                if appState.pasteStackManager.isActive {
                    PasteStackBannerView()
                }

                // Search (not shown on snippets tab)
                if appState.selectedCategory != .snippets {
                    SearchBarView(text: $appState.searchText)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

                // Category tabs
                CategoryTabBar(selection: $appState.selectedCategory)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                // Workspace filter
                if appState.selectedCategory != .snippets {
                    WorkspaceFilterView()
                }

                // Subtle separator
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.horizontal, 14)

                // Content
                if appState.selectedCategory == .snippets {
                    SnippetListView()
                        .transition(.opacity)
                } else if appState.clipboardItems.isEmpty {
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

                // Merge floating button
                if appState.isMergeMode && !appState.mergeSelection.isEmpty {
                    mergeBar
                }

                // Footer
                footer
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .animation(Constants.Animation.smooth, value: appState.clipboardItems.isEmpty)
            .animation(Constants.Animation.snappy, value: appState.selectedCategory)

            // Overlay modals (replaces .sheet() to avoid MenuBarExtra dismiss bug)
            if appState.showDiffView {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.showDiffView = false
                    }
                }
                if appState.diffSelection.count == 2 {
                    DiffView(
                        leftItem: appState.diffSelection[0],
                        rightItem: appState.diffSelection[1],
                        onDismiss: {
                            withAnimation(Constants.Animation.snappy) {
                                appState.showDiffView = false
                            }
                        }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                }
            }

            if appState.showMergeView {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.showMergeView = false
                    }
                }
                MergeView(
                    items: appState.mergeSelectedItems,
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            appState.showMergeView = false
                        }
                    }
                )
                .environmentObject(appState)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            if appState.showTransformResult, let result = appState.transformResult {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.showTransformResult = false
                    }
                }
                TransformResultView(
                    result: result,
                    onCopy: {
                        appState.copyText(result)
                    },
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            appState.showTransformResult = false
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            if let detailItem = appState.detailItem {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.detailItem = nil
                    }
                }
                ItemDetailView(
                    item: detailItem,
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            appState.detailItem = nil
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            if let ocrItem = appState.ocrResultItem, let ocrText = ocrItem.ocrText {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.ocrResultItem = nil
                    }
                }
                OCRResultView(
                    text: ocrText,
                    onCopy: {
                        appState.copyText(ocrText)
                    },
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            appState.ocrResultItem = nil
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(Constants.Animation.snappy, value: appState.showDiffView)
        .animation(Constants.Animation.snappy, value: appState.showMergeView)
        .animation(Constants.Animation.snappy, value: appState.showTransformResult)
        .animation(Constants.Animation.snappy, value: appState.detailItem?.id)
        .animation(Constants.Animation.snappy, value: appState.ocrResultItem?.id)
    }

    // MARK: - Overlay Backdrop

    private func overlayBackdrop(onTap: @escaping () -> Void) -> some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .onTapGesture(perform: onTap)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: appState.pasteStackManager.isActive ? "clipboard.fill" : "clipboard.fill")
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
                        appState.pasteStackManager.isActive
                        ? appState.pasteStackManager.deactivate()
                        : appState.pasteStackManager.activate()
                    } label: {
                        Label(appState.pasteStackManager.isActive ? "Exit Paste Stack" : "Paste Stack Mode",
                              systemImage: "square.stack.3d.up")
                    }

                    Button {
                        appState.isMergeMode.toggle()
                        if !appState.isMergeMode {
                            appState.clearMergeSelection()
                        }
                    } label: {
                        Label(appState.isMergeMode ? "Exit Merge Mode" : "Merge Clips",
                              systemImage: "arrow.triangle.merge")
                    }

                    Divider()

                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "analytics")
                    } label: {
                        Label("Analytics", systemImage: "chart.bar")
                    }

                    Divider()

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

    // MARK: - Merge Bar

    private var mergeBar: some View {
        HStack {
            Text("\(appState.mergeSelection.count) selected")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancel") {
                appState.clearMergeSelection()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("Merge") {
                appState.showMergeView = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(appState.mergeSelection.count < 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.05))
    }

    // MARK: - Actions

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            HStack(spacing: 4) {
                let count = appState.clipboardItems.count
                Text("\(count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.quaternary)
                Text(count == 1 ? "clip" : "clips")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.quaternary)

                if appState.pasteStackManager.isActive {
                    Text("| Stack: \(appState.pasteStackManager.depth)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.purple.opacity(0.5))
                }

                Spacer()

                if appState.isMergeMode {
                    Text("Select items to merge")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.purple.opacity(0.5))
                } else if appState.diffSelection.count == 1 {
                    Text("Select one more to compare")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.blue.opacity(0.5))
                } else {
                    Text("\u{2318} double-click to copy")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }
}
