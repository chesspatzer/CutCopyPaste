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
struct CodePreviewView: View {
    let text: String
    let language: String
    let lineLimit: Int
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var previewHeight: CGFloat {
        isCompact ? 42 : 78
    }

    var body: some View {
        let isDark = colorScheme == .dark
        let nsAttr = SyntaxHighlighter.shared.highlight(previewText, language: language, isDark: isDark)
        let swiftAttr = try? AttributedString(nsAttr, including: \.appKit)

        VStack(alignment: .leading, spacing: 0) {
            if let swiftAttr {
                Text(swiftAttr)
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
            }
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.04)
                      : Color.black.opacity(0.03))
        }
    }

    private var previewText: String {
        let lines = text.components(separatedBy: .newlines)
        let limited = Array(lines.prefix(lineLimit))
        return limited.joined(separator: "\n")
    }
}
