import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let displayMode: DisplayMode
    let showTimestamps: Bool
    let showSourceApp: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var isHovered = false
    @State private var justCopied = false

    // Cached image — computed once and stored in @State
    @State private var cachedImage: NSImage?
    @State private var cachedImageDataHash: Int?

    private var isSelectedForCompare: Bool {
        appState.diffSelection.contains(where: { $0.id == item.id })
    }

    private var displayText: String {
        if item.isMasked, let text = item.textContent {
            return String(repeating: "*", count: min(text.count, 40))
        }
        return item.preview
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top bar: source app + time + pin
            topBar
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // Content preview
            contentPreview
                .padding(.horizontal, 12)

            // Summary for long text
            if let summary = item.summary, !item.isMasked {
                Text(summary)
                    .font(Constants.Typography.summary)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .italic()
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }

            // Bottom bar: type label + char count + hover actions
            bottomBar
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .background {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .fill(cardBackground)
                .shadow(
                    color: .black.opacity(isHovered ? 0.1 : Constants.UI.cardShadowOpacity),
                    radius: isHovered ? 4 : Constants.UI.cardShadowRadius,
                    y: 1
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: borderWidth)
        }
        .overlay {
            if justCopied {
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                    .fill(Color.green.opacity(0.08))
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous))
        .onHover { hovering in
            withAnimation(Constants.Animation.quick) {
                isHovered = hovering
            }
        }
        .animation(Constants.Animation.quick, value: isHovered)
        .onTapGesture(count: 2) {
            performCopy()
        }
        .draggable(TransferableClipboardData(from: item)) {
            HStack(spacing: 6) {
                Image(systemName: item.contentType.systemImage)
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.secondary)
                Text(item.preview)
                    .font(Constants.Typography.caption)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            if item.contentType == .image {
                loadImageIfNeeded()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 6) {
            // Source app icon
            if let bundleID = item.sourceAppBundleID {
                SourceAppIcon(bundleID: bundleID)
            }

            if showSourceApp, let app = item.sourceAppName {
                Text(app)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if showTimestamps {
                Text(item.createdAt.relativeFormatted())
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.tertiary)
            }

            // Pin indicator
            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(Constants.Typography.micro)
                    .foregroundStyle(.orange)
            }

            // Sensitive data badge
            SensitiveDataBadge(types: item.sensitiveDataTypes)
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .image:
            imagePreview

        case .file:
            filePreview

        case .link:
            if item.isMasked {
                Text(displayText)
                    .font(Constants.Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                linkPreview
            }

        case .text, .richText:
            textPreview
        }
    }

    // MARK: - Image Preview

    @ViewBuilder
    private var imagePreview: some View {
        if let nsImage = cachedImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: displayMode == .compact ? 80 : 120)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                }
        } else {
            HStack {
                Spacer()
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(height: 60)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            }
            .onAppear { loadImageIfNeeded() }
        }
    }

    private func loadImageIfNeeded() {
        let dataHash = item.thumbnailData?.hashValue ?? item.imageData?.hashValue ?? 0
        guard cachedImageDataHash != dataHash else { return }
        cachedImageDataHash = dataHash
        if let thumbData = item.thumbnailData, let img = NSImage(data: thumbData) {
            cachedImage = img
        } else if let fullData = item.imageData, let img = NSImage(data: fullData) {
            cachedImage = img
        }
    }

    // MARK: - Link Preview

    private var parsedLink: (urlString: String, domain: String, displayPath: String) {
        let urlString = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let url = URL(string: urlString)
        let host = url?.host ?? urlString
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let path = url?.path ?? ""
        let displayPath = path == "/" ? "" : path
        return (urlString, domain, displayPath)
    }

    @ViewBuilder
    private var linkPreview: some View {
        let link = parsedLink

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Favicon placeholder with domain initial
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 28, height: 28)
                    Text(String(link.domain.prefix(1)).uppercased())
                        .font(Constants.Typography.faviconInitial)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(link.domain)
                        .font(Constants.Typography.linkDomain)
                        .foregroundStyle(.primary.opacity(0.85))
                        .lineLimit(1)

                    if !link.displayPath.isEmpty {
                        Text(link.displayPath)
                            .font(Constants.Typography.linkDetail)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.blue.opacity(0.5))
            }

            // Full URL
            Text(link.urlString)
                .font(Constants.Typography.linkDetail)
                .foregroundStyle(.blue.opacity(0.7))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.blue.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.blue.opacity(0.08), lineWidth: 0.5)
                }
        }
    }

    // MARK: - File Preview

    private var filePreview: some View {
        let count = item.filePaths?.count ?? 0
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(count) file\(count == 1 ? "" : "s")")
                .font(Constants.Typography.fileTitle)
                .foregroundStyle(.primary)
            if let first = item.filePaths?.first {
                Text(first.components(separatedBy: "/").last ?? first)
                    .font(Constants.Typography.linkDetail)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    // MARK: - Text Preview

    private var textPreview: some View {
        HStack(spacing: 6) {
            if let text = item.textContent, !item.isMasked {
                if let color = parseHexColor(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 16, height: 16)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                        }
                }
            }
            Text(displayText)
                .font(Constants.Typography.body)
                .lineLimit(displayMode == .compact ? 2 : 3)
                .truncationMode(.tail)
                .foregroundStyle(.primary.opacity(0.9))
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 6) {
            // Content type + metadata
            HStack(spacing: 4) {
                Image(systemName: item.contentType.systemImage)
                    .font(Constants.Typography.micro)
                Text(item.contentType.displayName)
                    .font(Constants.Typography.footnote)
            }
            .foregroundStyle(.quaternary)

            if let count = item.characterCount, item.contentType != .image {
                Text("\u{00B7}")
                    .foregroundStyle(.quaternary)
                    .font(Constants.Typography.footnote)
                Text("\(count) chars")
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.quaternary)
            }

            if item.ocrText != nil {
                Text("\u{00B7}")
                    .foregroundStyle(.quaternary)
                    .font(Constants.Typography.footnote)
                Text("OCR")
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.quaternary)
            }

            Spacer()

            // Hover actions
            if isHovered {
                HStack(spacing: 2) {
                    Button {
                        appState.toggleDiffSelection(item)
                    } label: {
                        Image(systemName: isSelectedForCompare ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(isSelectedForCompare ? .blue : .secondary)
                            .frame(width: 24, height: 24)
                            .background {
                                Circle()
                                    .fill(isSelectedForCompare ? Color.blue.opacity(0.1) : Color.primary.opacity(0.06))
                            }
                    }
                    .buttonStyle(.plain)
                    .help(isSelectedForCompare ? "Deselect for Compare" : "Compare")

                    if item.textContent != nil || item.contentType == .image {
                        ActionsMenu(item: item)
                    }

                    PinButton(isPinned: item.isPinned, action: onPin)

                    DeleteButton(action: onDelete)

                    CopyButton(action: { performCopy() })
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Card Styling

    private var cardBackground: Color {
        if justCopied {
            return Color.green.opacity(0.04)
        } else if isSelectedForCompare {
            return Color.blue.opacity(0.04)
        } else if appState.mergeSelection.contains(item.id) {
            return Color.purple.opacity(0.05)
        } else if isSelected {
            return Color.accentColor.opacity(0.06)
        } else {
            return Color(nsColor: .controlBackgroundColor)
        }
    }

    private var cardBorder: Color {
        if isSelectedForCompare {
            return Color.blue.opacity(0.3)
        } else if appState.mergeSelection.contains(item.id) {
            return Color.purple.opacity(0.3)
        } else if isSelected {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.primary.opacity(isHovered ? 0.08 : 0.04)
        }
    }

    private var borderWidth: CGFloat {
        (isSelectedForCompare || appState.mergeSelection.contains(item.id) || isSelected) ? 1.5 : 0.5
    }

    // MARK: - Actions

    private func performCopy() {
        onCopy()
        withAnimation(Constants.Animation.bouncy) {
            justCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(Constants.Animation.smooth) {
                justCopied = false
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button { onCopy() } label: { Label("Copy", systemImage: "doc.on.doc") }
        Button { onPin() } label: { Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") }

        Divider()

        Button {
            withAnimation(Constants.Animation.snappy) {
                appState.detailItem = item
            }
        } label: { Label("Details", systemImage: "info.circle") }

        if item.ocrText != nil {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    appState.ocrResultItem = item
                }
            } label: { Label("View OCR Text", systemImage: "text.viewfinder") }
        }

        if item.contentType == .image && item.ocrText == nil {
            Button { appState.extractTextFromImage(item) } label: { Label("Extract Text (OCR)", systemImage: "text.viewfinder") }
        }

        Divider()

        Button { appState.toggleDiffSelection(item) } label: {
            Label(isSelectedForCompare ? "Deselect for Compare" : "Select for Compare",
                  systemImage: "arrow.left.arrow.right")
        }

        if appState.isMergeMode {
            Button { appState.toggleMergeSelection(item) } label: {
                Label(appState.mergeSelection.contains(item.id) ? "Deselect for Merge" : "Select for Merge",
                      systemImage: "arrow.triangle.merge")
            }
        }

        Divider()

        Button(role: .destructive) { onDelete() } label: { Label("Delete", systemImage: "trash") }
    }

    // MARK: - Color Parsing

    private static var hexColorCache: [String: Color] = [:]

    private func parseHexColor(_ text: String) -> Color? {
        if let cached = Self.hexColorCache[text] {
            return cached
        }
        guard text.hasPrefix("#") else { return nil }
        var hex = String(text.dropFirst())
        guard hex.count == 3 || hex.count == 6 else { return nil }
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        let color = Color(red: r, green: g, blue: b)
        Self.hexColorCache[text] = color
        return color
    }
}

// MARK: - Source App Icon

private struct SourceAppIcon: View {
    let bundleID: String

    // Static cache shared across all instances — NSWorkspace lookups are expensive
    private static var iconCache: [String: NSImage] = [:]
    private static var failedLookups: Set<String> = []

    var body: some View {
        if let icon = cachedIcon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
    }

    private var cachedIcon: NSImage? {
        if let cached = Self.iconCache[bundleID] {
            return cached
        }
        if Self.failedLookups.contains(bundleID) {
            return nil
        }
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleID) else {
            Self.failedLookups.insert(bundleID)
            return nil
        }
        let icon = workspace.icon(forFile: url.path)
        Self.iconCache[bundleID] = icon
        return icon
    }
}
