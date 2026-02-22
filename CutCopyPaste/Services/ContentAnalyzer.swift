import Foundation

enum ContentSignature: Hashable {
    case plainText
    case json
    case xml
    case curl
    case sql
    case markdown
    case base64
    case urlEncoded
    case hexColor
    case rgbColor
    case url
    case identifier
    case uuid
    case timestamp
    case email
    case phoneNumber
}

struct ContentAnalyzer {
    static func analyze(_ text: String) -> Set<ContentSignature> {
        var signatures: Set<ContentSignature> = [.plainText]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return signatures }

        if isValidJSON(trimmed) { signatures.insert(.json) }
        if looksLikeXML(trimmed) { signatures.insert(.xml) }
        if trimmed.lowercased().hasPrefix("curl ") { signatures.insert(.curl) }
        if looksLikeSQL(trimmed) { signatures.insert(.sql) }
        if looksLikeMarkdown(trimmed) { signatures.insert(.markdown) }
        if isBase64(trimmed) { signatures.insert(.base64) }
        if trimmed.contains("%") && trimmed.removingPercentEncoding != trimmed { signatures.insert(.urlEncoded) }
        if isHexColor(trimmed) { signatures.insert(.hexColor) }
        if trimmed.lowercased().hasPrefix("rgb(") || trimmed.lowercased().hasPrefix("rgba(") { signatures.insert(.rgbColor) }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { signatures.insert(.url) }
        if looksLikeIdentifier(trimmed) { signatures.insert(.identifier) }
        if isUUID(trimmed) { signatures.insert(.uuid) }
        if looksLikeTimestamp(trimmed) { signatures.insert(.timestamp) }
        if containsEmail(trimmed) { signatures.insert(.email) }
        if containsPhoneNumber(trimmed) { signatures.insert(.phoneNumber) }

        return signatures
    }

    // MARK: - Detection Helpers

    private static func isValidJSON(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    private static func looksLikeXML(_ text: String) -> Bool {
        (text.hasPrefix("<?xml") || text.hasPrefix("<")) && text.hasSuffix(">")
            && text.contains("</")
    }

    private static func looksLikeSQL(_ text: String) -> Bool {
        let upper = text.uppercased()
        let keywords = ["SELECT ", "INSERT ", "UPDATE ", "DELETE ", "CREATE TABLE", "ALTER TABLE", "DROP TABLE"]
        return keywords.contains { upper.hasPrefix($0) }
    }

    private static func looksLikeMarkdown(_ text: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        let mdPatterns = ["# ", "## ", "### ", "- ", "* ", "```", "**", "[", "!["]
        let matchCount = lines.prefix(10).filter { line in
            mdPatterns.contains { line.trimmingCharacters(in: .whitespaces).hasPrefix($0) }
        }.count
        return matchCount >= 2
    }

    private static func isBase64(_ text: String) -> Bool {
        guard text.count >= 8, !text.contains(" ") else { return false }
        let base64Chars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+/="))
        return text.unicodeScalars.allSatisfy { base64Chars.contains($0) }
            && Data(base64Encoded: text) != nil
    }

    private static func isHexColor(_ text: String) -> Bool {
        let pattern = "^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"
        return text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func looksLikeIdentifier(_ text: String) -> Bool {
        guard !text.contains(" ") || text.components(separatedBy: .whitespacesAndNewlines).count <= 3 else { return false }
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.contains { word in
            // camelCase: lowercase followed by uppercase
            word.range(of: "[a-z][A-Z]", options: .regularExpression) != nil
            // snake_case
            || word.contains("_")
            // kebab-case (but not sentences with hyphens)
            || (word.range(of: "^[a-z]+-[a-z]+", options: .regularExpression) != nil)
        }
    }

    private static func isUUID(_ text: String) -> Bool {
        UUID(uuidString: text) != nil
    }

    private static func looksLikeTimestamp(_ text: String) -> Bool {
        // Epoch timestamps (10 or 13 digits)
        if text.range(of: "^\\d{10,13}$", options: .regularExpression) != nil { return true }
        // ISO 8601
        if text.range(of: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}", options: .regularExpression) != nil { return true }
        return false
    }

    private static func containsEmail(_ text: String) -> Bool {
        text.range(of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .regularExpression) != nil
    }

    private static func containsPhoneNumber(_ text: String) -> Bool {
        text.range(of: "\\+?\\d[\\d\\s\\-().]{7,}\\d", options: .regularExpression) != nil
    }
}
