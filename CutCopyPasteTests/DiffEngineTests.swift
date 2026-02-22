import XCTest
@testable import CutCopyPaste

final class DiffEngineTests: XCTestCase {
    // MARK: - Basic Diff

    func testIdenticalTexts() {
        let result = DiffEngine.diff(old: "hello", new: "hello")
        XCTAssertEqual(result.unchangedCount, 1)
        XCTAssertEqual(result.addedCount, 0)
        XCTAssertEqual(result.removedCount, 0)
    }

    func testEmptyOld() {
        let result = DiffEngine.diff(old: "", new: "line1\nline2")
        // Empty string splits to [""], so old has 1 "empty" line
        XCTAssertGreaterThanOrEqual(result.addedCount, 1)
    }

    func testEmptyNew() {
        let result = DiffEngine.diff(old: "line1\nline2", new: "")
        // Empty string splits to [""], so new has 1 "empty" line
        XCTAssertGreaterThanOrEqual(result.removedCount, 1)
    }

    func testBothEmpty() {
        let result = DiffEngine.diff(old: "", new: "")
        // Empty string splits to [""], producing 1 unchanged empty line
        XCTAssertEqual(result.unchangedCount, 1)
        XCTAssertEqual(result.addedCount, 0)
        XCTAssertEqual(result.removedCount, 0)
    }

    func testSingleLineChange() {
        let result = DiffEngine.diff(old: "hello", new: "world")
        XCTAssertEqual(result.removedCount, 1)
        XCTAssertEqual(result.addedCount, 1)
    }

    func testMultiLineWithAdditions() {
        let old = "line1\nline2\nline3"
        let new = "line1\nline2\nline2.5\nline3"
        let result = DiffEngine.diff(old: old, new: new)
        XCTAssertEqual(result.addedCount, 1)
        XCTAssertEqual(result.unchangedCount, 3)
        XCTAssertEqual(result.removedCount, 0)
    }

    func testMultiLineWithDeletions() {
        let old = "line1\nline2\nline3"
        let new = "line1\nline3"
        let result = DiffEngine.diff(old: old, new: new)
        XCTAssertEqual(result.removedCount, 1)
        XCTAssertEqual(result.unchangedCount, 2)
    }

    func testMultiLineWithModifications() {
        let old = "func hello() {\n    print(\"hello\")\n}"
        let new = "func hello() {\n    print(\"world\")\n}"
        let result = DiffEngine.diff(old: old, new: new)
        XCTAssertEqual(result.unchangedCount, 2) // first and last lines
        XCTAssertEqual(result.removedCount, 1)
        XCTAssertEqual(result.addedCount, 1)
    }

    func testDiffLineNumbers() {
        let old = "a\nb\nc"
        let new = "a\nc"
        let result = DiffEngine.diff(old: old, new: new)
        let unchanged = result.lines.filter { $0.type == .unchanged }
        XCTAssertEqual(unchanged.count, 2)

        let removed = result.lines.filter { $0.type == .removed }
        XCTAssertEqual(removed.count, 1)
        XCTAssertEqual(removed.first?.content, "b")
        XCTAssertEqual(removed.first?.leftLineNumber, 2)
    }

    // MARK: - Inline Diff

    func testInlineDiffIdentical() {
        let result = DiffEngine.inlineDiff(oldLine: "hello", newLine: "hello")
        XCTAssertEqual(result.old.count, 1)
        XCTAssertEqual(result.old.first?.0, "hello")
        XCTAssertEqual(result.old.first?.1, false)
    }

    func testInlineDiffSingleCharChange() {
        let result = DiffEngine.inlineDiff(oldLine: "cat", newLine: "car")
        // Should identify the changed character
        let oldChanged = result.old.filter { $0.1 }
        let newChanged = result.new.filter { $0.1 }
        XCTAssertFalse(oldChanged.isEmpty)
        XCTAssertFalse(newChanged.isEmpty)
    }

    func testInlineDiffCompletelyDifferent() {
        let result = DiffEngine.inlineDiff(oldLine: "abc", newLine: "xyz")
        let oldChanged = result.old.filter { $0.1 }
        XCTAssertFalse(oldChanged.isEmpty)
    }

    func testInlineDiffPartialOverlap() {
        let result = DiffEngine.inlineDiff(oldLine: "hello world", newLine: "hello earth")
        // "hello " should be unchanged, "world" vs "earth" changed
        let oldUnchanged = result.old.filter { !$0.1 }.map { $0.0 }.joined()
        XCTAssertTrue(oldUnchanged.contains("hello"))
    }

    // MARK: - DiffLineType

    func testDiffLineTypeValues() {
        XCTAssertNotNil(DiffLineType.unchanged)
        XCTAssertNotNil(DiffLineType.added)
        XCTAssertNotNil(DiffLineType.removed)
    }

    // MARK: - Large Input

    func testLargeIdenticalInput() {
        let lines = (1...100).map { "line \($0)" }.joined(separator: "\n")
        let result = DiffEngine.diff(old: lines, new: lines)
        XCTAssertEqual(result.unchangedCount, 100)
        XCTAssertEqual(result.addedCount, 0)
        XCTAssertEqual(result.removedCount, 0)
    }

    func testCompleteReplacement() {
        let old = "a\nb\nc"
        let new = "x\ny\nz"
        let result = DiffEngine.diff(old: old, new: new)
        XCTAssertEqual(result.removedCount, 3)
        XCTAssertEqual(result.addedCount, 3)
        XCTAssertEqual(result.unchangedCount, 0)
    }
}
