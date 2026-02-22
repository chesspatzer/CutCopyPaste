import SwiftUI
import AppKit

/// Renders syntax-highlighted code using NSTextView via NSViewRepresentable.
struct SyntaxHighlightedText: NSViewRepresentable {
    let text: String
    let language: String
    let maxHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let isDark = colorScheme == .dark
        let attributed = SyntaxHighlighter.shared.highlight(text, language: language, isDark: isDark)
        textView.textStorage?.setAttributedString(attributed)
    }
}

/// A compact code preview with syntax highlighting, suitable for clipboard item rows.
struct CodePreviewView: View {
    let text: String
    let language: String
    let lineLimit: Int
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SyntaxHighlightedText(
                text: previewText,
                language: language,
                maxHeight: isCompact ? 36 : 72
            )
            .frame(maxHeight: isCompact ? 36 : 72)
            .clipShape(RoundedRectangle(cornerRadius: 4))
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
