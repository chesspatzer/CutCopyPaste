import XCTest
@testable import CutCopyPaste

final class CutCopyPasteTests: XCTestCase {

    // MARK: - ClipboardItem Creation

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

    func testClipboardItemWithSourceApp() {
        let item = ClipboardItem(
            contentType: .text,
            textContent: "test",
            sourceAppBundleID: "com.apple.Safari",
            sourceAppName: "Safari"
        )
        XCTAssertEqual(item.sourceAppBundleID, "com.apple.Safari")
        XCTAssertEqual(item.sourceAppName, "Safari")
    }

    func testClipboardItemLink() {
        let item = ClipboardItem(contentType: .link, textContent: "https://example.com")
        XCTAssertEqual(item.contentType, .link)
        XCTAssertEqual(item.textContent, "https://example.com")
    }

    func testClipboardItemRichText() {
        let item = ClipboardItem(contentType: .richText, textContent: "Rich text content")
        XCTAssertEqual(item.contentType, .richText)
    }

    func testClipboardItemFile() {
        let item = ClipboardItem(contentType: .file, filePaths: ["/tmp/a.txt", "/tmp/b.txt"])
        XCTAssertEqual(item.filePaths?.count, 2)
    }

    func testClipboardItemImage() {
        let item = ClipboardItem(contentType: .image)
        XCTAssertNil(item.textContent)
        XCTAssertEqual(item.contentType, .image)
    }

    // MARK: - Preview

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

    func testPreviewSingleFile() {
        let item = ClipboardItem(contentType: .file, filePaths: ["/tmp/a.txt"])
        XCTAssertEqual(item.preview, "1 file")
    }

    func testPreviewNoFiles() {
        let item = ClipboardItem(contentType: .file, filePaths: [])
        XCTAssertEqual(item.preview, "0 files")
    }

    func testPreviewNilText() {
        let item = ClipboardItem(contentType: .text, textContent: nil)
        // preview returns "" when textContent is nil for .text type
        XCTAssertEqual(item.preview, "")
    }

    func testPreviewMultiline() {
        let item = ClipboardItem(contentType: .text, textContent: "first line\nsecond line\nthird line")
        // Preview should show the text (up to 150 chars)
        XCTAssertTrue(item.preview.contains("first line"))
    }

    // MARK: - ClipboardItemType

    func testClipboardItemTypeAllCases() {
        XCTAssertEqual(ClipboardItemType.allCases.count, 5)
    }

    func testClipboardItemTypeDisplayNames() {
        XCTAssertEqual(ClipboardItemType.text.displayName, "Text")
        XCTAssertEqual(ClipboardItemType.link.displayName, "Link")
        XCTAssertEqual(ClipboardItemType.image.displayName, "Image")
        XCTAssertEqual(ClipboardItemType.file.displayName, "File")
        XCTAssertEqual(ClipboardItemType.richText.displayName, "Rich Text")
    }

    func testClipboardItemTypeSystemImages() {
        XCTAssertEqual(ClipboardItemType.text.systemImage, "doc.text")
        XCTAssertEqual(ClipboardItemType.link.systemImage, "link")
        for type in ClipboardItemType.allCases {
            XCTAssertFalse(type.systemImage.isEmpty)
        }
    }

    func testClipboardItemTypeIdentifiable() {
        for type in ClipboardItemType.allCases {
            XCTAssertFalse(type.id.isEmpty)
        }
    }

    // MARK: - Item Properties

    func testPinToggle() {
        let item = ClipboardItem(contentType: .text, textContent: "test")
        XCTAssertFalse(item.isPinned)
        item.isPinned = true
        XCTAssertTrue(item.isPinned)
    }

    func testUseCount() {
        let item = ClipboardItem(contentType: .text, textContent: "test")
        XCTAssertEqual(item.useCount, 0)
        item.useCount += 1
        XCTAssertEqual(item.useCount, 1)
    }

    func testMasked() {
        let item = ClipboardItem(contentType: .text, textContent: "secret")
        XCTAssertFalse(item.isMasked)
        item.isMasked = true
        XCTAssertTrue(item.isMasked)
    }

