import Foundation
import SwiftData

@Model
final class Snippet {
    @Attribute(.unique)
    var id: UUID

    var title: String
    var content: String
    var folderID: UUID?
    var isBuiltIn: Bool
    var createdAt: Date
    var lastUsedAt: Date
    var useCount: Int
    var sortOrder: Int

    @Transient
    var placeholders: [String] {
        let pattern = "\\{\\{(\\w+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        var seen = Set<String>()
        var result: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let name = String(content[range])
                if seen.insert(name).inserted {
                    result.append(name)
                }
            }
        }
        return result
    }

    init(
        title: String,
        content: String,
        folderID: UUID? = nil,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.folderID = folderID
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.useCount = 0
        self.sortOrder = sortOrder
    }
}
