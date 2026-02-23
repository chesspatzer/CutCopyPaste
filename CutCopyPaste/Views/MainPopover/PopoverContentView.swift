import SwiftUI

/// Captures the hosting NSWindow reference on appear.
private struct WindowCapture: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindow(window)
            }
        }
    }
}

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

                // Monitoring status banners
                if !appState.clipboardMonitor.isMonitoring {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 11))
                        Text("Monitoring paused")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Button {
                            withAnimation(Constants.Animation.snappy) {
                                appState.clipboardMonitor.startMonitoring()
                            }
                        } label: {
                            Text("Resume")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if appState.clipboardMonitor.skipNextCapture {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                        Text("Skipping next copy")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Button {
                            withAnimation(Constants.Animation.snappy) {
                                appState.clipboardMonitor.skipNextCapture = false
                            }
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Search (not shown on snippets tab)
                if appState.selectedCategory != .snippets {
                    SearchBarView(text: $appState.searchText, searchMode: $appState.searchMode)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }

                // Active smart collection chip
                if let collection = appState.activeSmartCollection {
                    HStack(spacing: 6) {
                        Image(systemName: collection.systemImage)
                            .font(.system(size: 10, weight: .medium))
                        Text(collection.name)
                            .font(.system(size: 11, weight: .medium))
                        Button {
                            withAnimation(Constants.Animation.snappy) {
                                appState.activeSmartCollection = nil
                                appState.refreshItems()
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                    .transition(.scale.combined(with: .opacity))
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
                        onAutoPaste: { item in appState.copyToClipboard(item, autoPaste: true) },
                        onPastePlain: { item in appState.copyToClipboardPlainText(item, autoPaste: true) },
                        onPin: { item in appState.togglePin(item) },
                        onDelete: { item in appState.deleteItem(item) }
                    )
                    .transition(.opacity)
                }

                // Compare bar — shows when items selected for diff
                if !appState.diffSelection.isEmpty {
                    compareBar
                }

                // Footer
                footer
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .background(WindowCapture { window in
                appState.popoverNSWindow = window
            })

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

            // Onboarding overlay
            if appState.showOnboarding {
                overlayBackdrop { }
                OnboardingView()
                    .environmentObject(appState)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            // Smart Collections overlay
            if appState.showSmartCollections {
                overlayBackdrop {
                    withAnimation(Constants.Animation.snappy) {
                        appState.showSmartCollections = false
                    }
                }
                SmartCollectionsView(
                    onSelect: { collection in
                        withAnimation(Constants.Animation.snappy) {
                            appState.activeSmartCollection = collection
                            appState.showSmartCollections = false
                            appState.refreshItems()
                        }
                    },
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            appState.showSmartCollections = false
                        }
                    }
                )
                .environmentObject(appState)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            // Undo delete toast
            if appState.showUndoToast {
                VStack {
                    Spacer()
                    undoToast
                        .padding(.horizontal, 14)
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .coordinateSpace(name: "popover")
        .animation(Constants.Animation.snappy, value: appState.showDiffView)
        .animation(Constants.Animation.snappy, value: appState.showTransformResult)
        .animation(Constants.Animation.snappy, value: appState.showOnboarding)
        .animation(Constants.Animation.snappy, value: appState.showUndoToast)
        .animation(Constants.Animation.snappy, value: appState.showSmartCollections)
        .animation(Constants.Animation.snappy, value: appState.activeSmartCollection?.id)
        .onAppear {
            appState.unseenCopyCount = 0
        }
        .onDisappear {
            appState.dismissHoverPreview()
        }
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
                .foregroundStyle(.primary)
                .tracking(-0.3)

            Spacer()

            HStack(spacing: 4) {
                // Smart Collections
                Button {
                    withAnimation(Constants.Animation.snappy) {
                        appState.showSmartCollections = true
                    }
                } label: {
                    Image(systemName: "square.stack.3d.up.badge.automatic")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(appState.activeSmartCollection != nil ? Color.accentColor : Color.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Smart Collections")

                // Pause/Resume monitoring
                Button {
                    withAnimation(Constants.Animation.snappy) {
                        if appState.clipboardMonitor.isMonitoring {
                            appState.clipboardMonitor.stopMonitoring()
                        } else {
                            appState.clipboardMonitor.startMonitoring()
                        }
                    }
                } label: {
                    Image(systemName: appState.clipboardMonitor.isMonitoring ? "pause.circle" : "play.circle.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(appState.clipboardMonitor.isMonitoring ? Color.secondary : .orange)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(appState.clipboardMonitor.isMonitoring ? "Pause monitoring" : "Resume monitoring")

                // Settings
                SettingsLink {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Settings")

                // Overflow menu
                Menu {
                    Button {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "analytics")
                    } label: {
                        Label("Analytics", systemImage: "chart.bar")
                    }

                    Divider()

                    Button {
                        withAnimation(Constants.Animation.snappy) {
                            appState.clipboardMonitor.skipNextCapture = true
                        }
                    } label: {
                        Label("Skip Next Copy", systemImage: "forward.end")
                    }
                    .disabled(appState.clipboardMonitor.skipNextCapture)

                    Button {
                        withAnimation(Constants.Animation.snappy) {
                            if appState.clipboardMonitor.isMonitoring {
                                appState.clipboardMonitor.stopMonitoring()
                            } else {
                                appState.clipboardMonitor.startMonitoring()
                            }
                        }
                    } label: {
                        Label(
                            appState.clipboardMonitor.isMonitoring ? "Pause Monitoring" : "Resume Monitoring",
                            systemImage: appState.clipboardMonitor.isMonitoring ? "pause" : "play"
                        )
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
                        .foregroundStyle(.secondary)
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
        .background(Color.blue.opacity(0.08))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Compare bar, \(appState.diffSelection.count) of 2 items selected")
    }

    // MARK: - Undo Toast

    private var undoToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "trash")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text("Item deleted")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary.opacity(0.8))

            Spacer()

            Button {
                withAnimation(Constants.Animation.snappy) {
                    appState.undoDelete()
                }
            } label: {
                Text("Undo")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Item deleted. Tap undo to restore.")
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 4) {
            let count = appState.clipboardItems.count
            Text("\(count) \(count == 1 ? "clip" : "clips")")
                .font(Constants.Typography.footer)
                .foregroundStyle(.tertiary)

            Spacer()

            if appState.diffSelection.count == 1 {
                Text("Select one more to compare")
                    .font(Constants.Typography.footer)
                    .foregroundStyle(.blue.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }
}
