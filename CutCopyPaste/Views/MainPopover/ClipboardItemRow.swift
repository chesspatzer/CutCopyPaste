import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let displayMode: DisplayMode
    let showTimestamps: Bool
    let showSourceApp: Bool
    let isSelected: Bool
    let onCopy: () -> Void
    let onAutoPaste: () -> Void
    let onPastePlain: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var appState: AppState

    // Cached image — computed once from thumbnailData on first appear
    @State private var cachedImage: NSImage?
    // Cached timestamp — computed once on appear, not per-frame
    @State private var cachedTimestamp: String = ""
    // Cached accessibility label — computed once on appear
    @State private var cachedAccessibility: String = ""

    private var isSelectedForCompare: Bool {
        appState.diffSelection.contains(where: { $0.id == item.id })
    }

    private var displayText: String {
        if item.isMasked {
            return String(repeating: "*", count: min(item.characterCount ?? 0, 40))
        }
        return item.preview
    }

    private var isCompact: Bool { displayMode == .compact }

    var body: some View {
        cardContent
            .onHover { hovering in
                if hovering {
                    appState.requestHoverPreview(for: item, cardFrame: .zero)
                } else {
                    appState.cancelHoverPreview(fromCard: true)
                }
            }
            .onTapGesture(count: 2) {
                onAutoPaste()
            }
            .draggable(TransferableClipboardData(from: item))
            .contextMenu {
                contextMenuItems
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(cachedAccessibility)
            .accessibilityHint("Double-click to paste. Right-click for more options.")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .onAppear {
                if item.contentType == .image {
                    loadImageIfNeeded()
                }
                if showTimestamps {
                    cachedTimestamp = item.createdAt.relativeFormatted()
                }
                cachedAccessibility = computeAccessibility()
            }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
                .padding(.horizontal, isCompact ? 8 : 12)
                .padding(.top, isCompact ? 6 : 10)
                .padding(.bottom, isCompact ? 3 : 6)

            contentPreview
                .padding(.horizontal, isCompact ? 8 : 12)

            if !isCompact, let summary = item.summary, !item.isMasked {
                Text(summary)
                    .font(Constants.Typography.summary)
                    .foregroundStyle(.secondary.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .italic()
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }

            bottomBar
                .padding(.horizontal, isCompact ? 8 : 12)
                .padding(.top, isCompact ? 3 : 8)
                .padding(.bottom, isCompact ? 6 : 10)
        }
        .background {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .fill(cardBackground)
                .shadow(
                    color: .black.opacity(Constants.UI.cardShadowOpacity),
                    radius: Constants.UI.cardShadowRadius,
                    y: 1
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .strokeBorder(cardBorder, lineWidth: borderWidth)
        }
        .contentShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous))
    }

    private func computeAccessibility() -> String {
        var parts: [String] = []
        parts.append(item.contentType.displayName)
        if item.isPinned { parts.append("pinned") }
        if let app = item.sourceAppName { parts.append("from \(app)") }
        switch item.contentType {
        case .text, .link, .richText:
            parts.append(String(item.preview.prefix(100)))
        case .image:
            if let ocrText = item.ocrText { parts.append("OCR: \(String(ocrText.prefix(60)))") }
        case .file:
            let count = item.filePaths?.count ?? 0
            parts.append("\(count) file\(count == 1 ? "" : "s")")
        }
        if item.isMasked { parts.append("masked") }
        if item.sensitiveDataTypes != nil { parts.append("contains sensitive data") }
        return parts.joined(separator: ", ")
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

            // Language badge
            if let lang = item.detectedLanguage {
                Text(SyntaxHighlighter.displayName(for: lang))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.blue.opacity(0.9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.14)))
            } else if item.isMarkdown {
                Text("Markdown")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.purple.opacity(0.9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.purple.opacity(0.14)))
            }

            if showTimestamps {
                Text(cachedTimestamp)
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.secondary)
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
                .frame(maxWidth: .infinity, maxHeight: isCompact ? 60 : 120)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                }
        } else {
            HStack {
                Spacer()
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(height: 60)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            }
            .onAppear { loadImageIfNeeded() }
        }
    }

    private func loadImageIfNeeded() {
        guard cachedImage == nil else { return }
        if let thumbData = item.thumbnailData, let img = NSImage(data: thumbData) {
            cachedImage = img
        }
    }

    // MARK: - Link Preview

    @State private var cachedLink: (urlString: String, domain: String, displayPath: String)?

    private func computeLink() -> (urlString: String, domain: String, displayPath: String) {
        if let cached = cachedLink { return cached }
        let urlString = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let url = URL(string: urlString)
        let host = url?.host ?? urlString
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        let path = url?.path ?? ""
        let displayPath = path == "/" ? "" : path
        let result = (urlString, domain, displayPath)
        cachedLink = result
        return result
    }

    @ViewBuilder
    private var linkPreview: some View {
        let link = computeLink()

        if isCompact {
            HStack(spacing: 6) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.blue.opacity(0.8))
                Text(link.domain)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)
                if !link.displayPath.isEmpty {
                    Text(link.displayPath)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
            }
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.blue.opacity(0.06))
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
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
                            .foregroundStyle(.primary.opacity(0.9))
                            .lineLimit(1)

                        if !link.displayPath.isEmpty {
                            Text(link.displayPath)
                                .font(Constants.Typography.linkDetail)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(Constants.Typography.footnote)
                        .foregroundStyle(.blue.opacity(0.7))
                }

                Text(link.urlString)
                    .font(Constants.Typography.linkDetail)
                    .foregroundStyle(.blue.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.blue.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.15), lineWidth: 0.5)
                    }
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
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    // MARK: - Text Preview

    private static func truncateForPreview(_ text: String, maxLen: Int = 500) -> String {
        if text.count <= maxLen { return text }
        return String(text.prefix(maxLen))
    }

    private var textPreview: some View {
        let text = item.textContent
        let masked = item.isMasked

        return VStack(alignment: .leading, spacing: 0) {
            if let lang = item.detectedLanguage, let text, !masked {
                CodePreviewView(
                    text: Self.truncateForPreview(text),
                    language: lang,
                    lineLimit: isCompact ? 3 : 6,
                    isCompact: isCompact
                )
            } else if item.isMarkdown, let text, !masked {
                MarkdownPreviewView(
                    text: Self.truncateForPreview(text, maxLen: 800),
                    lineLimit: isCompact ? 6 : 12,
                    isCompact: isCompact
                )
            } else {
                HStack(spacing: 6) {
                    if let text, !masked {
                        if text.count < 10 {
                            if let color = parseHexColor(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(width: isCompact ? 14 : 16, height: isCompact ? 14 : 16)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.5)
                                    }
                            }
                        }
                    }
                    Text(displayText)
                        .font(isCompact ? .system(size: 12, weight: .regular) : Constants.Typography.body)
                        .lineLimit(isCompact ? 2 : 4)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary.opacity(0.9))
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 6) {
            if !isCompact {
                HStack(spacing: 4) {
                    Image(systemName: item.contentType.systemImage)
                        .font(Constants.Typography.micro)
                    Text(item.contentType.displayName)
                        .font(Constants.Typography.footnote)
                }
                .foregroundStyle(.tertiary)

                if let count = item.characterCount, item.contentType != .image {
                    Text("\u{00B7}")
                        .foregroundStyle(.tertiary)
                        .font(Constants.Typography.footnote)
                    Text("\(count) chars")
                        .font(Constants.Typography.footnote)
                        .foregroundStyle(.tertiary)
                }
            }

            if item.ocrText != nil {
                if !isCompact {
                    Text("\u{00B7}")
                        .foregroundStyle(.tertiary)
                        .font(Constants.Typography.footnote)
                }
                Button {
                    appState.ocrResultItem = item
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 9))
                        Text("OCR")
                            .font(Constants.Typography.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 2) {
                Button {
                    appState.toggleDiffSelection(item)
                } label: {
                    Image(systemName: isSelectedForCompare ? "arrow.left.arrow.right.circle.fill" : "arrow.left.arrow.right")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(isSelectedForCompare ? .blue : .secondary)
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

                if item.contentType == .richText {
                    PastePlainButton(action: { onPastePlain() })
                }

                CopyButton(action: { onCopy() })
            }
        }
    }

    // MARK: - Card Styling

    private var cardBackground: Color {
        if isSelectedForCompare {
            return Color.blue.opacity(0.04)
        } else if isSelected {
            return Color.accentColor.opacity(0.06)
        } else {
            return Color(nsColor: .controlBackgroundColor)
        }
    }

    private var cardBorder: Color {
        if isSelectedForCompare {
            return Color.blue.opacity(0.4)
        } else if isSelected {
            return Color.accentColor.opacity(0.4)
        } else {
            return Color.primary.opacity(0.08)
        }
    }

    private var borderWidth: CGFloat {
        (isSelectedForCompare || isSelected) ? 1.5 : 0.5
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button { onCopy() } label: { Label("Copy", systemImage: "doc.on.doc") }
        if item.contentType == .richText {
            Button { onPastePlain() } label: { Label("Paste as Plain Text", systemImage: "doc.plaintext") }
        }
        Button { onPin() } label: { Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") }

        Divider()

        Button {
            appState.detailItem = item
        } label: { Label("Details", systemImage: "info.circle") }

        if item.ocrText != nil {
            Button {
                appState.ocrResultItem = item
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

        Button {
            ShareService.shared.exportToFile(item)
        } label: {
            Label("Export to File...", systemImage: "square.and.arrow.up")
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
        if Self.hexColorCache.count > 200 { Self.hexColorCache.removeAll(keepingCapacity: false) }
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
        if let icon = Self.iconCache[bundleID] {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 14, height: 14)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else if !Self.failedLookups.contains(bundleID) {
            Color.clear
                .frame(width: 14, height: 14)
                .onAppear { Self.loadIcon(for: bundleID) }
        }
    }

    private static func loadIcon(for bundleID: String) {
        guard iconCache[bundleID] == nil, !failedLookups.contains(bundleID) else { return }
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleID) else {
            failedLookups.insert(bundleID)
            return
        }
        let icon = workspace.icon(forFile: url.path)
        iconCache[bundleID] = icon
    }
}
