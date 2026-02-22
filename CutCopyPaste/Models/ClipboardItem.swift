import Foundation
import SwiftData

@Model
final class ClipboardItem {
    @Attribute(.unique)
    var id: UUID

    var contentType: ClipboardItemType
    var textContent: String?
    @Attribute(.externalStorage)
    var rtfData: Data?
    @Attribute(.externalStorage)
    var imageData: Data?
    var thumbnailData: Data?
    var filePaths: [String]?
    var sourceAppBundleID: String?
    var sourceAppName: String?

    var createdAt: Date
    var lastUsedAt: Date
    var useCount: Int
    var isPinned: Bool
    var characterCount: Int?

    @Transient
    var preview: String {
        switch contentType {
        case .text, .link:
            return String((textContent ?? "").prefix(150))
        case .richText:
            return String((textContent ?? "Rich Text").prefix(150))
        case .image:
            return "Image"
        case .file:
            let count = filePaths?.count ?? 0
            return "\(count) file\(count == 1 ? "" : "s")"
        }
    }

    init(
        contentType: ClipboardItemType,
        textContent: String? = nil,
        rtfData: Data? = nil,
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        filePaths: [String]? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil
    ) {
        self.id = UUID()
        self.contentType = contentType
        self.textContent = textContent
        self.rtfData = rtfData
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.filePaths = filePaths
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.createdAt = Date()
        self.lastUsedAt = Date()
        self.useCount = 0
        self.isPinned = false
        self.characterCount = textContent?.count
    }
}
