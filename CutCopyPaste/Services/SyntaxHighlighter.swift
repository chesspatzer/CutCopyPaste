import AppKit
import SwiftUI

/// Detects programming languages and produces syntax-highlighted AttributedStrings.
/// Works entirely offline using regex-based tokenization.
final class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()
    private init() {}

    // MARK: - Caches

    /// Cache compiled NSRegularExpression objects to avoid recompiling on every call
    private var regexCache: [String: NSRegularExpression] = [:]

    /// LRU cache for highlight output — keyed by (text hash, language, isDark)
    private var highlightCache = OrderedCache<HighlightCacheKey, NSAttributedString>(capacity: 30)

    private struct HighlightCacheKey: Hashable {
        let textHash: Int
        let language: String
        let isDark: Bool
    }

    private func cachedRegex(_ pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        let key = "\(pattern)|\(options.rawValue)"
        if let cached = regexCache[key] { return cached }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        regexCache[key] = regex
        return regex
    }

    // MARK: - Language Detection

    struct LanguagePattern {
        let name: String
        let keywords: Set<String>
        let patterns: [String] // regex patterns unique to this language
    }

    private let languages: [LanguagePattern] = [
        LanguagePattern(
            name: "swift",
            keywords: ["func", "var", "let", "struct", "class", "enum", "protocol", "import", "guard", "if let", "@Published", "@State", "@ObservedObject", "@MainActor", "typealias", "extension", "where", "associatedtype", "some View"],
            patterns: ["\\bfunc\\s+\\w+\\s*\\(", "\\bvar\\s+\\w+\\s*:", "\\blet\\s+\\w+\\s*[=:]", "@\\w+\\s+(var|let|func|class|struct)", "\\bguard\\s+let\\b"]
        ),
        LanguagePattern(
            name: "python",
            keywords: ["def", "class", "import", "from", "if", "elif", "else", "for", "while", "return", "yield", "lambda", "with", "as", "try", "except", "raise", "pass", "self", "__init__", "print"],
            patterns: ["\\bdef\\s+\\w+\\s*\\(", "\\bclass\\s+\\w+[:\\(]", "\\bimport\\s+\\w+", "\\bfrom\\s+\\w+\\s+import\\b", "\\belif\\b", "\\bself\\.\\w+"]
        ),
        LanguagePattern(
            name: "javascript",
            keywords: ["function", "const", "let", "var", "return", "if", "else", "for", "while", "class", "extends", "import", "export", "default", "async", "await", "new", "this", "=>", "require", "module.exports", "console.log"],
            patterns: ["\\bconst\\s+\\w+\\s*=", "\\bfunction\\s+\\w+\\s*\\(", "=>\\s*\\{?", "\\bconsole\\.(log|warn|error)\\(", "\\brequire\\s*\\(", "\\bmodule\\.exports\\b"]
        ),
        LanguagePattern(
            name: "typescript",
            keywords: ["interface", "type", "enum", "namespace", "readonly", "implements", "declare", "keyof", "typeof", "as", "is", "abstract"],
            patterns: ["\\binterface\\s+\\w+", "\\btype\\s+\\w+\\s*=", ":\\s*(string|number|boolean|void|any|never|unknown)\\b", "\\b\\w+\\s*<\\w+>"]
        ),
        LanguagePattern(
            name: "go",
            keywords: ["func", "package", "import", "type", "struct", "interface", "map", "chan", "go", "defer", "range", "select", "goroutine", "make", "append", "fmt"],
            patterns: ["\\bpackage\\s+\\w+", "\\bfunc\\s+\\(\\w+\\s+\\*?\\w+\\)", "\\bfunc\\s+\\w+\\(", ":=\\s*", "\\bgo\\s+\\w+", "\\bdefer\\s+"]
        ),
        LanguagePattern(
            name: "rust",
            keywords: ["fn", "let", "mut", "pub", "struct", "enum", "impl", "trait", "use", "mod", "match", "self", "Self", "crate", "Box", "Vec", "Option", "Result", "unwrap"],
            patterns: ["\\bfn\\s+\\w+\\s*\\(", "\\blet\\s+mut\\s+", "\\bimpl\\s+\\w+", "\\bpub\\s+(fn|struct|enum|trait)", "\\b->\\s*\\w+", "#\\[\\w+"]
        ),
        LanguagePattern(
            name: "java",
            keywords: ["public", "private", "protected", "static", "void", "class", "interface", "extends", "implements", "new", "return", "import", "package", "final", "abstract", "throws", "try", "catch", "synchronized"],
            patterns: ["\\bpublic\\s+(static\\s+)?\\w+\\s+\\w+\\s*\\(", "\\bclass\\s+\\w+\\s+(extends|implements)\\s+\\w+", "System\\.out\\.print", "\\bpackage\\s+[\\w.]+;"]
        ),
        LanguagePattern(
            name: "html",
            keywords: ["<html", "<head", "<body", "<div", "<span", "<p>", "<a ", "<img", "<script", "<style", "<link", "<!DOCTYPE", "<form", "<input", "<button"],
            patterns: ["<\\w+[\\s>]", "</\\w+>", "<!DOCTYPE\\s+html", "<[a-z]+\\s+[a-z]+="]
        ),
        LanguagePattern(
            name: "css",
            keywords: ["color:", "background:", "margin:", "padding:", "display:", "position:", "font-size:", "border:", "width:", "height:", "@media", "@import", "@keyframes"],
            patterns: ["\\{[^}]*\\b(color|margin|padding|display|font-size|background)\\s*:", "\\.\\w+\\s*\\{", "#\\w+\\s*\\{", "@media\\s*\\("]
        ),
        LanguagePattern(
            name: "sql",
            keywords: ["SELECT", "FROM", "WHERE", "INSERT", "UPDATE", "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "JOIN", "ON", "GROUP BY", "ORDER BY", "HAVING", "UNION", "INDEX"],
            patterns: ["\\bSELECT\\s+.+\\s+FROM\\b", "\\bCREATE\\s+TABLE\\b", "\\bINSERT\\s+INTO\\b", "\\bALTER\\s+TABLE\\b"]
        ),
        LanguagePattern(
            name: "shell",
            keywords: ["echo", "export", "source", "alias", "if", "then", "fi", "else", "elif", "for", "do", "done", "while", "case", "esac", "function", "chmod", "chown", "grep", "awk", "sed"],
            patterns: ["^#!/bin/(ba)?sh", "\\$\\{?\\w+\\}?", "\\becho\\s+", "\\bexport\\s+\\w+=", "\\|\\s*grep\\b", "\\bif\\s+\\["]
        ),
        LanguagePattern(
            name: "json",
            keywords: [],
            patterns: ["^\\s*\\{\\s*\"", "\"\\w+\"\\s*:\\s*[\"\\d\\[\\{tfn]"]
        ),
        LanguagePattern(
            name: "yaml",
            keywords: [],
            patterns: ["^\\w+:\\s*$", "^\\s+-\\s+\\w+", "^---\\s*$", "^\\w+:\\s+[\"']?\\w+"]
        ),
        LanguagePattern(
            name: "xml",
            keywords: [],
            patterns: ["^<\\?xml\\s+", "<\\w+[\\s>].*</\\w+>", "<\\w+\\s+\\w+=\"[^\"]*\""]
        ),
        LanguagePattern(
            name: "ruby",
            keywords: ["def", "end", "class", "module", "require", "include", "attr_accessor", "attr_reader", "puts", "nil", "do", "yield", "block", "proc", "lambda"],
            patterns: ["\\bdef\\s+\\w+", "\\bclass\\s+\\w+\\s*<\\s*\\w+", "\\brequire\\s+['\"]", "\\battr_(accessor|reader|writer)\\s+:", "\\bdo\\s*\\|\\w+\\|"]
        ),
        LanguagePattern(
            name: "c",
            keywords: ["#include", "#define", "int", "void", "char", "float", "double", "struct", "typedef", "sizeof", "malloc", "free", "printf", "scanf", "return", "NULL"],
            patterns: ["#include\\s*[<\"]", "#define\\s+\\w+", "\\bint\\s+main\\s*\\(", "\\bmalloc\\s*\\(", "\\bprintf\\s*\\("]
        ),
    ]

    /// Detect the most likely programming language for the given text.
    /// Returns nil if the text doesn't look like code.
    func detectLanguage(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 20 else { return nil }

        // Quick JSON check
        if (trimmed.hasPrefix("{") && trimmed.hasSuffix("}")) ||
           (trimmed.hasPrefix("[") && trimmed.hasSuffix("]")) {
            if (try? JSONSerialization.jsonObject(with: Data(trimmed.utf8))) != nil {
                return "json"
            }
        }

        var scores: [String: Int] = [:]
        let lines = trimmed.components(separatedBy: .newlines).prefix(50) // Sample first 50 lines
        let sampleText = lines.joined(separator: "\n")
        let lowered = sampleText.lowercased()
        let words = Set(sampleText.components(separatedBy: .alphanumerics.inverted).filter { !$0.isEmpty })

        for lang in languages {
            var score = 0

            // Keyword matching
            for keyword in lang.keywords {
                if keyword.contains(" ") || keyword.contains(".") || keyword.contains("<") {
                    if sampleText.contains(keyword) || lowered.contains(keyword.lowercased()) {
                        score += 3
                    }
                } else {
                    if words.contains(keyword) || words.contains(keyword.lowercased()) {
                        score += 2
                    }
                }
            }

            // Pattern matching
            for pattern in lang.patterns {
                if let regex = cachedRegex(pattern, options: lang.name == "sql" ? .caseInsensitive : []) {
                    let matches = regex.numberOfMatches(in: sampleText, range: NSRange(sampleText.startIndex..., in: sampleText))
                    score += matches * 3
                }
            }

            if score > 0 {
                scores[lang.name] = score
            }
        }

        // Require minimum score to classify as code
        guard let best = scores.max(by: { $0.value < $1.value }), best.value >= 6 else {
            return nil
        }

        // TypeScript is a superset of JavaScript — prefer TS if both score similarly
        if best.key == "javascript", let tsScore = scores["typescript"], tsScore >= 6 {
            return "typescript"
        }

        return best.key
    }

    // MARK: - Token Types

    enum TokenType {
        case keyword
        case string
        case comment
        case number
        case type
        case function
        case property
        case plain
    }

    struct Token {
        let range: Range<String.Index>
        let type: TokenType
    }

    // MARK: - Tokenization

    /// Tokenize text for syntax highlighting.
    func tokenize(_ text: String, language: String) -> [Token] {
        var tokens: [Token] = []
        var covered = IndexSet()
        let nsRange = NSRange(text.startIndex..., in: text)

        // 1. Comments
        let commentPatterns: [String]
        switch language {
        case "python", "ruby", "shell", "yaml":
            commentPatterns = ["#[^\n]*"]
        case "html", "xml":
            commentPatterns = ["<!--[\\s\\S]*?-->"]
        case "css":
            commentPatterns = ["/\\*[\\s\\S]*?\\*/"]
        case "sql":
            commentPatterns = ["--[^\n]*", "/\\*[\\s\\S]*?\\*/"]
        default:
            commentPatterns = ["//[^\n]*", "/\\*[\\s\\S]*?\\*/"]
        }
        for pattern in commentPatterns {
            addMatches(pattern: pattern, type: .comment, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)
        }

        // 2. Strings
        let stringPatterns = ["\"\"\"[\\s\\S]*?\"\"\"", "\"[^\"\\\\]*(\\\\.[^\"\\\\]*)*\"", "'[^'\\\\]*(\\\\.[^'\\\\]*)*'", "`[^`]*`"]
        for pattern in stringPatterns {
            addMatches(pattern: pattern, type: .string, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)
        }

        // 3. Numbers
        addMatches(pattern: "\\b\\d+(\\.\\d+)?\\b", type: .number, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)

        // 4. Keywords (language-specific)
        let keywords = keywordsFor(language: language)
        if !keywords.isEmpty {
            let joined = keywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
            addMatches(pattern: "\\b(\(joined))\\b", type: .keyword, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)
        }

        // 5. Types (capitalized identifiers)
        addMatches(pattern: "\\b[A-Z][a-zA-Z0-9]*\\b", type: .type, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)

        // 6. Function calls
        addMatches(pattern: "\\b[a-zA-Z_]\\w*(?=\\s*\\()", type: .function, text: text, nsRange: nsRange, tokens: &tokens, covered: &covered)

        return tokens.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    private func addMatches(pattern: String, type: TokenType, text: String, nsRange: NSRange, tokens: inout [Token], covered: inout IndexSet) {
        guard let regex = cachedRegex(pattern) else { return }
        let matches = regex.matches(in: text, range: nsRange)
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }
            let intRange = match.range.location..<(match.range.location + match.range.length)
            if covered.intersection(IndexSet(integersIn: intRange)).isEmpty {
                covered.insert(integersIn: intRange)
                tokens.append(Token(range: range, type: type))
            }
        }
    }

    private func keywordsFor(language: String) -> [String] {
        switch language {
        case "swift":
            return ["import", "func", "var", "let", "struct", "class", "enum", "protocol", "extension",
                    "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
                    "return", "throw", "throws", "try", "catch", "do", "in", "where", "as", "is",
                    "true", "false", "nil", "self", "Self", "super", "init", "deinit",
                    "public", "private", "internal", "fileprivate", "open", "static", "final",
                    "override", "mutating", "async", "await", "some", "any", "weak", "unowned",
                    "typealias", "associatedtype", "inout", "break", "continue", "fallthrough"]
        case "python":
            return ["def", "class", "import", "from", "if", "elif", "else", "for", "while",
                    "return", "yield", "lambda", "with", "as", "try", "except", "finally",
                    "raise", "pass", "break", "continue", "and", "or", "not", "in", "is",
                    "True", "False", "None", "self", "global", "nonlocal", "del", "assert", "async", "await"]
        case "javascript", "typescript":
            return ["function", "const", "let", "var", "if", "else", "for", "while", "do",
                    "return", "class", "extends", "new", "this", "super", "import", "export",
                    "default", "async", "await", "try", "catch", "finally", "throw",
                    "true", "false", "null", "undefined", "typeof", "instanceof", "of", "in",
                    "switch", "case", "break", "continue", "yield", "void", "delete"]
        case "go":
            return ["func", "package", "import", "type", "struct", "interface", "map", "chan",
                    "go", "defer", "range", "select", "case", "default", "if", "else", "for",
                    "switch", "return", "break", "continue", "fallthrough", "var", "const",
                    "true", "false", "nil", "make", "append", "len", "cap"]
        case "rust":
            return ["fn", "let", "mut", "pub", "struct", "enum", "impl", "trait", "use", "mod",
                    "match", "if", "else", "for", "while", "loop", "return", "break", "continue",
                    "self", "Self", "super", "crate", "where", "as", "in", "ref", "move",
                    "true", "false", "async", "await", "unsafe", "dyn", "static", "const", "type"]
        case "java":
            return ["public", "private", "protected", "static", "final", "abstract", "class",
                    "interface", "extends", "implements", "new", "return", "if", "else", "for",
                    "while", "do", "switch", "case", "default", "break", "continue", "try",
                    "catch", "finally", "throw", "throws", "void", "import", "package",
                    "this", "super", "true", "false", "null", "synchronized", "volatile"]
        case "ruby":
            return ["def", "end", "class", "module", "if", "elsif", "else", "unless", "while",
                    "until", "for", "do", "begin", "rescue", "ensure", "raise", "return",
                    "yield", "block_given?", "require", "include", "extend", "attr_accessor",
                    "attr_reader", "attr_writer", "true", "false", "nil", "self", "super",
                    "puts", "print", "and", "or", "not", "in", "then", "when", "case"]
        case "c":
            return ["int", "void", "char", "float", "double", "long", "short", "unsigned", "signed",
                    "struct", "union", "enum", "typedef", "sizeof", "return", "if", "else", "for",
                    "while", "do", "switch", "case", "default", "break", "continue", "goto",
                    "static", "extern", "const", "volatile", "register", "auto", "NULL",
                    "include", "define", "ifdef", "ifndef", "endif", "pragma"]
        case "sql":
            return ["SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "DELETE", "CREATE",
                    "TABLE", "ALTER", "DROP", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON",
                    "GROUP", "BY", "ORDER", "HAVING", "UNION", "ALL", "DISTINCT", "AS", "AND",
                    "OR", "NOT", "IN", "BETWEEN", "LIKE", "IS", "NULL", "EXISTS", "SET", "VALUES",
                    "INDEX", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "DEFAULT", "CONSTRAINT"]
        case "shell":
            return ["echo", "export", "source", "alias", "if", "then", "fi", "else", "elif",
                    "for", "do", "done", "while", "case", "esac", "function", "return",
                    "local", "read", "shift", "set", "unset", "exit", "test", "true", "false"]
        default:
            return []
        }
    }

    // MARK: - Highlighting

    /// Build an NSAttributedString with syntax highlighting colors.
    func highlight(_ text: String, language: String, isDark: Bool) -> NSAttributedString {
        let cacheKey = HighlightCacheKey(textHash: text.hashValue, language: language, isDark: isDark)
        if let cached = highlightCache[cacheKey] { return cached }

        let tokens = tokenize(text, language: language)
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributed.length)

        // Base style
        let baseColor = isDark ? NSColor.white.withAlphaComponent(0.85) : NSColor.black.withAlphaComponent(0.85)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        attributed.addAttribute(.foregroundColor, value: baseColor, range: fullRange)
        attributed.addAttribute(.font, value: monoFont, range: fullRange)

        // Apply token colors
        for token in tokens {
            let nsRange = NSRange(token.range, in: text)
            let color = colorFor(token: token.type, isDark: isDark)
            attributed.addAttribute(.foregroundColor, value: color, range: nsRange)
            if token.type == .keyword {
                attributed.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold), range: nsRange)
            }
        }

        highlightCache[cacheKey] = attributed
        return attributed
    }

    private func colorFor(token: TokenType, isDark: Bool) -> NSColor {
        if isDark {
            switch token {
            case .keyword:  return NSColor(red: 0.78, green: 0.46, blue: 0.82, alpha: 1.0)  // purple
            case .string:   return NSColor(red: 0.84, green: 0.40, blue: 0.36, alpha: 1.0)  // red
            case .comment:  return NSColor(red: 0.42, green: 0.47, blue: 0.53, alpha: 1.0)  // gray
            case .number:   return NSColor(red: 0.82, green: 0.68, blue: 0.40, alpha: 1.0)  // gold
            case .type:     return NSColor(red: 0.40, green: 0.72, blue: 0.82, alpha: 1.0)  // cyan
            case .function: return NSColor(red: 0.38, green: 0.65, blue: 0.90, alpha: 1.0)  // blue
            case .property: return NSColor(red: 0.60, green: 0.80, blue: 0.60, alpha: 1.0)  // green
            case .plain:    return NSColor.white.withAlphaComponent(0.85)
            }
        } else {
            switch token {
            case .keyword:  return NSColor(red: 0.55, green: 0.20, blue: 0.60, alpha: 1.0)
            case .string:   return NSColor(red: 0.77, green: 0.10, blue: 0.09, alpha: 1.0)
            case .comment:  return NSColor(red: 0.42, green: 0.47, blue: 0.53, alpha: 1.0)
            case .number:   return NSColor(red: 0.68, green: 0.51, blue: 0.17, alpha: 1.0)
            case .type:     return NSColor(red: 0.11, green: 0.43, blue: 0.55, alpha: 1.0)
            case .function: return NSColor(red: 0.15, green: 0.40, blue: 0.70, alpha: 1.0)
            case .property: return NSColor(red: 0.20, green: 0.50, blue: 0.20, alpha: 1.0)
            case .plain:    return NSColor.black.withAlphaComponent(0.85)
            }
        }
    }

    // MARK: - Language Display

    static let languageDisplayNames: [String: String] = [
        "swift": "Swift",
        "python": "Python",
        "javascript": "JavaScript",
        "typescript": "TypeScript",
        "go": "Go",
        "rust": "Rust",
        "java": "Java",
        "html": "HTML",
        "css": "CSS",
        "sql": "SQL",
        "shell": "Shell",
        "json": "JSON",
        "yaml": "YAML",
        "xml": "XML",
        "ruby": "Ruby",
        "c": "C",
    ]

    static func displayName(for language: String) -> String {
        languageDisplayNames[language] ?? language.capitalized
    }
}
