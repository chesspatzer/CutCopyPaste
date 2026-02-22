import Foundation

struct StripLineNumbersTransform: ClipboardTransform {
    let id = "strip_line_numbers"
    let name = "Strip Line Numbers"
    let description = "Remove leading line numbers from code"
    let iconSystemName = "list.number"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard lines.count >= 3 else { return false }
        let numberedCount = lines.prefix(5).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.range(of: "^\\d+[\\s.:;|\\-]+", options: .regularExpression) != nil
        }.count
        return numberedCount >= 3
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let lines = text.components(separatedBy: .newlines)
        let cleaned = lines.map { line in
            line.replacingOccurrences(
                of: "^\\s*\\d+[\\s.:;|\\-]+",
                with: "",
                options: .regularExpression
            )
        }
        return .success(cleaned.joined(separator: "\n"))
    }
}

struct NormalizeWhitespaceTransform: ClipboardTransform {
    let id = "normalize_whitespace"
    let name = "Normalize Whitespace"
    let description = "Trim trailing whitespace and normalize line endings"
    let iconSystemName = "text.alignleft"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        text.contains("\r") || text.contains(" \n") || text.contains("\t\n")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
        let trimmed = lines.map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
        return .success(trimmed.joined(separator: "\n"))
    }
}

struct SortLinesTransform: ClipboardTransform {
    let id = "sort_lines"
    let name = "Sort Lines"
    let description = "Sort all lines alphabetically"
    let iconSystemName = "arrow.up.arrow.down"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        text.components(separatedBy: .newlines).count >= 2
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let lines = text.components(separatedBy: .newlines)
        let sorted = lines.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return .success(sorted.joined(separator: "\n"))
    }
}

struct RemoveDuplicateLinesTransform: ClipboardTransform {
    let id = "remove_duplicate_lines"
    let name = "Remove Duplicate Lines"
    let description = "Remove duplicate lines while preserving order"
    let iconSystemName = "minus.circle"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        return Set(lines).count < lines.count
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let lines = text.components(separatedBy: .newlines)
        var seen = Set<String>()
        var unique: [String] = []
        for line in lines {
            if seen.insert(line).inserted {
                unique.append(line)
            }
        }
        return .success(unique.joined(separator: "\n"))
    }
}
