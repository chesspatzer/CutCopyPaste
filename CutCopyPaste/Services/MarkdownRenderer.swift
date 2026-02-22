import AppKit
import Foundation

final class MarkdownRenderer {
    static let shared = MarkdownRenderer()

    // MARK: - Markdown Detection

    static func isMarkdown(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard lines.count >= 2 else { return false }

        var score = 0
        let checkLines = lines.prefix(20)

        for line in checkLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Headings: # ## ### etc.
            if trimmed.range(of: "^#{1,6} .+", options: .regularExpression) != nil { score += 3 }
            // Unordered lists: - item or * item
            else if trimmed.range(of: "^[\\-\\*] .+", options: .regularExpression) != nil { score += 1 }
            // Ordered lists: 1. item
            else if trimmed.range(of: "^\\d+\\. .+", options: .regularExpression) != nil { score += 1 }
            // Code fences
            else if trimmed.hasPrefix("```") { score += 3 }
            // Blockquotes
            else if trimmed.hasPrefix("> ") { score += 2 }
            // Horizontal rules
            else if trimmed.range(of: "^(---|\\*\\*\\*|___)\\s*$", options: .regularExpression) != nil { score += 2 }
        }

        // Inline patterns (check full text)
        let sample = String(text.prefix(2000))
        // Bold: **text** or __text__
        if sample.range(of: "\\*\\*[^*]+\\*\\*", options: .regularExpression) != nil { score += 2 }
        // Italic: *text* or _text_ (but not inside words like file_name)
        if sample.range(of: "(?<![\\w*])\\*[^*\\n]+\\*(?![\\w*])", options: .regularExpression) != nil { score += 1 }
        // Inline code: `code`
        if sample.range(of: "`[^`]+`", options: .regularExpression) != nil { score += 1 }
        // Links: [text](url)
        if sample.range(of: "\\[[^\\]]+\\]\\([^)]+\\)", options: .regularExpression) != nil { score += 2 }
        // Images: ![alt](url)
        if sample.range(of: "!\\[[^\\]]*\\]\\([^)]+\\)", options: .regularExpression) != nil { score += 2 }

