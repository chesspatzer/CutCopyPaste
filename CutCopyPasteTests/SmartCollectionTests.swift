import XCTest
@testable import CutCopyPaste

final class SmartCollectionTests: XCTestCase {
    let service = SmartCollectionService.shared

    private func makeItem(
        contentType: ClipboardItemType = .text,
        textContent: String? = "test",
        sourceAppBundleID: String? = nil,
        detectedLanguage: String? = nil,
        useCount: Int = 0,
        characterCount: Int? = nil,
        ocrText: String? = nil,
        sensitiveDataTypes: [String]? = nil,
        createdAt: Date = Date()
    ) -> ClipboardItem {
        let item = ClipboardItem(contentType: contentType, textContent: textContent, sourceAppBundleID: sourceAppBundleID)
        item.detectedLanguage = detectedLanguage
        item.useCount = useCount
        item.characterCount = characterCount
        item.ocrText = ocrText
        item.sensitiveDataTypes = sensitiveDataTypes
        item.createdAt = createdAt
        return item
    }

    func testCollectionsNotEmpty() {
        XCTAssertFalse(service.collections.isEmpty)
    }

    func testCodeSnippetsCollection() {
        let collection = service.collections.first { $0.id == "code_snippets" }!
        let codeItem = makeItem(detectedLanguage: "swift")
        let plainItem = makeItem()
        XCTAssertTrue(collection.predicate(codeItem))
        XCTAssertFalse(collection.predicate(plainItem))
    }

    func testURLsCollection() {
        let collection = service.collections.first { $0.id == "urls_links" }!
        let linkItem = makeItem(contentType: .link)
        let textItem = makeItem(contentType: .text)
        XCTAssertTrue(collection.predicate(linkItem))
        XCTAssertFalse(collection.predicate(textItem))
    }

    func testImagesCollection() {
        let collection = service.collections.first { $0.id == "images" }!
        let imageItem = makeItem(contentType: .image, textContent: nil)
        let textItem = makeItem(contentType: .text)
        XCTAssertTrue(collection.predicate(imageItem))
        XCTAssertFalse(collection.predicate(textItem))
    }

    func testFromXcodeCollection() {
        let collection = service.collections.first { $0.id == "from_xcode" }!
        let xcodeItem = makeItem(sourceAppBundleID: "com.apple.dt.Xcode")
        let safariItem = makeItem(sourceAppBundleID: "com.apple.Safari")
        XCTAssertTrue(collection.predicate(xcodeItem))
        XCTAssertFalse(collection.predicate(safariItem))
    }

    func testFromBrowsersCollection() {
        let collection = service.collections.first { $0.id == "from_browsers" }!
        let safariItem = makeItem(sourceAppBundleID: "com.apple.Safari")
        let chromeItem = makeItem(sourceAppBundleID: "com.google.Chrome")
        let xcodeItem = makeItem(sourceAppBundleID: "com.apple.dt.Xcode")
        XCTAssertTrue(collection.predicate(safariItem))
        XCTAssertTrue(collection.predicate(chromeItem))
        XCTAssertFalse(collection.predicate(xcodeItem))
    }

    func testFrequentlyUsedCollection() {
        let collection = service.collections.first { $0.id == "frequently_used" }!
        let frequent = makeItem(useCount: 5)
        let rare = makeItem(useCount: 1)
        XCTAssertTrue(collection.predicate(frequent))
        XCTAssertFalse(collection.predicate(rare))
    }

    func testLongTextCollection() {
        let collection = service.collections.first { $0.id == "long_text" }!
        let longItem = makeItem(characterCount: 600)
        let shortItem = makeItem(characterCount: 50)
        XCTAssertTrue(collection.predicate(longItem))
        XCTAssertFalse(collection.predicate(shortItem))
    }

    func testWithOCRCollection() {
        let collection = service.collections.first { $0.id == "with_ocr" }!
        let ocrItem = makeItem(ocrText: "some extracted text")
        let noOCR = makeItem()
        XCTAssertTrue(collection.predicate(ocrItem))
        XCTAssertFalse(collection.predicate(noOCR))
    }

    func testSensitiveDataCollection() {
        let collection = service.collections.first { $0.id == "sensitive" }!
        let sensitiveItem = makeItem(sensitiveDataTypes: ["apiKey"])
        let normalItem = makeItem()
        XCTAssertTrue(collection.predicate(sensitiveItem))
        XCTAssertFalse(collection.predicate(normalItem))
    }

    func testTodayCollection() {
        let collection = service.collections.first { $0.id == "today" }!
        let todayItem = makeItem(createdAt: Date())
        let oldItem = makeItem(createdAt: Date().addingTimeInterval(-86400 * 5))
        XCTAssertTrue(collection.predicate(todayItem))
        XCTAssertFalse(collection.predicate(oldItem))
    }

    func testFilterMethod() {
        let collection = service.collections.first { $0.id == "urls_links" }!
        let items = [
            makeItem(contentType: .text),
            makeItem(contentType: .link),
            makeItem(contentType: .link),
            makeItem(contentType: .image, textContent: nil),
        ]
        let filtered = service.filter(items, by: collection)
        XCTAssertEqual(filtered.count, 2)
    }

    func testCountsMethod() {
        let items = [
            makeItem(contentType: .link),
            makeItem(contentType: .text, detectedLanguage: "swift"),
        ]
        let counts = service.counts(for: items)
        XCTAssertEqual(counts["urls_links"], 1)
        XCTAssertEqual(counts["code_snippets"], 1)
    }
}
