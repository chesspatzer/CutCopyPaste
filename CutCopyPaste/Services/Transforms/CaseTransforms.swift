import Foundation

struct CamelToSnakeTransform: ClipboardTransform {
    let id = "camel_to_snake"
    let name = "camelCase → snake_case"
    let description = "Convert camelCase identifiers to snake_case"
    let iconSystemName = "textformat.abc"
    let inputSignatures: Set<ContentSignature> = [.identifier, .plainText]

    func canApply(to text: String) -> Bool {
        text.range(of: "[a-z][A-Z]", options: .regularExpression) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let result = text.map { char -> String in
            if char.isUppercase {
                return "_\(char.lowercased())"
            }
            return String(char)
        }.joined()
        return .success(result)
    }
}

struct SnakeToCamelTransform: ClipboardTransform {
    let id = "snake_to_camel"
    let name = "snake_case → camelCase"
    let description = "Convert snake_case identifiers to camelCase"
    let iconSystemName = "textformat.abc"
    let inputSignatures: Set<ContentSignature> = [.identifier, .plainText]

    func canApply(to text: String) -> Bool {
        text.contains("_") && text.range(of: "[a-z_]+", options: .regularExpression) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let parts = text.components(separatedBy: "_")
        guard parts.count > 1 else { return .success(text) }
        let camel = parts.enumerated().map { index, part in
            index == 0 ? part.lowercased() : part.capitalized
        }.joined()
        return .success(camel)
    }
}

struct ToKebabCaseTransform: ClipboardTransform {
    let id = "to_kebab_case"
    let name = "→ kebab-case"
    let description = "Convert to kebab-case"
    let iconSystemName = "textformat.abc"
    let inputSignatures: Set<ContentSignature> = [.identifier, .plainText]

    func canApply(to text: String) -> Bool {
        text.range(of: "[a-z][A-Z]", options: .regularExpression) != nil || text.contains("_")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        // First convert camelCase to separated
        var result = ""
        for char in text {
            if char.isUppercase && !result.isEmpty {
                result += "-\(char.lowercased())"
            } else if char == "_" {
                result += "-"
            } else {
                result += String(char).lowercased()
            }
        }
        return .success(result)
    }
}
