import XCTest
@testable import CutCopyPaste

final class TimeGrouperTests: XCTestCase {

    private func makeItem(createdAt: Date, isPinned: Bool = false) -> ClipboardItem {
        let item = ClipboardItem(contentType: .text, textContent: "test")
        item.createdAt = createdAt
        item.isPinned = isPinned
        return item
    }

    func testEmptyItems() {
        let sections = TimeGrouper.group([])
        XCTAssertTrue(sections.isEmpty)
    }

    func testPinnedItemsInOwnSection() {
        let item = makeItem(createdAt: Date(), isPinned: true)
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.title, "Pinned")
        XCTAssertEqual(sections.first?.items.count, 1)
    }

    func testRecentItemsInJustNow() {
        let item = makeItem(createdAt: Date().addingTimeInterval(-60)) // 1 minute ago
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.title, "Just Now")
    }

    func testTodayItems() {
        // Item from 2 hours ago (should be "Today" not "Just Now")
        let item = makeItem(createdAt: Date().addingTimeInterval(-7200))
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.title, "Today")
    }

    func testYesterdayItems() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
            .addingTimeInterval(43200) // noon yesterday
        let item = makeItem(createdAt: yesterday)
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.title, "Yesterday")
    }

    func testOlderItems() {
        let longAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        let item = makeItem(createdAt: longAgo)
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.title, "Earlier")
    }

    func testMixedItemsMultipleSections() {
        let now = makeItem(createdAt: Date())
        let pinned = makeItem(createdAt: Date(), isPinned: true)
        let old = makeItem(createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!)

        let sections = TimeGrouper.group([now, pinned, old])
        let titles = sections.map { $0.title }
        XCTAssertTrue(titles.contains("Pinned"))
        XCTAssertTrue(titles.contains("Just Now"))
        XCTAssertTrue(titles.contains("Earlier"))
    }

    func testSectionIDs() {
        let item = makeItem(createdAt: Date(), isPinned: true)
        let sections = TimeGrouper.group([item])
        XCTAssertEqual(sections.first?.id, "pinned")
    }
}
