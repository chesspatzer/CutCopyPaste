import Foundation

struct SQLToSwiftDataTransform: ClipboardTransform {
    let id = "sql_to_swiftdata"
    let name = "SQL → SwiftData Model"
    let description = "Convert CREATE TABLE to SwiftData @Model"
    let iconSystemName = "tablecells"
    let inputSignatures: Set<ContentSignature> = [.sql]

    func canApply(to text: String) -> Bool {
        text.uppercased().contains("CREATE TABLE")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")

        guard let tableMatch = normalized.range(of: "CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?[`\"']?(\\w+)[`\"']?\\s*\\(",
                                                  options: .regularExpression) else {
            return .failure(.invalidInput("Could not parse CREATE TABLE statement"))
        }

        let beforeParen = normalized[tableMatch]
        let tableName = extractTableName(from: String(beforeParen))
        let className = tableName.capitalized.replacingOccurrences(of: "_", with: "")

        // Extract columns between parentheses
        guard let openParen = normalized.firstIndex(of: "("),
              let closeParen = normalized.lastIndex(of: ")") else {
            return .failure(.invalidInput("Could not find column definitions"))
        }

        let columnsDef = String(normalized[normalized.index(after: openParen)..<closeParen])
        let columns = parseColumns(columnsDef)

        var lines: [String] = []
        lines.append("import SwiftData")
        lines.append("")
        lines.append("@Model")
        lines.append("final class \(className) {")

        for col in columns {
            let swiftType = sqlTypeToSwift(col.type, nullable: col.nullable)
            lines.append("    var \(camelCase(col.name)): \(swiftType)")
        }

        lines.append("")
        lines.append("    init(")
        let initParams = columns.map { col in
            let swiftType = sqlTypeToSwift(col.type, nullable: col.nullable)
            let defaultVal = col.nullable ? " = nil" : ""
            return "        \(camelCase(col.name)): \(swiftType)\(defaultVal)"
        }
        lines.append(initParams.joined(separator: ",\n"))
        lines.append("    ) {")
        for col in columns {
            let name = camelCase(col.name)
            lines.append("        self.\(name) = \(name)")
        }
        lines.append("    }")
        lines.append("}")

        return .success(lines.joined(separator: "\n"))
    }

    private struct Column {
        let name: String
        let type: String
        let nullable: Bool
    }

    private func extractTableName(from text: String) -> String {
        let pattern = "CREATE\\s+TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?[`\"']?(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return "UnknownTable"
        }
        return String(text[range])
    }

    private func parseColumns(_ def: String) -> [Column] {
        let parts = def.components(separatedBy: ",")
        var columns: [Column] = []
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            let upper = trimmed.uppercased()
            // Skip constraints
            if upper.hasPrefix("PRIMARY KEY") || upper.hasPrefix("FOREIGN KEY")
                || upper.hasPrefix("UNIQUE") || upper.hasPrefix("CHECK")
                || upper.hasPrefix("CONSTRAINT") || upper.hasPrefix("INDEX") {
                continue
            }
            let tokens = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard tokens.count >= 2 else { continue }
            let name = tokens[0].trimmingCharacters(in: CharacterSet(charactersIn: "`\"'"))
            let type = tokens[1].uppercased()
            let nullable = !upper.contains("NOT NULL")
            columns.append(Column(name: name, type: type, nullable: nullable))
        }
        return columns
    }

    private func sqlTypeToSwift(_ sqlType: String, nullable: Bool) -> String {
        let base: String
        let upper = sqlType.uppercased()
        if upper.hasPrefix("INT") || upper == "INTEGER" || upper == "BIGINT" || upper == "SMALLINT" {
            base = "Int"
        } else if upper.hasPrefix("VARCHAR") || upper == "TEXT" || upper.hasPrefix("CHAR") {
            base = "String"
        } else if upper == "BOOLEAN" || upper == "BOOL" {
            base = "Bool"
        } else if upper == "FLOAT" || upper == "DOUBLE" || upper == "REAL" || upper.hasPrefix("DECIMAL") || upper.hasPrefix("NUMERIC") {
            base = "Double"
        } else if upper == "DATE" || upper == "DATETIME" || upper == "TIMESTAMP" {
            base = "Date"
        } else if upper == "BLOB" {
            base = "Data"
        } else {
            base = "String"
        }
        return nullable ? "\(base)?" : base
    }

    private func camelCase(_ snakeCase: String) -> String {
        let parts = snakeCase.lowercased().components(separatedBy: "_")
        return parts.enumerated().map { i, part in
            i == 0 ? part : part.capitalized
        }.joined()
    }
}
