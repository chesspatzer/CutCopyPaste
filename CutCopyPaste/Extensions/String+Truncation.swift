import Foundation

extension String {
    /// Truncate to a maximum length, appending ellipsis if truncated.
    func truncated(to maxLength: Int) -> String {
        if count <= maxLength { return self }
        return String(prefix(maxLength)) + "..."
    }

    /// Returns the first line of the string, trimmed.
    var firstLine: String {
        let line = components(separatedBy: .newlines).first ?? self
        return line.trimmingCharacters(in: .whitespaces)
    }
}
