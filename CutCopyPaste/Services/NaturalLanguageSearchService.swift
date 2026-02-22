import Foundation

struct SearchIntent {
    var textQuery: String?
    var contentTypeFilter: ClipboardItemType?
    var dateRange: (start: Date, end: Date)?
    var sourceAppFilter: String?
    var isFuzzy: Bool = true
}

final class NaturalLanguageSearchService {
    static let shared = NaturalLanguageSearchService()

    // MARK: - Synonym Dictionary

    private static let synonyms: [String: [String]] = [
        "function":  ["func", "method", "def", "fn", "procedure", "subroutine"],
        "variable":  ["var", "let", "const", "val"],
        "class":     ["struct", "type", "interface", "protocol", "object"],
        "import":    ["include", "require", "using", "use"],
        "array":     ["list", "slice", "vector", "collection"],
        "string":    ["str", "text", "varchar", "char"],
        "error":     ["exception", "fault", "bug", "issue", "err"],
        "image":     ["photo", "picture", "screenshot", "pic", "img"],
        "link":      ["url", "href", "uri", "address", "website"],
        "file":      ["document", "doc", "attachment"],
        "database":  ["db", "sql", "table", "schema"],
        "api":       ["endpoint", "route", "rest", "graphql"],
        "config":    ["configuration", "settings", "preferences", "env"],
    ]

    // MARK: - Intent Parsing

    func parseIntent(from query: String) -> SearchIntent {
        var intent = SearchIntent()
        var remaining = query.lowercased()

        // Content type detection
        let typePatterns: [(String, ClipboardItemType)] = [
            ("(?:show|find|get)\\s+(?:me\\s+)?(?:all\\s+)?images?|photos?|pictures?|screenshots?", .image),
            ("(?:show|find|get)\\s+(?:me\\s+)?(?:all\\s+)?(?:urls?|links?|websites?)", .link),
            ("(?:show|find|get)\\s+(?:me\\s+)?(?:all\\s+)?(?:files?|documents?)", .file),
            ("(?:show|find|get)\\s+(?:me\\s+)?(?:all\\s+)?(?:text|snippets?|code)", .text),
        ]

        for (pattern, type) in typePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)),
               let range = Range(match.range, in: remaining) {
                intent.contentTypeFilter = type
                remaining = remaining.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Source app detection
        let appPattern = "(?:from|in|via)\\s+(\\w+)"
        if let regex = try? NSRegularExpression(pattern: appPattern),
           let match = regex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)),
           let fullRange = Range(match.range, in: remaining),
           let appRange = Range(match.range(at: 1), in: remaining) {
            intent.sourceAppFilter = String(remaining[appRange])
            remaining = remaining.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
        }

        // Date range detection
        let now = Date()
        let calendar = Calendar.current
        let datePatterns: [(String, () -> (Date, Date)?)] = [
            ("today", {
                let start = calendar.startOfDay(for: now)
                return (start, now)
            }),
            ("yesterday", {
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
                let start = calendar.startOfDay(for: yesterday)
                let end = calendar.startOfDay(for: now)
                return (start, end)
            }),
            ("(?:this|last)\\s+week", {
                guard let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return nil }
                return (weekAgo, now)
            }),
            ("last\\s+month", {
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
                return (monthAgo, now)
            }),
            ("(\\d+)\\s+(?:days?|hours?|minutes?)\\s+ago", {
                nil // Handled separately below
            }),
        ]

        for (pattern, resolver) in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)),
               let fullRange = Range(match.range, in: remaining) {
                if let range = resolver() {
                    intent.dateRange = range
                }
                remaining = remaining.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
                break
            }
        }

        // Relative time: "N days/hours/minutes ago"
        if intent.dateRange == nil {
            let relPattern = "(\\d+)\\s+(days?|hours?|minutes?)\\s+ago"
            if let regex = try? NSRegularExpression(pattern: relPattern),
               let match = regex.firstMatch(in: remaining, range: NSRange(remaining.startIndex..., in: remaining)),
               let fullRange = Range(match.range, in: remaining),
               let numRange = Range(match.range(at: 1), in: remaining),
               let unitRange = Range(match.range(at: 2), in: remaining),
               let num = Int(remaining[numRange]) {
                let unit = String(remaining[unitRange])
                let component: Calendar.Component
                if unit.hasPrefix("day") { component = .day }
                else if unit.hasPrefix("hour") { component = .hour }
                else { component = .minute }
                if let past = calendar.date(byAdding: component, value: -num, to: now) {
                    intent.dateRange = (past, now)
                }
                remaining = remaining.replacingCharacters(in: fullRange, with: "").trimmingCharacters(in: .whitespaces)
            }
        }

        // Remaining text becomes the fuzzy text query
        let cleaned = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.isEmpty {
            intent.textQuery = cleaned
        }

        return intent
    }

    // MARK: - Fuzzy Matching

    func fuzzyScore(query: String, against text: String) -> Double {
        let q = query.lowercased()
        let t = text.lowercased()

        // Exact match
        if t.contains(q) { return 1.0 }

        // Synonym expansion
        let expandedTerms = expandWithSynonyms(q)
        for term in expandedTerms {
            if t.contains(term) { return 0.9 }
        }

        // Bigram similarity
        return bigramSimilarity(q, t)
    }

    func bigramSimilarity(_ a: String, _ b: String) -> Double {
        guard a.count >= 2 && b.count >= 2 else { return 0 }
        let aBigrams = Set(zip(a, a.dropFirst()).map { String([$0, $1]) })
        let bBigrams = Set(zip(b, b.dropFirst()).map { String([$0, $1]) })
        let intersection = aBigrams.intersection(bBigrams).count
        guard aBigrams.count + bBigrams.count > 0 else { return 0 }
        return Double(2 * intersection) / Double(aBigrams.count + bBigrams.count)
    }

    private func expandWithSynonyms(_ query: String) -> [String] {
        var terms: [String] = []
        let words = query.components(separatedBy: .whitespaces)
        for word in words {
            // Check if word is a key in synonyms
            if let syns = Self.synonyms[word] {
                terms.append(contentsOf: syns)
            }
            // Check if word is a synonym value
            for (key, values) in Self.synonyms {
                if values.contains(word) {
                    terms.append(key)
                    terms.append(contentsOf: values.filter { $0 != word })
                }
            }
        }
        return terms
    }
}
