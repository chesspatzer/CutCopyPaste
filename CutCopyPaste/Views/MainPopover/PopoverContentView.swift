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

                // Compare bar — shows when items selected for diff
                if !appState.diffSelection.isEmpty {
                    compareBar
                }

                // Merge floating button
                if appState.isMergeMode && !appState.mergeSelection.isEmpty {
                    mergeBar
                }

                // Footer
                footer
            }
            .background(Color(nsColor: .windowBackgroundColor))

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
            Text("CutCopyPaste")
                .font(Constants.Typography.title)
                .foregroundStyle(.primary.opacity(0.8))
                .tracking(-0.3)

            Spacer()

            HStack(spacing: 4) {
                // Settings
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Settings")

                // Overflow menu
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

                    Button(role: .destructive) {
                        appState.clearAll()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 28)
                .help("More options")
            }
        }
    }

    // MARK: - Compare Bar

    private var compareBar: some View {
        HStack {
            Image(systemName: "arrow.left.arrow.right")
                .font(Constants.Typography.footnote)
                .foregroundStyle(.blue)
            Text("\(appState.diffSelection.count) of 2 selected")
                .font(Constants.Typography.bar)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Clear") {
                withAnimation(Constants.Animation.snappy) {
                    appState.diffSelection.removeAll()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("Compare") {
                appState.showDiffView = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(appState.diffSelection.count < 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
    }

    // MARK: - Merge Bar

    private var mergeBar: some View {
        HStack {
            Text("\(appState.mergeSelection.count) selected")
                .font(Constants.Typography.bar)
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
        HStack(spacing: 4) {
            let count = appState.clipboardItems.count
            Text("\(count) \(count == 1 ? "clip" : "clips")")
                .font(Constants.Typography.footer)
                .foregroundStyle(.quaternary)

            if appState.pasteStackManager.isActive {
                Text("\u{00B7} Stack: \(appState.pasteStackManager.depth)")
                    .font(Constants.Typography.footer)
                    .foregroundStyle(.purple.opacity(0.5))
            }

            Spacer()

            if appState.isMergeMode {
                Text("Select items to merge")
                    .font(Constants.Typography.footer)
                    .foregroundStyle(.purple.opacity(0.5))
            } else if appState.diffSelection.count == 1 {
                Text("Select one more to compare")
                    .font(Constants.Typography.footer)
                    .foregroundStyle(.blue.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }
}
