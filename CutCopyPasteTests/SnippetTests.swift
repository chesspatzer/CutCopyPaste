import XCTest
@testable import CutCopyPaste

final class SnippetTests: XCTestCase {
    // MARK: - Snippet Creation

    func testSnippetCreation() {
        let snippet = Snippet(title: "Test", content: "Hello {{name}}")
        XCTAssertEqual(snippet.title, "Test")
        XCTAssertEqual(snippet.content, "Hello {{name}}")
        XCTAssertFalse(snippet.isBuiltIn)
        XCTAssertEqual(snippet.useCount, 0)
    }

    // MARK: - Placeholder Extraction

    func testExtractsPlaceholders() {
        let snippet = Snippet(title: "Test", content: "Hello {{name}}, welcome to {{place}}")
        let placeholders = snippet.placeholders
        XCTAssertEqual(placeholders.count, 2)
        XCTAssertTrue(placeholders.contains("name"))
        XCTAssertTrue(placeholders.contains("place"))
    }

    func testExtractsNoDuplicatePlaceholders() {
        let snippet = Snippet(title: "Test", content: "{{name}} and {{name}} again")
        let placeholders = snippet.placeholders
        XCTAssertEqual(placeholders.count, 1)
        XCTAssertTrue(placeholders.contains("name"))
    }

    func testNoPlaceholders() {
        let snippet = Snippet(title: "Test", content: "Just plain text")
        XCTAssertTrue(snippet.placeholders.isEmpty)
    }

    func testBuiltInPlaceholders() {
        let snippet = Snippet(title: "Test", content: "Today is {{date}}, time is {{time}}, id: {{uuid}}")
        let placeholders = snippet.placeholders
        XCTAssertTrue(placeholders.contains("date"))
        XCTAssertTrue(placeholders.contains("time"))
        XCTAssertTrue(placeholders.contains("uuid"))
    }

    // MARK: - SnippetFolder

    func testSnippetFolderCreation() {
        let folder = SnippetFolder(name: "Work", iconName: "briefcase")
        XCTAssertEqual(folder.name, "Work")
        XCTAssertEqual(folder.iconName, "briefcase")
    }

    // MARK: - ClipboardRule

    func testClipboardRuleCreation() {
        let rule = ClipboardRule(
            name: "Strip ANSI",
            transformType: .stripAnsi,
            sortOrder: 0
        )
        XCTAssertEqual(rule.name, "Strip ANSI")
        XCTAssertTrue(rule.isEnabled)
        XCTAssertEqual(rule.transformTypeEnum, .stripAnsi)
    }

    func testClipboardRuleTransformTypes() {
        let allTypes = ClipboardTransformType.allCases
        XCTAssertTrue(allTypes.count >= 7)
        XCTAssertTrue(allTypes.contains(.stripAnsi))
        XCTAssertTrue(allTypes.contains(.prettifyJson))
        XCTAssertTrue(allTypes.contains(.stripTrackingParams))
        XCTAssertTrue(allTypes.contains(.regexReplace))
        XCTAssertTrue(allTypes.contains(.trimWhitespace))
        XCTAssertTrue(allTypes.contains(.lowercaseAll))
        XCTAssertTrue(allTypes.contains(.uppercaseAll))
    }

    func testClipboardTransformTypeDisplayNames() {
        for type in ClipboardTransformType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
}
