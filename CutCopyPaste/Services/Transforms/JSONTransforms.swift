import Foundation

struct JSONPrettifyTransform: ClipboardTransform {
    let id = "json_prettify"
    let name = "Prettify JSON"
    let description = "Format JSON with indentation"
    let iconSystemName = "curlybraces"
    let inputSignatures: Set<ContentSignature> = [.json]

    func canApply(to text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let result = String(data: pretty, encoding: .utf8) else {
            return .failure(.transformFailed("Could not prettify JSON"))
        }
        return .success(result)
    }
}

struct JSONMinifyTransform: ClipboardTransform {
    let id = "json_minify"
    let name = "Minify JSON"
    let description = "Compact JSON by removing whitespace"
    let iconSystemName = "curlybraces"
    let inputSignatures: Set<ContentSignature> = [.json]

    func canApply(to text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minified = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]),
              let result = String(data: minified, encoding: .utf8) else {
            return .failure(.transformFailed("Could not minify JSON"))
        }
        return .success(result)
    }
}

struct JSONToSwiftStructTransform: ClipboardTransform {
    let id = "json_to_swift"
    let name = "JSON → Swift Struct"
    let description = "Generate Swift Codable struct from JSON"
    let iconSystemName = "swift"
    let inputSignatures: Set<ContentSignature> = [.json]

    func canApply(to text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        let obj = try? JSONSerialization.jsonObject(with: data)
        return obj is [String: Any]
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let data = text.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.invalidInput("Expected a JSON object"))
        }
        let result = generateStruct(name: "GeneratedModel", from: dict)
        return .success(result)
    }

    private func generateStruct(name: String, from dict: [String: Any]) -> String {
        var lines: [String] = []
        lines.append("struct \(name): Codable {")

        for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
            let swiftType = inferSwiftType(from: value)
            let propertyName = key.contains("_") ? snakeToCamel(key) : key
            if propertyName != key {
                lines.append("    let \(propertyName): \(swiftType)")
            } else {
                lines.append("    let \(key): \(swiftType)")
            }
        }

        // Add CodingKeys if any key was converted
        let needsCodingKeys = dict.keys.contains { $0.contains("_") }
        if needsCodingKeys {
            lines.append("")
            lines.append("    enum CodingKeys: String, CodingKey {")
            for key in dict.keys.sorted() {
                let propertyName = key.contains("_") ? snakeToCamel(key) : key
                if propertyName != key {
                    lines.append("        case \(propertyName) = \"\(key)\"")
                } else {
                    lines.append("        case \(key)")
                }
            }
            lines.append("    }")
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func inferSwiftType(from value: Any) -> String {
        switch value {
        case is String: return "String"
        case is Bool: return "Bool"
        case is Int: return "Int"
        case is Double: return "Double"
        case is [Any]: return "[Any]"
        case is [String: Any]: return "[String: Any]"
        case is NSNull: return "String?"
        default: return "Any"
        }
    }

    private func snakeToCamel(_ text: String) -> String {
        let parts = text.components(separatedBy: "_")
        return parts.enumerated().map { i, part in
            i == 0 ? part.lowercased() : part.capitalized
        }.joined()
    }
}
