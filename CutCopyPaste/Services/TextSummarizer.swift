import Foundation
import NaturalLanguage

struct TextSummary {
    let oneLiner: String
    let keyPhrases: [String]
    let stats: TextStats
}

struct TextStats {
    let characterCount: Int
    let wordCount: Int
    let lineCount: Int
    let sentenceCount: Int
    let paragraphCount: Int
    let estimatedReadingTime: String
}

final class TextSummarizer {
    static let shared = TextSummarizer()

    let summaryThreshold = 200

    func summarize(_ text: String) -> TextSummary {
        let stats = computeStats(text)
        let oneLiner = extractFirstSentence(text)
        let keyPhrases = extractKeyPhrases(text)

        return TextSummary(
            oneLiner: oneLiner,
            keyPhrases: keyPhrases,
            stats: stats
        )
    }

    func shouldSummarize(_ text: String) -> Bool {
        text.count >= summaryThreshold
    }

    private func computeStats(_ text: String) -> TextStats {
        let charCount = text.count
        let words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        let lines = text.components(separatedBy: .newlines)
        let paragraphs = text.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        let sentenceRanges = tokenizer.tokens(for: text.startIndex..<text.endIndex)

        let readingMinutes = max(1, words.count / 200)

        return TextStats(
            characterCount: charCount,
            wordCount: words.count,
            lineCount: lines.count,
            sentenceCount: sentenceRanges.count,
            paragraphCount: paragraphs.count,
            estimatedReadingTime: "\(readingMinutes) min read"
        )
    }

    private func extractFirstSentence(_ text: String) -> String {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        let ranges = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        if let firstRange = ranges.first {
            let sentence = String(text[firstRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if sentence.count > 120 {
                return String(sentence.prefix(117)) + "..."
            }
            return sentence
        }
        return String(text.prefix(120))
    }

    private func extractKeyPhrases(_ text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var nounFrequency: [String: Int] = [:]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range]).lowercased()
                if word.count > 2 {
                    nounFrequency[word, default: 0] += 1
                }
            }
            return true
        }

        return nounFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
    }
}
