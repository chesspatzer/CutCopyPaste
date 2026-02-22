import XCTest
@testable import CutCopyPaste

final class ShareServiceTests: XCTestCase {
    let service = ShareService.shared

    // MARK: - Slack Format

    func testFormatForSlackWithLanguage() {
        let result = service.formatForSlack("print('hello')", language: "python")
        XCTAssertTrue(result.hasPrefix("```python"))
        XCTAssertTrue(result.hasSuffix("```"))
        XCTAssertTrue(result.contains("print('hello')"))
    }

    func testFormatForSlackNoLanguage() {
        let result = service.formatForSlack("hello world", language: nil)
        XCTAssertTrue(result.hasPrefix("```"))
        XCTAssertTrue(result.hasSuffix("```"))
    }

    // MARK: - Discord Format

    func testFormatForDiscordWithLanguage() {
        let result = service.formatForDiscord("func main() {}", language: "go")
        XCTAssertTrue(result.hasPrefix("```go"))
        XCTAssertTrue(result.hasSuffix("```"))
    }

    func testFormatForDiscordNoLanguage() {
        let result = service.formatForDiscord("some text", language: nil)
        XCTAssertTrue(result.hasPrefix("```"))
    }

    // MARK: - Markdown Link

    func testFormatAsMarkdownLink() {
        let result = service.formatAsMarkdownLink("https://example.com/page")
        XCTAssertEqual(result, "[example.com](https://example.com/page)")
    }

    func testFormatAsMarkdownLinkWithSubdomain() {
        let result = service.formatAsMarkdownLink("https://docs.example.com/api")
        XCTAssertTrue(result.contains("[docs.example.com]"))
        XCTAssertTrue(result.contains("(https://docs.example.com/api)"))
    }
}
