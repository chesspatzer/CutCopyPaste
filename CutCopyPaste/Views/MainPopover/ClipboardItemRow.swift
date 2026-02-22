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

    @State private var isHovered = false
    @State private var justCopied = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            TypeBadge(type: item.contentType)

            VStack(alignment: .leading, spacing: 4) {
                contentPreview

                HStack(spacing: 4) {
                    if showTimestamps {
                        MetadataPill(text: item.createdAt.relativeFormatted())
                    }
                    if showSourceApp, let app = item.sourceAppName {
                        MetadataPill(text: app)
                    }
                    if let count = item.characterCount, item.contentType != .image {
                        MetadataPill(text: "\(count) chars")
                    }
                }
            }

            Spacer(minLength: 4)

            ZStack {
                if isHovered {
                    HStack(spacing: 3) {
                        PinButton(isPinned: item.isPinned, action: onPin)
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
                        DeleteButton(action: onDelete)
                    }
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
            .animation(Constants.Animation.quick, value: isHovered)
        }
        .padding(.horizontal, 12)
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
        .onTapGesture(count: 2) {
            onCopy()
        }
    }

    private var backgroundColor: Color {
        if justCopied {
            return Color.green.opacity(0.05)
        } else if isSelected {
            return Color.accentColor.opacity(0.08)
        } else if isHovered {
            return Color.primary.opacity(0.04)
        } else {
            return Color.clear
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .image:
            if let thumbData = item.thumbnailData, let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 180, maxHeight: displayMode == .compact ? 32 : 44)
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
                }
            }

        case .link:
            Text(item.textContent?.firstLine ?? "Link")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
                .lineLimit(displayMode == .compact ? 1 : 2)

        case .text, .richText:
            Text(item.preview)
                .font(.system(size: 12))
                .lineLimit(displayMode == .compact ? 1 : 2)
                .foregroundStyle(.primary.opacity(0.85))
        }
    }
}

// MARK: - Metadata Pill

private struct MetadataPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(0.04))
            }
    }
}
