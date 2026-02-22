import XCTest
@testable import CutCopyPaste

final class ContentAnalyzerTests: XCTestCase {
    // MARK: - JSON Detection

    func testDetectsJSON() {
        let json = "{\"name\": \"John\", \"age\": 30}"
        let sigs = ContentAnalyzer.analyze(json)
        XCTAssertTrue(sigs.contains(.json))
    }

    func testDetectsJSONArray() {
        let json = "[1, 2, 3]"
        let sigs = ContentAnalyzer.analyze(json)
        XCTAssertTrue(sigs.contains(.json))
    }

    func testNonJSON() {
        let text = "just some regular text"
        let sigs = ContentAnalyzer.analyze(text)
        XCTAssertFalse(sigs.contains(.json))
    }

    // MARK: - XML Detection

    func testDetectsXML() {
        let xml = "<root><child>value</child></root>"
        let sigs = ContentAnalyzer.analyze(xml)
        XCTAssertTrue(sigs.contains(.xml))
    }

    // MARK: - URL Detection

    func testDetectsURL() {
        let url = "https://www.example.com/path?query=value"
        let sigs = ContentAnalyzer.analyze(url)
        XCTAssertTrue(sigs.contains(.url))
    }

    func testDetectsHTTPURL() {
        let sigs = ContentAnalyzer.analyze("http://example.com")
        XCTAssertTrue(sigs.contains(.url))
    }

    // MARK: - cURL Detection

    func testDetectsCurl() {
        let curl = "curl -X POST https://api.example.com -H 'Content-Type: application/json'"
        let sigs = ContentAnalyzer.analyze(curl)
        XCTAssertTrue(sigs.contains(.curl))
    }

    func testDoesNotDetectCurlInRegularText() {
        let sigs = ContentAnalyzer.analyze("I like curling")
        XCTAssertFalse(sigs.contains(.curl))
    }

    // MARK: - SQL Detection

    func testDetectsSQL() {
        let sql = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL)"
        let sigs = ContentAnalyzer.analyze(sql)
        XCTAssertTrue(sigs.contains(.sql))
    }

    // MARK: - Base64 Detection

    func testDetectsBase64() {
        let base64 = "SGVsbG8gV29ybGQ=" // "Hello World"
        let sigs = ContentAnalyzer.analyze(base64)
        XCTAssertTrue(sigs.contains(.base64))
    }

    // MARK: - Color Detection

    func testDetectsHexColor() {
        let sigs = ContentAnalyzer.analyze("#FF5733")
        XCTAssertTrue(sigs.contains(.hexColor))
    }

    func testDetectsShortHexColor() {
        let sigs = ContentAnalyzer.analyze("#F00")
        XCTAssertTrue(sigs.contains(.hexColor))
    }

    func testDetectsRGBColor() {
        let sigs = ContentAnalyzer.analyze("rgb(255, 87, 51)")
        XCTAssertTrue(sigs.contains(.rgbColor))
    }

    // MARK: - UUID Detection

    func testDetectsUUID() {
        let sigs = ContentAnalyzer.analyze("550e8400-e29b-41d4-a716-446655440000")
        XCTAssertTrue(sigs.contains(.uuid))
    }

    // MARK: - URL Encoded Detection

    func testDetectsURLEncoded() {
        let sigs = ContentAnalyzer.analyze("hello%20world%21")
        XCTAssertTrue(sigs.contains(.urlEncoded))
    }

    // MARK: - Email Detection

    func testDetectsEmail() {
        let sigs = ContentAnalyzer.analyze("user@example.com")
        XCTAssertTrue(sigs.contains(.email))
    }

    // MARK: - Markdown Detection

    func testDetectsMarkdown() {
        // looksLikeMarkdown requires 2+ matching lines from first 10
        let md = "# Heading\n\n## Subheading\n\n- List item\n\nSome **bold** text."
        let sigs = ContentAnalyzer.analyze(md)
        XCTAssertTrue(sigs.contains(.markdown))
    }

    // MARK: - Timestamp Detection

    func testDetectsTimestamp() {
        let sigs = ContentAnalyzer.analyze("1700000000")
        XCTAssertTrue(sigs.contains(.timestamp))
    }

    // MARK: - Plain Text

    func testPlainText() {
        let sigs = ContentAnalyzer.analyze("hello world")
        XCTAssertTrue(sigs.contains(.plainText))
    }

    // MARK: - Empty Input

    func testEmptyString() {
        let sigs = ContentAnalyzer.analyze("")
        XCTAssertTrue(sigs.isEmpty || sigs.contains(.plainText))
    }

    // MARK: - Multiple Signatures

    func testMultipleSignatures() {
        // A JSON string that also contains a URL — might detect both
        let json = "{\"url\": \"https://example.com\"}"
        let sigs = ContentAnalyzer.analyze(json)
        XCTAssertTrue(sigs.contains(.json))
    }
}
