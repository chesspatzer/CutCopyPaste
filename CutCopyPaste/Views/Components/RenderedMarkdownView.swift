import SwiftUI
import AppKit

struct RenderedMarkdownView: NSViewRepresentable {
    let text: String
    let maxHeight: CGFloat
    let fontSize: CGFloat

    @Environment(\.colorScheme) private var colorScheme

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
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let isDark = colorScheme == .dark
        let attributed = MarkdownRenderer.shared.render(text, isDark: isDark, fontSize: fontSize)
        textView.textStorage?.setAttributedString(attributed)
        // Force layout so the text view reports correct size
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
    }
}

struct MarkdownPreviewView: View {
    let text: String
    let lineLimit: Int
    let isCompact: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var previewHeight: CGFloat {
        isCompact ? 48 : 90
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RenderedMarkdownView(
                text: previewText,
                maxHeight: previewHeight,
                fontSize: isCompact ? 11 : 12
            )
            .frame(height: previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.03)
                      : Color.black.opacity(0.02))
        }
    }

    private var previewText: String {
        let lines = text.components(separatedBy: .newlines)
        let limited = Array(lines.prefix(lineLimit))
        return limited.joined(separator: "\n")
    }
}