        return score >= 4
    }

    // MARK: - Render to NSAttributedString

    func render(_ text: String, isDark: Bool, fontSize: CGFloat = 13) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")

        let bodyFont = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        let bodyColor = isDark ? NSColor.white.withAlphaComponent(0.88) : NSColor.black.withAlphaComponent(0.85)
        let mutedColor = isDark ? NSColor.white.withAlphaComponent(0.4) : NSColor.black.withAlphaComponent(0.35)
        let linkColor = isDark ? NSColor(red: 0.45, green: 0.68, blue: 0.95, alpha: 1.0) : NSColor.systemBlue
        let codeColor = isDark ? NSColor(red: 0.84, green: 0.40, blue: 0.36, alpha: 1.0) : NSColor(red: 0.72, green: 0.22, blue: 0.22, alpha: 1.0)
        let codeBgColor = isDark ? NSColor.white.withAlphaComponent(0.06) : NSColor.black.withAlphaComponent(0.04)
        let codeFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        let blockquoteColor = isDark ? NSColor.white.withAlphaComponent(0.55) : NSColor.black.withAlphaComponent(0.5)

        var inCodeBlock = false
        var codeBlockContent: [String] = []
        var codeBlockLanguage: String?
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code fence toggle
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End code block — render accumulated code
                    let code = codeBlockContent.joined(separator: "\n")
                    let codeAttrs: [NSAttributedString.Key: Any] = [
                        .font: codeFont,
                        .foregroundColor: codeColor,
                        .backgroundColor: codeBgColor,
                    ]
                    result.append(NSAttributedString(string: code + "\n", attributes: codeAttrs))
                    inCodeBlock = false
                    codeBlockContent = []
                    codeBlockLanguage = nil
                } else {
                    // Start code block
                    inCodeBlock = true
                    let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockLanguage = lang.isEmpty ? nil : lang
                }
                i += 1
                continue
            }

            if inCodeBlock {
                codeBlockContent.append(line)
                i += 1
                continue
            }

            // Heading: # to ######
            if let headingMatch = trimmed.range(of: "^(#{1,6}) (.+)", options: .regularExpression) {
                let fullMatch = String(trimmed[headingMatch])
                let hashCount = fullMatch.prefix(while: { $0 == "#" }).count
                let content = String(fullMatch.dropFirst(hashCount + 1))
                let headingSize: CGFloat = fontSize + CGFloat(7 - hashCount) * 2
                let headingFont = NSFont.systemFont(ofSize: headingSize, weight: hashCount <= 2 ? .bold : .semibold)
                let headingAttrs: [NSAttributedString.Key: Any] = [
                    .font: headingFont,
                    .foregroundColor: bodyColor,
                ]
                let rendered = renderInlineElements(content, baseAttrs: headingAttrs, isDark: isDark, linkColor: linkColor, codeColor: codeColor, codeBgColor: codeBgColor, codeFont: codeFont)
                result.append(rendered)
                result.append(NSAttributedString(string: "\n", attributes: headingAttrs))
                i += 1
                continue
            }

            // Horizontal rule
            if trimmed.range(of: "^(---|\\*\\*\\*|___)\\s*$", options: .regularExpression) != nil {
                let ruleAttrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: mutedColor,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: mutedColor,
                ]
                result.append(NSAttributedString(string: "                              \n", attributes: ruleAttrs))
                i += 1
                continue
            }

            // Blockquote: > text
            if trimmed.hasPrefix("> ") {
                let content = String(trimmed.dropFirst(2))
                let quoteAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: fontSize, weight: .regular).withTraits(.italicFontMask),
                    .foregroundColor: blockquoteColor,
                ]
                let rendered = renderInlineElements(content, baseAttrs: quoteAttrs, isDark: isDark, linkColor: linkColor, codeColor: codeColor, codeBgColor: codeBgColor, codeFont: codeFont)
                let bar = NSAttributedString(string: "\u{258F} ", attributes: [
                    .font: bodyFont,
                    .foregroundColor: isDark ? NSColor.systemBlue.withAlphaComponent(0.5) : NSColor.systemBlue.withAlphaComponent(0.4),
                ])
                result.append(bar)
                result.append(rendered)
                result.append(NSAttributedString(string: "\n", attributes: quoteAttrs))
                i += 1
                continue
            }

            // Unordered list: - item or * item
            if trimmed.range(of: "^[\\-\\*] .+", options: .regularExpression) != nil {
                let content = String(trimmed.dropFirst(2))
                let bulletAttrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: bodyColor,
                ]
                result.append(NSAttributedString(string: "  \u{2022} ", attributes: bulletAttrs))
                let rendered = renderInlineElements(content, baseAttrs: bulletAttrs, isDark: isDark, linkColor: linkColor, codeColor: codeColor, codeBgColor: codeBgColor, codeFont: codeFont)
                result.append(rendered)
                result.append(NSAttributedString(string: "\n", attributes: bulletAttrs))
                i += 1
                continue
            }

            // Ordered list: 1. item
            if let match = trimmed.range(of: "^(\\d+)\\. (.+)", options: .regularExpression) {
                let fullMatch = String(trimmed[match])
                let dotIdx = fullMatch.firstIndex(of: ".")!
                let num = String(fullMatch[fullMatch.startIndex..<dotIdx])
                let content = String(fullMatch[fullMatch.index(dotIdx, offsetBy: 2)...])
                let numAttrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: bodyColor,
                ]
                result.append(NSAttributedString(string: "  \(num). ", attributes: numAttrs))
                let rendered = renderInlineElements(content, baseAttrs: numAttrs, isDark: isDark, linkColor: linkColor, codeColor: codeColor, codeBgColor: codeBgColor, codeFont: codeFont)
                result.append(rendered)
                result.append(NSAttributedString(string: "\n", attributes: numAttrs))
                i += 1
                continue
            }

            // Empty line = paragraph break
            if trimmed.isEmpty {
                result.append(NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: fontSize * 0.4)]))
                i += 1
                continue
            }

            // Regular paragraph
            let paraAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: bodyColor,
            ]
            let rendered = renderInlineElements(trimmed, baseAttrs: paraAttrs, isDark: isDark, linkColor: linkColor, codeColor: codeColor, codeBgColor: codeBgColor, codeFont: codeFont)
            result.append(rendered)
            result.append(NSAttributedString(string: "\n", attributes: paraAttrs))
            i += 1
        }

        // If code block was never closed, flush it
        if inCodeBlock && !codeBlockContent.isEmpty {
            let code = codeBlockContent.joined(separator: "\n")
            let codeAttrs: [NSAttributedString.Key: Any] = [
                .font: codeFont,
                .foregroundColor: codeColor,
                .backgroundColor: codeBgColor,
            ]
            result.append(NSAttributedString(string: code + "\n", attributes: codeAttrs))
        }

        return result
    }

    // MARK: - Inline Element Rendering

    private func renderInlineElements(
        _ text: String,
        baseAttrs: [NSAttributedString.Key: Any],
        isDark: Bool,
        linkColor: NSColor,
        codeColor: NSColor,
        codeBgColor: NSColor,
        codeFont: NSFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
        let baseFont = baseAttrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: 13)

        // Process inline elements in order of specificity (most specific first to avoid overlap)

        // Images: ![alt](url) — replace with [alt] label
        applyPattern("!\\[[^\\]]*\\]\\([^)]+\\)", to: result) { range, match in
            // Extract alt text
            if let altStart = match.range(of: "!["), let altEnd = match.range(of: "](") {
                let alt = String(match[altStart.upperBound..<altEnd.lowerBound])
                let display = alt.isEmpty ? "[image]" : "[\(alt)]"
                result.replaceCharacters(in: range, with: NSAttributedString(string: display, attributes: [
                    .font: baseFont,
                    .foregroundColor: linkColor,
                ]))
                return true
            }
            return false
        }

        // Links: [text](url)
        applyPattern("\\[[^\\]]+\\]\\([^)]+\\)", to: result) { range, match in
            if let textStart = match.firstIndex(of: "["),
               let textEnd = match.range(of: "]("),
               let urlEnd = match.lastIndex(of: ")") {
                let linkText = String(match[match.index(after: textStart)..<textEnd.lowerBound])
                let url = String(match[textEnd.upperBound..<urlEnd])
                var attrs = baseAttrs
                attrs[.foregroundColor] = linkColor
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                if let linkURL = URL(string: url) {
                    attrs[.link] = linkURL
                }
                result.replaceCharacters(in: range, with: NSAttributedString(string: linkText, attributes: attrs))
                return true
            }
            return false
        }

        // Inline code: `code`
        applyPattern("`[^`]+`", to: result) { range, match in
            let code = String(match.dropFirst().dropLast())
            var attrs = baseAttrs
            attrs[.font] = codeFont
            attrs[.foregroundColor] = codeColor
            attrs[.backgroundColor] = codeBgColor
            result.replaceCharacters(in: range, with: NSAttributedString(string: code, attributes: attrs))
            return true
        }

        // Bold + italic: ***text*** or ___text___
        applyPattern("(\\*{3}|_{3})(?!\\s)(.+?)(?<!\\s)\\1", to: result) { range, match in
            let content = extractDelimitedContent(match, delimiterLength: 3)
            var attrs = baseAttrs
            attrs[.font] = baseFont.withTraits([.boldFontMask, .italicFontMask])
            result.replaceCharacters(in: range, with: NSAttributedString(string: content, attributes: attrs))
            return true
        }

        // Bold: **text** or __text__
        applyPattern("(\\*{2}|_{2})(?!\\s)(.+?)(?<!\\s)\\1", to: result) { range, match in
            let content = extractDelimitedContent(match, delimiterLength: 2)
            var attrs = baseAttrs
            attrs[.font] = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
            result.replaceCharacters(in: range, with: NSAttributedString(string: content, attributes: attrs))
            return true
        }

        // Italic: *text* or _text_ (not inside words)
        applyPattern("(?<![\\w*\\\\])([*_])(?!\\s)(.+?)(?<!\\s)\\1(?![\\w*])", to: result) { range, match in
            let content = extractDelimitedContent(match, delimiterLength: 1)
            var attrs = baseAttrs
            attrs[.font] = baseFont.withTraits(.italicFontMask)
            result.replaceCharacters(in: range, with: NSAttributedString(string: content, attributes: attrs))
            return true
        }

        // Strikethrough: ~~text~~
        applyPattern("~~[^~]+~~", to: result) { range, match in
            let content = String(match.dropFirst(2).dropLast(2))
            var attrs = baseAttrs
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            result.replaceCharacters(in: range, with: NSAttributedString(string: content, attributes: attrs))
            return true
        }

        return result
    }

    // MARK: - Helpers

    private func applyPattern(
        _ pattern: String,
        to attrString: NSMutableAttributedString,
        handler: (NSRange, String) -> Bool
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        // Process matches from end to start so range replacements don't invalidate earlier ranges
        let fullString = attrString.string
        let matches = regex.matches(in: fullString, range: NSRange(fullString.startIndex..., in: fullString))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: fullString) else { continue }
            let matchText = String(fullString[range])
            _ = handler(match.range, matchText)
        }
    }

    private func extractDelimitedContent(_ text: String, delimiterLength: Int) -> String {
        guard text.count > delimiterLength * 2 else { return text }
        let start = text.index(text.startIndex, offsetBy: delimiterLength)
        let end = text.index(text.endIndex, offsetBy: -delimiterLength)
        guard start < end else { return text }
        return String(text[start..<end])
    }
}

// MARK: - NSFont Extension

private extension NSFont {
    func withTraits(_ traits: NSFontTraitMask) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(NSFontDescriptor.SymbolicTraits(rawValue: UInt32(traits.rawValue)))
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
