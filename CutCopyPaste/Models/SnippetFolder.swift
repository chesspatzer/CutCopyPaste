import Foundation
import SwiftData

@Model
final class SnippetFolder {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var iconName: String
    var sortOrder: Int
    var createdAt: Date

    init(name: String, iconName: String = "folder", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
