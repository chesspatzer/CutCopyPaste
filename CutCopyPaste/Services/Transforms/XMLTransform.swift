import Foundation

struct XMLPrettifyTransform: ClipboardTransform {
    let id = "xml_prettify"
    let name = "Prettify XML"
    let description = "Format XML with indentation"
    let iconSystemName = "chevron.left.forwardslash.chevron.right"
    let inputSignatures: Set<ContentSignature> = [.xml]

    func canApply(to text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("<") && trimmed.hasSuffix(">")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let data = text.data(using: .utf8) else {
            return .failure(.invalidInput("Could not encode as UTF-8"))
        }

        do {
            let doc = try XMLDocument(data: data, options: [.nodePrettyPrint])
            let pretty = doc.xmlString(options: [.nodePrettyPrint])
            return .success(pretty)
        } catch {
            // Fallback: simple indent-based prettification
            return .success(simplePrettify(text))
        }
    }

    private func simplePrettify(_ xml: String) -> String {
        var result = ""
        var indent = 0
        let indentStr = "  "

        // Split on > then reassemble
        let parts = xml
            .replacingOccurrences(of: ">", with: ">\n")
            .replacingOccurrences(of: "<", with: "\n<")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for part in parts {
            if part.hasPrefix("</") {
                indent = max(0, indent - 1)
                result += String(repeating: indentStr, count: indent) + part + "\n"
            } else if part.hasPrefix("<") && !part.hasSuffix("/>") && !part.contains("</") {
                result += String(repeating: indentStr, count: indent) + part + "\n"
                if !part.hasPrefix("<?") && !part.hasPrefix("<!") {
                    indent += 1
                }
            } else {
                result += String(repeating: indentStr, count: indent) + part + "\n"
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
