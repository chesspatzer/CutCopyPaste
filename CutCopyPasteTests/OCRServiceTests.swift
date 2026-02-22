import XCTest
@testable import CutCopyPaste

final class OCRServiceTests: XCTestCase {
    let service = OCRService.shared

    // Helper to create RecognizedLine with vertical position
    // y decreases as we go down the page (normalized coords: top = 1.0, bottom = 0.0)
    private func line(_ text: String, confidence: Float = 0.9, y: CGFloat, height: CGFloat = 0.03) -> OCRService.RecognizedLine {
        OCRService.RecognizedLine(
            text: text,
            confidence: confidence,
            boundingBox: CGRect(x: 0.05, y: y, width: 0.9, height: height)
        )
    }

    // Simple helper for tests that don't care about spatial layout
    private func flatLines(_ items: [(String, Float)]) -> [OCRService.RecognizedLine] {
        var y: CGFloat = 0.95
        return items.map { text, conf in
            let l = line(text, confidence: conf, y: y)
            y -= 0.04
            return l
        }
    }

    private func cleanUp(_ lines: [OCRService.RecognizedLine]) async -> String {
        await service.cleanUpOCRText(lines)
    }

    // MARK: - Confidence Filtering

    func testFiltersLowConfidenceLines() async {
        let lines = flatLines([
            ("Hello world", 0.95),
            ("garbled nonsense", 0.1),
            ("Good text", 0.8),
        ])
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("Hello world"))
        XCTAssertTrue(result.contains("Good text"))
        XCTAssertFalse(result.contains("garbled nonsense"))
    }

    func testKeepsLinesAtExactThreshold() async {
        let lines = flatLines([("Borderline", 0.3)])
        let result = await cleanUp(lines)
        XCTAssertEqual(result, "Borderline")
    }

    func testFiltersAllLowConfidence() async {
        let lines = flatLines([("bad1", 0.1), ("bad2", 0.2)])
        let result = await cleanUp(lines)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Whitespace Normalization

    func testCollapsesMultipleSpaces() async {
        let lines = flatLines([("Hello    world   here", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertEqual(result, "Hello world here")
    }

    func testTrimsTrailingWhitespace() async {
        let lines = flatLines([("  Hello world  ", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertEqual(result, "Hello world")
    }

    // MARK: - Stray Character Removal

    func testRemovesSingleStrayPunctuation() async {
        let lines = flatLines([("Hello", 0.9), ("|", 0.9), ("World", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("Hello"))
        XCTAssertTrue(result.contains("World"))
        XCTAssertFalse(result.components(separatedBy: "\n").contains("|"))
    }

    func testRemovesDoubleStrayPunctuation() async {
        let lines = flatLines([("//", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertTrue(result.isEmpty)
    }

    func testKeepsSingleLetters() async {
        let lines = flatLines([("A", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertEqual(result, "A")
    }

    func testKeepsSingleDigits() async {
        let lines = flatLines([("7", 0.9)])
        let result = await cleanUp(lines)
        XCTAssertEqual(result, "7")
    }

    // MARK: - Consecutive Duplicate Removal

    func testRemovesConsecutiveDuplicates() async {
        let lines = flatLines([("Same line", 0.9), ("Same line", 0.85), ("Different line", 0.9)])
        let result = await cleanUp(lines)
        let occurrences = result.components(separatedBy: "Same line").count - 1
        XCTAssertEqual(occurrences, 1)
        XCTAssertTrue(result.contains("Different line"))
    }

    func testKeepsNonConsecutiveDuplicates() async {
        let lines = flatLines([("Repeated", 0.9), ("Middle", 0.9), ("Repeated", 0.9)])
        let result = await cleanUp(lines)
        let occurrences = result.components(separatedBy: "Repeated").count - 1
        XCTAssertEqual(occurrences, 2)
    }

    // MARK: - Spatial Line Spacing

    func testNormalSpacingJoinsWrappedText() async {
        // Lines close together vertically (gap < 0.8 * height) — should join wrapped text
        let lines = [
            line("This is the beginning of a", y: 0.90),
            line("sentence that was split", y: 0.87),
            line("across multiple lines.", y: 0.84),
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("beginning of a sentence that was split across multiple lines."))
    }

    func testLargeGapInsertsParagraphBreak() async {
        // Large vertical gap between groups — should get blank line
        let lines = [
            line("First paragraph content here.", y: 0.90),
            line("Second paragraph starts here.", y: 0.80),  // gap of ~0.07, much larger than height 0.03
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("\n\n"), "Large gap should produce paragraph break")
        XCTAssertTrue(result.contains("First paragraph"))
        XCTAssertTrue(result.contains("Second paragraph"))
    }

    func testTightLinesNoExtraSpacing() async {
        // Lines directly adjacent — code-like, should be newline-separated
        let lines = [
            line("func hello() {", y: 0.90),
            line("print(\"hi\")", y: 0.87),
            line("}", y: 0.84),
        ]
        let result = await cleanUp(lines)
        // Code lines should be kept separate, not joined
        XCTAssertTrue(result.contains("func hello()"))
        XCTAssertTrue(result.contains("print"))
        XCTAssertTrue(result.contains("}"))
    }

    func testMixedParagraphsWithGaps() async {
        // Two paragraphs with visible gap, lines within each are tight
        let lines = [
            line("The quick brown fox jumps", y: 0.92),
            line("over the lazy dog.", y: 0.89),
            // gap
            line("Pack my box with five", y: 0.78),
            line("dozen liquor jugs.", y: 0.75),
        ]
        let result = await cleanUp(lines)
        // Should have two paragraphs separated by blank line
        XCTAssertTrue(result.contains("fox jumps over the lazy dog."))
        XCTAssertTrue(result.contains("box with five dozen liquor jugs."))
        XCTAssertTrue(result.contains("\n\n"))
    }

    // MARK: - Block Structure Preservation

    func testPreservesBulletPoints() async {
        let lines = [
            line("Shopping list:", y: 0.90),
            line("• Apples", y: 0.87),
            line("• Bananas", y: 0.84),
            line("• Cherries", y: 0.81),
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("• Apples"))
        XCTAssertTrue(result.contains("• Bananas"))
        XCTAssertTrue(result.contains("• Cherries"))
    }

    func testPreservesDashListItems() async {
        let lines = [
            line("- First item", y: 0.90),
            line("- Second item", y: 0.87),
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("- First item"))
        XCTAssertTrue(result.contains("- Second item"))
    }

    func testPreservesNumberedList() async {
        let lines = [
            line("1. First step", y: 0.90),
            line("2. Second step", y: 0.87),
            line("3. Third step", y: 0.84),
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("1. First step"))
        XCTAssertTrue(result.contains("2. Second step"))
        XCTAssertTrue(result.contains("3. Third step"))
    }

    // MARK: - Blank Line Collapsing

    func testCollapsesExcessiveBlankLines() async {
        // Simulate multiple large gaps that would each insert \n\n
        let lines = [
            line("First", y: 0.95),
            line("Second", y: 0.50),  // huge gap
        ]
        let result = await cleanUp(lines)
        XCTAssertFalse(result.contains("\n\n\n"), "Should never have triple newlines")
    }

    // MARK: - End-to-End

    func testRealisticScreenshotOCR() async {
        let lines = [
            line("func viewDidLoad() {", confidence: 0.92, y: 0.90),
            line("super.viewDidLoad()", confidence: 0.88, y: 0.87),
            line("super.viewDidLoad()", confidence: 0.15, y: 0.865),  // low confidence duplicate
            line("// Setup UI", confidence: 0.90, y: 0.84),
            line("|", confidence: 0.4, y: 0.83),                      // stray pipe
            line("setupNavigationBar()", confidence: 0.87, y: 0.81),
            line("}", confidence: 0.5, y: 0.78),
        ]
        let result = await cleanUp(lines)
        XCTAssertTrue(result.contains("func viewDidLoad()"))
        XCTAssertTrue(result.contains("super.viewDidLoad()"))
        XCTAssertTrue(result.contains("setupNavigationBar()"))
        let superCount = result.components(separatedBy: "super.viewDidLoad()").count - 1
        XCTAssertEqual(superCount, 1)
    }

    func testRealisticArticleOCR() async {
        // Simulates a blog post / article screenshot
        let lines = [
            line("GETTING STARTED WITH SWIFT", confidence: 0.95, y: 0.92, height: 0.04),  // heading
            // gap after heading
            line("Swift is a powerful and intuitive", confidence: 0.91, y: 0.82),
            line("programming language for macOS, iOS,", confidence: 0.89, y: 0.79),
            line("watchOS, and tvOS.", confidence: 0.90, y: 0.76),
            // paragraph gap
            line("It was designed to give developers", confidence: 0.88, y: 0.66),
            line("more freedom than ever before.", confidence: 0.87, y: 0.63),
        ]
        let result = await cleanUp(lines)
        // Heading should be separate from first paragraph
        XCTAssertTrue(result.hasPrefix("GETTING STARTED WITH SWIFT"))
        // Wrapped lines within paragraphs should be joined
        XCTAssertTrue(result.contains("intuitive programming language"))
        XCTAssertTrue(result.contains("developers more freedom"))
        // Paragraph break between the two body paragraphs
        let paragraphs = result.components(separatedBy: "\n\n")
        XCTAssertGreaterThanOrEqual(paragraphs.count, 2)
    }

    func testEmptyInput() async {
        let result = await cleanUp([])
        XCTAssertTrue(result.isEmpty)
    }

    func testSingleHighConfidenceLine() async {
        let result = await cleanUp([line("Just one line", confidence: 0.95, y: 0.90)])
        XCTAssertEqual(result, "Just one line")
    }

    // MARK: - Vertical Sorting

    func testSortsLinesByVerticalPosition() async {
        // Lines given out of order — should be sorted top to bottom
        let lines = [
            line("Third line", y: 0.80),
            line("First line", y: 0.92),
            line("Second line", y: 0.86),
        ]
        let result = await cleanUp(lines)
        let resultLines = result.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard resultLines.count >= 3 else {
            // Lines may have been joined — just check order
            XCTAssertTrue(result.contains("First"))
            XCTAssertTrue(result.contains("Second"))
            XCTAssertTrue(result.contains("Third"))
            let firstIdx = result.range(of: "First")!.lowerBound
            let secondIdx = result.range(of: "Second")!.lowerBound
            let thirdIdx = result.range(of: "Third")!.lowerBound
            XCTAssertTrue(firstIdx < secondIdx)
            XCTAssertTrue(secondIdx < thirdIdx)
            return
        }
        XCTAssertTrue(resultLines[0].contains("First"))
        XCTAssertTrue(resultLines[1].contains("Second"))
        XCTAssertTrue(resultLines[2].contains("Third"))
    }
}
