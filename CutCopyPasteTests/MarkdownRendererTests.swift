import XCTest
@testable import CutCopyPaste

final class MarkdownRendererTests: XCTestCase {
    let renderer = MarkdownRenderer.shared

    // MARK: - Detection

    func testDetectsBasicMarkdown() {
        let md = """
        # Hello World

        This is a **bold** statement.

        - Item one
        - Item two
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testDetectsMarkdownWithCodeFence() {
        let md = """
        ## Setup

        ```swift
        let x = 42
        ```

        Run the above code.
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testDetectsMarkdownWithLinks() {
        let md = """
        # Resources

        Check out [Apple](https://apple.com) and [Google](https://google.com).
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testDetectsMarkdownWithMultipleHeadings() {
        let md = """
        # Title
        ## Subtitle
        Some text here.
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testRejectsPlainText() {
        let text = "This is just a regular sentence with nothing special about it."
        XCTAssertFalse(MarkdownRenderer.isMarkdown(text))
    }

    func testRejectsSingleLine() {
        let text = "# Just a heading"
        XCTAssertFalse(MarkdownRenderer.isMarkdown(text))
    }

    func testRejectsCodeSnippet() {
        let code = """
        func hello() {
            print("hi")
        }
        let x = 42
        """
        XCTAssertFalse(MarkdownRenderer.isMarkdown(code))
    }

    func testDetectsREADMEWithSQLKeywords() {
        // README-style markdown that mentions SQL keywords in prose should still be detected as markdown
        let md = """
        # CutCopyPaste

        A powerful clipboard manager.

        ## Features

        - SQL CREATE TABLE to SwiftData @Model
        - SELECT, INSERT, UPDATE, DELETE support
        - **Bold text** and [links](https://example.com)

        | Category | Transforms |
        |---|---|
        | **Code Gen** | cURL to URLSession |
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testDetectsMarkdownWithTables() {
        let md = """
        ## Settings

        | Tab | Options |
        |---|---|
        | **General** | Max history, retention |
        | **Appearance** | Theme, compact mode |
        """
        XCTAssertTrue(MarkdownRenderer.isMarkdown(md))
    }

    func testRejectsShortTextWithAsterisk() {
        let text = "Hello * world"
        XCTAssertFalse(MarkdownRenderer.isMarkdown(text))
    }

    // MARK: - Rendering: Headings

    func testRendersHeadings() {
        let md = "# Big Heading"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("Big Heading"))
        // Heading text should NOT contain the # prefix
        XCTAssertFalse(string.hasPrefix("#"))
    }

    func testHeadingFontSizeDecreases() {
        let h1 = renderer.render("# H1", isDark: false)
        let h3 = renderer.render("### H3", isDark: false)

        var h1Size: CGFloat = 0
        var h3Size: CGFloat = 0
        h1.enumerateAttribute(.font, in: NSRange(location: 0, length: h1.length)) { val, _, _ in
            if let font = val as? NSFont { h1Size = max(h1Size, font.pointSize) }
        }
        h3.enumerateAttribute(.font, in: NSRange(location: 0, length: h3.length)) { val, _, _ in
            if let font = val as? NSFont { h3Size = max(h3Size, font.pointSize) }
        }
        XCTAssertGreaterThan(h1Size, h3Size)
    }

    // MARK: - Rendering: Bold & Italic

    func testRendersBold() {
        let md = "This is **bold** text"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        // The rendered text should contain "bold" without the ** markers
        XCTAssertTrue(string.contains("bold"))
        XCTAssertFalse(string.contains("**"))
    }

    func testRendersItalic() {
        let md = "This is *italic* text"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("italic"))
        // Single * should be stripped
        XCTAssertFalse(string.contains("*italic*"))
    }

    func testRendersStrikethrough() {
        let md = "This is ~~deleted~~ text"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("deleted"))
        XCTAssertFalse(string.contains("~~"))
    }

    // MARK: - Rendering: Code

    func testRendersInlineCode() {
        let md = "Use the `print()` function"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("print()"))
        XCTAssertFalse(string.contains("`print()`"))
    }

    func testRendersCodeBlock() {
        let md = """
        Here is code:

        ```
        let x = 42
        ```

        After code.
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("let x = 42"))
        XCTAssertFalse(string.contains("```"))
    }

    // MARK: - Rendering: Lists

    func testRendersUnorderedList() {
        let md = """
        - First
        - Second
        - Third
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        // Should use bullet character
        XCTAssertTrue(string.contains("\u{2022}"))
        XCTAssertTrue(string.contains("First"))
        XCTAssertTrue(string.contains("Second"))
    }

    func testRendersOrderedList() {
        let md = """
        1. First
        2. Second
        3. Third
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("1."))
        XCTAssertTrue(string.contains("First"))
        XCTAssertTrue(string.contains("3."))
    }

    // MARK: - Rendering: Links

    func testRendersLinks() {
        let md = "Visit [Apple](https://apple.com) today"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        // Should show link text, not raw markdown
        XCTAssertTrue(string.contains("Apple"))
        XCTAssertFalse(string.contains("]("))
    }

    func testRendersImages() {
        let md = "Look at ![screenshot](image.png) here"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        // Should show alt text in brackets
        XCTAssertTrue(string.contains("screenshot"))
        XCTAssertFalse(string.contains("!["))
    }

    // MARK: - Rendering: Blockquotes

    func testRendersBlockquote() {
        let md = "> This is a quote"
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("This is a quote"))
        // Should have the left-bar character
        XCTAssertTrue(string.contains("\u{258F}"))
    }

    // MARK: - Rendering: Horizontal Rule

    func testRendersHorizontalRule() {
        let md = """
        Above

        ---

        Below
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("Above"))
        XCTAssertTrue(string.contains("Below"))
        XCTAssertFalse(string.contains("---"))
    }

    // MARK: - Dark Mode

    func testDarkModeRendering() {
        let md = "# Hello"
        let light = renderer.render(md, isDark: false)
        let dark = renderer.render(md, isDark: true)
        // Both should produce non-empty output
        XCTAssertGreaterThan(light.length, 0)
        XCTAssertGreaterThan(dark.length, 0)
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        let result = renderer.render("", isDark: false)
        XCTAssertEqual(result.string.trimmingCharacters(in: .whitespacesAndNewlines), "")
    }

    func testUnclosedCodeBlock() {
        let md = """
        ```
        let x = 42
        some more code
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        // Should still render the code even if fence is never closed
        XCTAssertTrue(string.contains("let x = 42"))
    }

    func testComplexDocument() {
        let md = """
        # Project README

        A **powerful** clipboard manager with *many* features.

        ## Features

        - Clipboard history
        - Smart search with `NLEmbedding`
        - Syntax highlighting

        ### Code Example

        ```swift
        let app = ClipboardApp()
        app.run()
        ```

        > Built with love for developers.

        ---

        Visit [our site](https://example.com) for more.
        """
        let result = renderer.render(md, isDark: false)
        let string = result.string
        XCTAssertTrue(string.contains("Project README"))
        XCTAssertTrue(string.contains("powerful"))
        XCTAssertFalse(string.contains("**"))
        XCTAssertTrue(string.contains("\u{2022}"))
        XCTAssertTrue(string.contains("ClipboardApp"))
        XCTAssertFalse(string.contains("```"))
        XCTAssertTrue(string.contains("our site"))
    }
}
