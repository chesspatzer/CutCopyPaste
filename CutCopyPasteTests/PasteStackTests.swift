import XCTest
@testable import CutCopyPaste

@MainActor
final class PasteStackTests: XCTestCase {
    // MARK: - Activation

    func testInitialState() {
        let manager = PasteStackManager()
        XCTAssertFalse(manager.isActive)
        XCTAssertTrue(manager.isEmpty)
        XCTAssertEqual(manager.depth, 0)
    }

    func testActivate() {
        let manager = PasteStackManager()
        manager.activate()
        XCTAssertTrue(manager.isActive)
        XCTAssertTrue(manager.isEmpty)
    }

    func testDeactivate() {
        let manager = PasteStackManager()
        manager.activate()
        manager.push(textContent: "test", contentType: .text)
        manager.deactivate()
        XCTAssertFalse(manager.isActive)
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - Push

    func testPush() {
        let manager = PasteStackManager()
        manager.activate()
        manager.push(textContent: "hello", contentType: .text)
        XCTAssertEqual(manager.depth, 1)
        XCTAssertFalse(manager.isEmpty)
    }

    func testPushMultiple() {
        let manager = PasteStackManager()
        manager.activate()
        manager.push(textContent: "first", contentType: .text)
        manager.push(textContent: "second", contentType: .text)
        manager.push(textContent: "third", contentType: .text)
        XCTAssertEqual(manager.depth, 3)
    }

    func testPushPreviewTruncation() {
        let manager = PasteStackManager()
        let longText = String(repeating: "a", count: 200)
        manager.push(textContent: longText, contentType: .text)
        XCTAssertEqual(manager.items.first?.preview.count, 80)
    }

    func testPushImageItem() {
        let manager = PasteStackManager()
        manager.push(textContent: nil, contentType: .image)
        XCTAssertEqual(manager.items.first?.preview, "Image")
    }

    // MARK: - Queue Mode (FIFO)

    func testQueueMode() {
        let manager = PasteStackManager()
        manager.pasteMode = .queue
        manager.push(textContent: "first", contentType: .text)
        manager.push(textContent: "second", contentType: .text)
        manager.push(textContent: "third", contentType: .text)

        let item1 = manager.pasteNext()
        XCTAssertEqual(item1?.textContent, "first")
        let item2 = manager.pasteNext()
        XCTAssertEqual(item2?.textContent, "second")
        let item3 = manager.pasteNext()
        XCTAssertEqual(item3?.textContent, "third")
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - Stack Mode (LIFO)

    func testStackMode() {
        let manager = PasteStackManager()
        manager.pasteMode = .stack
        manager.push(textContent: "first", contentType: .text)
        manager.push(textContent: "second", contentType: .text)
        manager.push(textContent: "third", contentType: .text)

        let item1 = manager.pasteNext()
        XCTAssertEqual(item1?.textContent, "third")
        let item2 = manager.pasteNext()
        XCTAssertEqual(item2?.textContent, "second")
        let item3 = manager.pasteNext()
        XCTAssertEqual(item3?.textContent, "first")
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - Paste From Empty

    func testPasteFromEmpty() {
        let manager = PasteStackManager()
        let item = manager.pasteNext()
        XCTAssertNil(item)
    }

    // MARK: - Clear Stack

    func testClearStack() {
        let manager = PasteStackManager()
        manager.push(textContent: "a", contentType: .text)
        manager.push(textContent: "b", contentType: .text)
        XCTAssertEqual(manager.depth, 2)
        manager.clearStack()
        XCTAssertTrue(manager.isEmpty)
    }

    // MARK: - Toggle Mode

    func testToggleMode() {
        let manager = PasteStackManager()
        manager.pasteMode = .queue
        manager.toggleMode()
        XCTAssertEqual(manager.pasteMode, .stack)
        manager.toggleMode()
        XCTAssertEqual(manager.pasteMode, .queue)
    }

    // MARK: - Mode Display Names

    func testModeDisplayNames() {
        XCTAssertTrue(PasteStackManager.PasteMode.stack.displayName.contains("LIFO"))
        XCTAssertTrue(PasteStackManager.PasteMode.queue.displayName.contains("FIFO"))
    }
}
