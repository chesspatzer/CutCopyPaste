import Foundation

struct CurlToURLSessionTransform: ClipboardTransform {
    let id = "curl_to_urlsession"
    let name = "cURL → URLSession"
    let description = "Convert cURL command to Swift URLSession code"
    let iconSystemName = "terminal"
    let inputSignatures: Set<ContentSignature> = [.curl]

    func canApply(to text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().hasPrefix("curl ")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let parsed = parseCurl(text)
        var lines: [String] = []

        lines.append("let url = URL(string: \"\(parsed.url)\")!")
        lines.append("var request = URLRequest(url: url)")
        lines.append("request.httpMethod = \"\(parsed.method)\"")

        for (key, value) in parsed.headers {
            lines.append("request.setValue(\"\(value)\", forHTTPHeaderField: \"\(key)\")")
        }

        if let body = parsed.body {
            let escaped = body.replacingOccurrences(of: "\"", with: "\\\"")
            lines.append("request.httpBody = \"\(escaped)\".data(using: .utf8)")
        }

        lines.append("")
        lines.append("let (data, response) = try await URLSession.shared.data(for: request)")

        return .success(lines.joined(separator: "\n"))
    }

    private struct CurlParsed {
        var url: String = ""
        var method: String = "GET"
        var headers: [(String, String)] = []
        var body: String?
    }

    private func parseCurl(_ command: String) -> CurlParsed {
        var parsed = CurlParsed()
        // Normalize continuation lines
        let normalized = command
            .replacingOccurrences(of: "\\\n", with: " ")
            .replacingOccurrences(of: "\\\r\n", with: " ")

        let tokens = tokenize(normalized)
        var i = 0
        while i < tokens.count {
            let token = tokens[i]
            switch token {
            case "-X", "--request":
                if i + 1 < tokens.count {
                    parsed.method = tokens[i + 1].uppercased()
                    i += 1
                }
            case "-H", "--header":
                if i + 1 < tokens.count {
                    let header = tokens[i + 1]
                    if let colonIndex = header.firstIndex(of: ":") {
                        let key = String(header[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                        let value = String(header[header.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        parsed.headers.append((key, value))
                    }
                    i += 1
                }
            case "-d", "--data", "--data-raw":
                if i + 1 < tokens.count {
                    parsed.body = tokens[i + 1]
                    if parsed.method == "GET" { parsed.method = "POST" }
                    i += 1
                }
            default:
                if !token.hasPrefix("-") && token.lowercased() != "curl" {
                    parsed.url = token
                }
            }
            i += 1
        }

        return parsed
    }

    private func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote: Character? = nil
        for char in input {
            if let q = inQuote {
                if char == q {
                    inQuote = nil
                    tokens.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            } else if char == "'" || char == "\"" {
                inQuote = char
            } else if char.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}