    func testSensitiveDataTypes() {
        let item = ClipboardItem(contentType: .text, textContent: "test")
        XCTAssertNil(item.sensitiveDataTypes)
        item.sensitiveDataTypes = ["awsAccessKey", "creditCard"]
        XCTAssertEqual(item.sensitiveDataTypes?.count, 2)
    }

    // MARK: - ExclusionListManager

    func testExclusionListManager() {
        let manager = ExclusionListManager()
        XCTAssertTrue(manager.isExcluded(bundleID: "com.1password.1password"))
        XCTAssertTrue(manager.isExcluded(bundleID: "com.bitwarden.desktop"))
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.Safari"))
    }

    func testExclusionListDefaults() {
        let defaults = ExclusionListManager.defaultExclusions
        XCTAssertTrue(defaults.contains("com.1password.1password"))
        XCTAssertTrue(defaults.contains("com.bitwarden.desktop"))
        XCTAssertGreaterThanOrEqual(defaults.count, 4)
    }

    func testExclusionListAllExclusions() {
        let manager = ExclusionListManager()
        let all = manager.allExclusions()
        XCTAssertFalse(all.isEmpty)
    }

    // MARK: - Date Formatting

    func testDateFormattingJustNow() {
        let now = Date()
        XCTAssertEqual(now.relativeFormatted(), "Just now")
    }

    func testDateFormattingMinutesAgo() {
        let fiveMinutesAgo = Date(timeIntervalSinceNow: -300)
        XCTAssertEqual(fiveMinutesAgo.relativeFormatted(), "5m ago")
    }

    func testDateFormattingHoursAgo() {
        let twoHoursAgo = Date(timeIntervalSinceNow: -7200)
        XCTAssertEqual(twoHoursAgo.relativeFormatted(), "2h ago")
    }

    func testDateFormattingYesterday() {
        let yesterday = Date(timeIntervalSinceNow: -100000)
        XCTAssertEqual(yesterday.relativeFormatted(), "Yesterday")
    }

    func testDateFormattingDaysAgo() {
        let threeDaysAgo = Date(timeIntervalSinceNow: -259200)
        XCTAssertEqual(threeDaysAgo.relativeFormatted(), "3d ago")
    }

    func testDateFormattingOneMinuteAgo() {
        let oneMinuteAgo = Date(timeIntervalSinceNow: -60)
        XCTAssertEqual(oneMinuteAgo.relativeFormatted(), "1m ago")
    }

    func testDateFormattingOneHourAgo() {
        let oneHourAgo = Date(timeIntervalSinceNow: -3600)
        XCTAssertEqual(oneHourAgo.relativeFormatted(), "1h ago")
    }

    // MARK: - String Truncation

    func testStringTruncation() {
        XCTAssertEqual("Hello".truncated(to: 10), "Hello")
        XCTAssertEqual("Hello, World!".truncated(to: 5), "Hello...")
        XCTAssertEqual("Hello\nWorld".firstLine, "Hello")
    }

    func testStringTruncationExactLength() {
        XCTAssertEqual("Hello".truncated(to: 5), "Hello")
    }

    func testStringTruncationEmpty() {
        XCTAssertEqual("".truncated(to: 5), "")
    }

    func testFirstLineMultiple() {
        XCTAssertEqual("a\nb\nc".firstLine, "a")
    }

    func testFirstLineSingle() {
        XCTAssertEqual("single line".firstLine, "single line")
    }

    func testFirstLineEmpty() {
        XCTAssertEqual("".firstLine, "")
    }

    // MARK: - Constants

    func testConstantsExist() {
        XCTAssertGreaterThan(Constants.UI.cornerRadius, 0)
        XCTAssertGreaterThan(Constants.UI.popoverDefaultWidth, 0)
        XCTAssertGreaterThan(Constants.UI.popoverDefaultHeight, 0)
        XCTAssertGreaterThan(Constants.UI.cardSpacing, 0)
        XCTAssertGreaterThan(Constants.Defaults.maxHistoryCount, 0)
        XCTAssertGreaterThan(Constants.Defaults.pollInterval, 0)
    }
}
