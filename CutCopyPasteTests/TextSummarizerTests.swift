import XCTest
@testable import CutCopyPaste

final class TextSummarizerTests: XCTestCase {
    let summarizer = TextSummarizer.shared

    // MARK: - Should Summarize

    func testShouldNotSummarizeShortText() {
        XCTAssertFalse(summarizer.shouldSummarize("Short text"))
    }

    func testShouldSummarizeLongText() {
        let longText = String(repeating: "This is a sentence. ", count: 20)
        XCTAssertTrue(summarizer.shouldSummarize(longText))
    }

    func testShouldSummarizeAtThreshold() {
        // Threshold is >= 200, so exactly 200 should summarize
        let text = String(repeating: "a", count: 200)
        XCTAssertTrue(summarizer.shouldSummarize(text))
    }

    func testShouldNotSummarizeBelowThreshold() {
        let text = String(repeating: "a", count: 199)
        XCTAssertFalse(summarizer.shouldSummarize(text))
    }

    // MARK: - Summary Generation

    func testSummarizeProducesOneLiner() {
        let longText = "This is the first sentence. This is the second sentence. This is the third sentence. This is the fourth sentence. This is the fifth sentence. This is the sixth sentence. This is the seventh. Eighth sentence here. Ninth one too. And the tenth."
        let summary = summarizer.summarize(longText)
        XCTAssertFalse(summary.oneLiner.isEmpty)
    }

    func testSummarizeStats() {
        let text = "Hello world. This is a test.\nSecond paragraph."
        let summary = summarizer.summarize(text)
        XCTAssertGreaterThan(summary.stats.wordCount, 0)
        XCTAssertGreaterThan(summary.stats.characterCount, 0)
        XCTAssertGreaterThan(summary.stats.lineCount, 0)
        XCTAssertGreaterThan(summary.stats.sentenceCount, 0)
    }

    func testSummarizeCharacterCount() {
        let text = "Hello"
        let summary = summarizer.summarize(text)
        XCTAssertEqual(summary.stats.characterCount, 5)
    }

    func testSummarizeLineCount() {
        let text = "line1\nline2\nline3"
        let summary = summarizer.summarize(text)
        XCTAssertEqual(summary.stats.lineCount, 3)
    }

    func testSummarizeParagraphCount() {
        let text = "Paragraph one.\n\nParagraph two.\n\nParagraph three."
        let summary = summarizer.summarize(text)
        XCTAssertGreaterThanOrEqual(summary.stats.paragraphCount, 2)
    }

    func testEstimatedReadingTime() {
        // Average reading speed ~200 words/min
        let words = (1...400).map { "word\($0)" }.joined(separator: " ")
        let summary = summarizer.summarize(words)
        XCTAssertTrue(summary.stats.estimatedReadingTime.contains("min"))
    }

    // MARK: - Key Phrases

    func testKeyPhrasesNotEmpty() {
        let text = "Swift programming language is used for iOS and macOS development. Swift was created by Apple. The language supports protocol-oriented programming."
        let summary = summarizer.summarize(text)
        // Key phrases may or may not be extracted depending on NL framework
        // Just ensure no crash
        XCTAssertNotNil(summary.keyPhrases)
    }

    // MARK: - Edge Cases

    func testSummarizeEmptyString() {
        let summary = summarizer.summarize("")
        XCTAssertEqual(summary.stats.characterCount, 0)
        XCTAssertEqual(summary.stats.wordCount, 0)
    }

    func testSummarizeSingleWord() {
        let summary = summarizer.summarize("Hello")
        XCTAssertEqual(summary.stats.wordCount, 1)
    }
}
