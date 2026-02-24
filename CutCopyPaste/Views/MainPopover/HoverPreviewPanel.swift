import SwiftUI

struct HoverPreviewPanel: View {
    let item: ClipboardItem
    let cardFrame: CGRect
    let popoverHeight: CGFloat
    let onHoverChange: (Bool) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var loadedImage: NSImage?
    @State private var renderedAttr: AttributedString?
    @State private var renderKey: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            previewContent
                .padding(12)
        }
        .frame(width: Constants.HoverPreview.panelWidth)
        .fixedSize(horizontal: true, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }
        .onHover { hovering in
            onHoverChange(hovering)
        }
        .onAppear {
            if item.contentType == .image, let data = item.imageData {
                loadedImage = NSImage(data: data)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            // Source app icon
            if let bundleID = item.sourceAppBundleID,
               let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            }

            if let app = item.sourceAppName {
                Text(app)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Content type badge
            HStack(spacing: 3) {
                Image(systemName: item.contentType.systemImage)
                    .font(.system(size: 9))
                Text(item.contentType.displayName)
                    .font(Constants.Typography.micro)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.primary.opacity(0.06)))

            // Language badge
            if let lang = item.detectedLanguage {
                Text(SyntaxHighlighter.displayName(for: lang))
                    .font(Constants.Typography.micro)
                    .foregroundStyle(.blue.opacity(0.9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
            }

            Text(item.createdAt.relativeFormatted())
                .font(Constants.Typography.footnote)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var previewContent: some View {
        switch item.contentType {
        case .image:
            imageContent

        case .link:
            linkContent

        case .file:
            fileContent

        case .text, .richText:
            textContent
        }
    }

    // MARK: - Text Content

    /// Whether this item needs syntax/markdown rendering (code or markdown).
    private var needsRendering: Bool {
        !item.isMasked && (item.detectedLanguage != nil || item.isMarkdown)
    }

    /// Stable key for the rendered content cache.
    private var currentRenderKey: Int {
        var h = Hasher()
        h.combine(item.textContent)
        h.combine(colorScheme == .dark)
        return h.finalize()
    }

    @ViewBuilder
    private var textContent: some View {
        if item.isMasked {
            Text(String(repeating: "*", count: min(item.textContent?.count ?? 0, 200)))
                .font(Constants.Typography.body)
                .foregroundStyle(.secondary)
        } else if needsRendering, let text = item.textContent {
            // Show cached rendered text, or plain text placeholder while rendering
            let previewText = String(text.prefix(5000))
            Group {
                if let attr = (currentRenderKey == renderKey) ? renderedAttr : nil {
                    Text(attr)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    Text(previewText)
                        .font(item.detectedLanguage != nil
                              ? .system(size: 12, design: .monospaced)
                              : .system(size: 13))
                        .foregroundStyle(.primary.opacity(0.85))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .onAppear { computeRendering(text: previewText) }
                }
            }
            .padding(item.detectedLanguage != nil ? 8 : 0)
            .background {
                if item.detectedLanguage != nil {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.04)
                              : Color.black.opacity(0.03))
                }
            }
        } else if let text = item.textContent {
            Text(text)
                .font(Constants.Typography.body)
                .foregroundStyle(.primary.opacity(0.9))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        // Character count footer
        if let count = item.characterCount {
            HStack(spacing: 4) {
                Text("\(count) characters")
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.tertiary)
                if let text = item.textContent {
                    let lines = text.components(separatedBy: .newlines).count
                    Text("\u{00B7} \(lines) lines")
                        .font(Constants.Typography.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 6)
        }
    }

    /// Renders syntax highlighting or markdown off the synchronous body path.
    /// The view shows plain text immediately, then swaps in the styled version.
    private func computeRendering(text: String) {
        let isDark = colorScheme == .dark
        let key = currentRenderKey

        let nsAttr: NSAttributedString
        if let lang = item.detectedLanguage {
            nsAttr = SyntaxHighlighter.shared.highlight(text, language: lang, isDark: isDark)
        } else {
            nsAttr = MarkdownRenderer.shared.render(text, isDark: isDark)
        }
        let swiftAttr = try? AttributedString(nsAttr, including: \.appKit)
        renderedAttr = swiftAttr
        renderKey = key
    }

    // MARK: - Image Content

    @ViewBuilder
    private var imageContent: some View {
        if let nsImage = loadedImage {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                }

            // Image dimensions
            HStack(spacing: 4) {
                Text("\(Int(nsImage.size.width)) x \(Int(nsImage.size.height))")
                    .font(Constants.Typography.footnote)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 4)
        }

        // OCR text
        if let ocrText = item.ocrText {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "text.viewfinder")
                        .font(.system(size: 10))
                    Text("Extracted Text")
                        .font(Constants.Typography.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 8)

                Text(ocrText)
                    .font(Constants.Typography.body)
                    .foregroundStyle(.primary.opacity(0.85))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: - Link Content

    private var linkContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let urlString = item.textContent {
                let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines))
                let host = url?.host ?? urlString
                let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host

                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 32, height: 32)
                        Text(String(domain.prefix(1)).uppercased())
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if let path = url?.path, path != "/" {
                            Text(path)
                                .font(Constants.Typography.linkDetail)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                Text(urlString)
                    .font(Constants.Typography.linkDetail)
                    .foregroundStyle(.blue.opacity(0.8))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: - File Content

    private var fileContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let paths = item.filePaths {
                let count = paths.count
                Text("\(count) file\(count == 1 ? "" : "s")")
                    .font(Constants.Typography.fileTitle)
                    .foregroundStyle(.primary)

                ForEach(paths, id: \.self) { path in
                    HStack(spacing: 6) {
                        Image(systemName: "doc")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Text(path)
                            .font(Constants.Typography.linkDetail)
                            .foregroundStyle(.primary.opacity(0.85))
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}
