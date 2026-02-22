import Foundation

struct MarkdownToPlainTextTransform: ClipboardTransform {
    let id = "markdown_to_plain"
    let name = "Markdown → Plain Text"
    let description = "Strip Markdown formatting"
    let iconSystemName = "doc.plaintext"
    let inputSignatures: Set<ContentSignature> = [.markdown]

    func canApply(to text: String) -> Bool {
        let markers = ["# ", "## ", "**", "__", "```", "- ", "* ", "["]
        return markers.contains { text.contains($0) }
    }

    func apply(to text: String) -> Result<String, TransformError> {
        var result = text

        // Remove code blocks
        result = result.replacingOccurrences(
            of: "```[\\s\\S]*?```",
            with: "",
            options: .regularExpression
        )

        // Remove inline code
        result = result.replacingOccurrences(
            of: "`([^`]+)`",
            with: "$1",
            options: .regularExpression
        )

        // Remove headers (keep text)
        result = result.replacingOccurrences(
            of: "^#{1,6}\\s+",
            with: "",
            options: .regularExpression
        )

        // Remove bold
        result = result.replacingOccurrences(
            of: "\\*\\*(.+?)\\*\\*",
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "__(.+?)__",
            with: "$1",
            options: .regularExpression
        )

        // Remove italic
        result = result.replacingOccurrences(
            of: "\\*(.+?)\\*",
            with: "$1",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "_(.+?)_",
            with: "$1",
            options: .regularExpression
        )

        // Remove links, keep text
        result = result.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\([^)]+\\)",
            with: "$1",
            options: .regularExpression
        )

        // Remove images
        result = result.replacingOccurrences(
            of: "!\\[([^\\]]*)\\]\\([^)]+\\)",
            with: "$1",
            options: .regularExpression
        )

        // Remove horizontal rules
        result = result.replacingOccurrences(
            of: "^[\\-\\*_]{3,}$",
            with: "",
            options: .regularExpression
        )

        // Clean up bullet points
        result = result.replacingOccurrences(
            of: "^[\\-\\*]\\s+",
            with: "- ",
            options: .regularExpression
        )

        // Remove extra blank lines
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return .success(result.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
