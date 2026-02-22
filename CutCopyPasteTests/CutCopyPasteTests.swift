import XCTest
@testable import CutCopyPaste

final class CutCopyPasteTests: XCTestCase {
    func testClipboardItemCreation() {
        let item = ClipboardItem(
            contentType: .text,
            textContent: "Hello, World!"
        )
        XCTAssertEqual(item.contentType, .text)
        XCTAssertEqual(item.textContent, "Hello, World!")
        XCTAssertEqual(item.characterCount, 13)
        XCTAssertFalse(item.isPinned)
        XCTAssertEqual(item.useCount, 0)
    }

    func testClipboardItemPreview() {
        let textItem = ClipboardItem(contentType: .text, textContent: "Short text")
        XCTAssertEqual(textItem.preview, "Short text")

        let longText = String(repeating: "a", count: 200)
        let longItem = ClipboardItem(contentType: .text, textContent: longText)
        XCTAssertEqual(longItem.preview.count, 150)

        let imageItem = ClipboardItem(contentType: .image)
        XCTAssertEqual(imageItem.preview, "Image")

        let fileItem = ClipboardItem(contentType: .file, filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        XCTAssertEqual(fileItem.preview, "2 files")
    }

    func testClipboardItemType() {
        XCTAssertEqual(ClipboardItemType.allCases.count, 5)
        XCTAssertEqual(ClipboardItemType.text.displayName, "Text")
        XCTAssertEqual(ClipboardItemType.link.systemImage, "link")
    }

    func testExclusionListManager() {
        let manager = ExclusionListManager()
        XCTAssertTrue(manager.isExcluded(bundleID: "com.1password.1password"))
        XCTAssertTrue(manager.isExcluded(bundleID: "com.bitwarden.desktop"))
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.Safari"))
    }

    func testDateFormatting() {
        let now = Date()
        XCTAssertEqual(now.relativeFormatted(), "Just now")

        let fiveMinutesAgo = Date(timeIntervalSinceNow: -300)
        XCTAssertEqual(fiveMinutesAgo.relativeFormatted(), "5m ago")

        let twoHoursAgo = Date(timeIntervalSinceNow: -7200)
        XCTAssertEqual(twoHoursAgo.relativeFormatted(), "2h ago")

        let yesterday = Date(timeIntervalSinceNow: -100000)
        XCTAssertEqual(yesterday.relativeFormatted(), "Yesterday")
    }

    func testStringTruncation() {
        XCTAssertEqual("Hello".truncated(to: 10), "Hello")
        XCTAssertEqual("Hello, World!".truncated(to: 5), "Hello...")
        XCTAssertEqual("Hello\nWorld".firstLine, "Hello")
    }
}
