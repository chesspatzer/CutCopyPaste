import Foundation

struct SensitiveDataMatch {
    let type: SensitiveDataType
    let range: Range<String.Index>
    let matchedText: String
}

enum SensitiveDataType: String, CaseIterable {
    case awsAccessKey = "aws_access_key"
    case awsSecretKey = "aws_secret_key"
    case openAIKey = "openai_key"
    case stripeKey = "stripe_key"
    case githubToken = "github_token"
    case genericAPIKey = "api_key"
    case creditCard = "credit_card"
    case ssn = "ssn"
    case pemPrivateKey = "pem_private_key"
    case connectionString = "connection_string"
    case password = "password_in_config"

    var displayName: String {
        switch self {
        case .awsAccessKey:     return "AWS Access Key"
        case .awsSecretKey:     return "AWS Secret Key"
        case .openAIKey:        return "OpenAI API Key"
        case .stripeKey:        return "Stripe Key"
        case .githubToken:      return "GitHub Token"
        case .genericAPIKey:    return "API Key"
        case .creditCard:       return "Credit Card"
        case .ssn:              return "Social Security Number"
        case .pemPrivateKey:    return "Private Key"
        case .connectionString: return "Connection String"
        case .password:         return "Password"
        }
    }

    var iconSystemName: String {
        switch self {
        case .creditCard:       return "creditcard"
        case .ssn:              return "person.text.rectangle"
        case .pemPrivateKey:    return "key"
        case .password:         return "lock"
        default:                return "exclamationmark.shield"
        }
    }

    var severity: Severity {
        switch self {
        case .pemPrivateKey, .awsSecretKey, .connectionString:
            return .high
        case .awsAccessKey, .openAIKey, .stripeKey, .githubToken, .genericAPIKey, .password:
            return .medium
        case .creditCard, .ssn:
            return .high
        }
    }

    enum Severity: String {
        case high, medium, low
    }
}

final class SensitiveDataDetector {
    static let shared = SensitiveDataDetector()

    private let patterns: [(SensitiveDataType, NSRegularExpression)]

    private init() {
        patterns = Self.buildPatterns()
    }

    private static func buildPatterns() -> [(SensitiveDataType, NSRegularExpression)] {
        let defs: [(SensitiveDataType, String)] = [
            (.awsAccessKey,    "AKIA[0-9A-Z]{16}"),
            (.awsSecretKey,    "(?i)(aws_secret_access_key|aws_secret)\\s*[=:]\\s*[A-Za-z0-9/+=]{40}"),
            (.openAIKey,       "sk-[A-Za-z0-9]{20,}"),
            (.stripeKey,       "(?:sk|pk)_(?:test|live)_[A-Za-z0-9]{10,}"),
            (.githubToken,     "gh[ps]_[A-Za-z0-9]{36,}"),
            (.genericAPIKey,   "(?i)(api[_\\-]?key|apikey|secret[_\\-]?key)\\s*[=:]\\s*['\"]?[A-Za-z0-9_\\-]{16,}['\"]?"),
            (.creditCard,      "\\b(?:\\d[ \\-]*?){13,19}\\b"),
            (.ssn,             "\\b\\d{3}-\\d{2}-\\d{4}\\b"),
            (.pemPrivateKey,   "-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----"),
            (.connectionString, "(?i)(mongodb|mysql|postgres|postgresql|redis|amqp)://[^\\s]+"),
            (.password,        "(?i)(password|passwd|pwd)\\s*[=:]\\s*['\"]?[^\\s'\"]{4,}['\"]?"),
        ]
        return defs.compactMap { type, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            return (type, regex)
        }
    }

    func detect(in text: String) -> [SensitiveDataMatch] {
        var matches: [SensitiveDataMatch] = []
        let fullRange = NSRange(text.startIndex..., in: text)

        for (type, regex) in patterns {
            for match in regex.matches(in: text, range: fullRange) {
                guard let range = Range(match.range, in: text) else { continue }
                let matchedText = String(text[range])

                // Credit card needs Luhn validation
                if type == .creditCard {
                    let digits = matchedText.filter(\.isNumber)
                    guard digits.count >= 13 && digits.count <= 19 && luhnCheck(digits) else { continue }
                }

                matches.append(SensitiveDataMatch(
                    type: type,
                    range: range,
                    matchedText: matchedText
                ))
            }
        }
        return matches
    }

    func redact(_ text: String, matches: [SensitiveDataMatch]) -> String {
        var result = text
        for match in matches.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            let replacement = String(repeating: "*", count: match.matchedText.count)
            result.replaceSubrange(match.range, with: replacement)
        }
        return result
    }

    private func luhnCheck(_ number: String) -> Bool {
        let digits = number.compactMap { Int(String($0)) }
        guard digits.count >= 13 else { return false }
        var sum = 0
        for (i, digit) in digits.reversed().enumerated() {
            if i % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}
