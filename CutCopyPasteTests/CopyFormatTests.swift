import XCTest
@testable import CutCopyPaste

final class CopyFormatTests: XCTestCase {

    // MARK: - CopyFormat Enum

    func testAllCopyFormats() {
        XCTAssertEqual(CopyFormat.allCases.count, 6)
    }

    func testDisplayNames() {
        XCTAssertEqual(CopyFormat.plainText.displayName, "Plain Text")
        XCTAssertEqual(CopyFormat.markdownCodeBlock.displayName, "Markdown Code Block")
        XCTAssertEqual(CopyFormat.htmlPreBlock.displayName, "HTML <pre> Block")
        XCTAssertEqual(CopyFormat.quotedText.displayName, "Quoted Text")
        XCTAssertEqual(CopyFormat.escapedString.displayName, "Escaped String")
        XCTAssertEqual(CopyFormat.singleLine.displayName, "Single Line")
    }

    func testSystemImages() {
        for format in CopyFormat.allCases {
            XCTAssertFalse(format.systemImage.isEmpty, "\(format) should have a system image")
        }
    }

    // MARK: - SearchMode Enum

    func testSearchModeValues() {
        XCTAssertEqual(SearchMode.allCases.count, 2)
        XCTAssertEqual(SearchMode.natural.rawValue, "natural")
        XCTAssertEqual(SearchMode.regex.rawValue, "regex")
    }
}
