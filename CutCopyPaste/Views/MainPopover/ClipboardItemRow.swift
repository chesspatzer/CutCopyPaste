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

    private var displayText: String {
        if item.isMasked, let text = item.textContent {
            return String(repeating: "*", count: min(text.count, 40))
        }
        return item.preview
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Type badge with sensitive data indicator
            ZStack(alignment: .topTrailing) {
                TypeBadge(type: item.contentType)
                SensitiveDataBadge(types: item.sensitiveDataTypes)
                    .offset(x: 4, y: -4)
            }

            // Content area — takes all available space
            VStack(alignment: .leading, spacing: 3) {
                contentPreview

                // Summary for long text
                if let summary = item.summary, !item.isMasked {
                    Text(summary)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .italic()
                }

                // Metadata row — wraps naturally, limited to 1 line
                metadataRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side: hover actions or pin indicator
            if isHovered {
                hoverActions
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.orange.opacity(0.5))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, displayMode == .compact
                 ? Constants.UI.rowPaddingCompact
                 : Constants.UI.rowPaddingComfortable)
        .background {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .fill(backgroundColor)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1.5)
                    }
                }
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
            onCopy()
        }
        .draggable(TransferableClipboardData(from: item)) {
            HStack(spacing: 6) {
                TypeBadge(type: item.contentType)
                Text(item.preview)
                    .font(.system(size: 11))
                    .lineLimit(1)
                    .frame(maxWidth: 200)
            }
            .padding(6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
        .contextMenu {
            contextMenuItems
        }
    }

    // MARK: - Hover Actions

    private var hoverActions: some View {
        HStack(spacing: 2) {
            if item.textContent != nil || item.contentType == .image {
                ActionsMenu(item: item)
            }

            CopyButton(action: {
                onCopy()
                withAnimation(Constants.Animation.bouncy) {
                    justCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(Constants.Animation.smooth) {
                        justCopied = false
                    }
                }
            })

            PinButton(isPinned: item.isPinned, action: onPin)

            DeleteButton(action: onDelete)
        }
    }

    // MARK: - Metadata Row

    @ViewBuilder
    private var metadataRow: some View {
        let pills = metadataPills
        if !pills.isEmpty {
            HStack(spacing: 3) {
                ForEach(pills.prefix(3), id: \.self) { pill in
                    MetadataPill(text: pill)
                }
                if pills.count > 3 {
                    MetadataPill(text: "+\(pills.count - 3)")
                }
            }
        }
    }

    private var metadataPills: [String] {
        var pills: [String] = []
        if showTimestamps {
            pills.append(item.createdAt.relativeFormatted())
        }
        if showSourceApp, let app = item.sourceAppName {
            pills.append(app)
        }
        // Only show workspace if it's different from the source app name
        if let workspace = item.workspaceName,
           workspace != item.sourceAppName {
            pills.append(workspace)
        }
        if let count = item.characterCount, item.contentType != .image {
            pills.append("\(count) chars")
        }
        if item.ocrText != nil {
            pills.append("OCR")
        }
        return pills
    }

    // MARK: - Background

    private var backgroundColor: Color {
        if justCopied {
            return Color.green.opacity(0.05)
        } else if appState.mergeSelection.contains(item.id) {
            return Color.purple.opacity(0.08)
        } else if isSelected {
            return Color.accentColor.opacity(0.08)
        } else if isHovered {
            return Color.primary.opacity(0.04)
        } else {
            return Color.clear
        }
    }

    // MARK: - Content Preview

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .image:
            HStack(spacing: 6) {
                if let thumbData = item.thumbnailData, let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 180, maxHeight: displayMode == .compact ? 30 : 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        }
                } else {
                    Label("Image", systemImage: "photo")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

        case .file:
            let count = item.filePaths?.count ?? 0
            HStack(spacing: 6) {
                Text("\(count) file\(count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                if let first = item.filePaths?.first {
                    Text(first.components(separatedBy: "/").last ?? first)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

        case .link:
            Text(item.isMasked ? displayText : (item.textContent?.firstLine ?? "Link"))
                .font(.system(size: 12))
                .foregroundColor(item.isMasked ? .secondary : .blue)
                .lineLimit(displayMode == .compact ? 1 : 2)
                .truncationMode(.tail)

        case .text, .richText:
            HStack(spacing: 6) {
                if let text = item.textContent, !item.isMasked {
                    if let color = parseHexColor(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 14, height: 14)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5)
                            }
                    }
                }
                Text(displayText)
                    .font(.system(size: 12))
                    .lineLimit(displayMode == .compact ? 1 : 2)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary.opacity(0.85))
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
            Label(appState.diffSelection.contains(where: { $0.id == item.id }) ? "Deselect for Compare" : "Select for Compare",
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

    private func parseHexColor(_ text: String) -> Color? {
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
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Metadata Pill

struct MetadataPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(0.04))
            }
            .lineLimit(1)
            .fixedSize()
    }
}
