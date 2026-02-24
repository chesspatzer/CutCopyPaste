import SwiftUI
import AppKit

/// Renders rich markdown using NSTextView via NSViewRepresentable.
/// Used only in detail/full views — card previews use the lightweight MarkdownPreviewView instead.
struct RenderedMarkdownView: NSViewRepresentable {
    let text: String
    let maxHeight: CGFloat
    let fontSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    final class Coordinator {
        var lastTextHash: Int = 0
        var lastIsDark: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    init(text: String, maxHeight: CGFloat = 200, fontSize: CGFloat = 13) {
        self.text = text
        self.maxHeight = maxHeight
        self.fontSize = fontSize
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 6, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let isDark = colorScheme == .dark
        let textHash = text.hashValue

        // Skip update if nothing changed
        guard textHash != context.coordinator.lastTextHash || isDark != context.coordinator.lastIsDark else { return }
        context.coordinator.lastTextHash = textHash
        context.coordinator.lastIsDark = isDark

        guard let textView = scrollView.documentView as? NSTextView else { return }
        let attributed = MarkdownRenderer.shared.render(text, isDark: isDark, fontSize: fontSize)
        textView.textStorage?.setAttributedString(attributed)
    }
}

/// Lightweight pure-SwiftUI markdown preview for clipboard item cards.
/// Uses SwiftUI Text(AttributedString) instead of NSViewRepresentable for fast scroll performance.
/// Caches the rendered result in @State to avoid re-running MarkdownRenderer on every body evaluation.
struct MarkdownPreviewView: View {
    let text: String
    let lineLimit: Int
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    @State private var cachedAttr: AttributedString?
    @State private var cacheKey: Int = 0

    private var previewHeight: CGFloat {
        isCompact ? 48 : 90
    }

    /// Stable key combining text content + dark mode — only recompute when this changes.
    private var currentKey: Int {
        var hasher = Hasher()
        hasher.combine(text)
        hasher.combine(colorScheme == .dark)
        return hasher.finalize()
    }

    var body: some View {
        let key = currentKey
        VStack(alignment: .leading, spacing: 0) {
            if let attr = (key == cacheKey) ? cachedAttr : nil {
                Text(attr)
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, maxHeight: previewHeight, alignment: .topLeading)
            } else {
                Text(previewText)
                    .font(.system(size: isCompact ? 11 : 12))
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: previewHeight, alignment: .topLeading)
                    .onAppear { computeRendered(key: key) }
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.03)
                      : Color.black.opacity(0.02))
        }
        .onChange(of: key) { _, newKey in
            computeRendered(key: newKey)
        }
    }

    private func computeRendered(key: Int) {
        let isDark = colorScheme == .dark
        let nsAttr = MarkdownRenderer.shared.render(previewText, isDark: isDark, fontSize: isCompact ? 11 : 12)
        let swiftAttr = try? AttributedString(nsAttr, including: \.appKit)
        cachedAttr = swiftAttr
        cacheKey = key
    }

    private var previewText: String {
        // Scan for the Nth newline instead of splitting the entire string
        var count = 0
        var endIndex = text.startIndex
        while endIndex < text.endIndex && count < lineLimit {
            if text[endIndex] == "\n" { count += 1 }
            if count < lineLimit { endIndex = text.index(after: endIndex) }
        }
        return endIndex == text.endIndex ? text : String(text[text.startIndex..<endIndex])
    }
}
