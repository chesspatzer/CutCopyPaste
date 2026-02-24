import SwiftUI
import AppKit

/// Renders syntax-highlighted code using NSTextView via NSViewRepresentable.
/// Used only in detail/full views — card previews use the lightweight CodePreviewView instead.
struct SyntaxHighlightedText: NSViewRepresentable {
    let text: String
    let language: String
    let maxHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    final class Coordinator {
        var lastTextHash: Int = 0
        var lastIsDark: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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
        let attributed = SyntaxHighlighter.shared.highlight(text, language: language, isDark: isDark)
        textView.textStorage?.setAttributedString(attributed)
    }
}

/// Lightweight pure-SwiftUI code preview for clipboard item cards.
/// Uses SwiftUI Text(AttributedString) instead of NSViewRepresentable for fast scroll performance.
/// Caches the highlighted result in @State to avoid re-running SyntaxHighlighter on every body evaluation.
struct CodePreviewView: View {
    let text: String
    let language: String
    let lineLimit: Int
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    @State private var cachedAttr: AttributedString?
    @State private var cacheKey: Int = 0

    private var previewHeight: CGFloat {
        isCompact ? 42 : 78
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
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(lineLimit)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: previewHeight, alignment: .topLeading)
                    .onAppear { computeHighlight(key: key) }
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.black.opacity(0.03))
        }
        .onChange(of: key) { _, newKey in
            computeHighlight(key: newKey)
        }
    }

    private func computeHighlight(key: Int) {
        let isDark = colorScheme == .dark
        let nsAttr = SyntaxHighlighter.shared.highlight(previewText, language: language, isDark: isDark)
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
