import Foundation

/// A plain value-type snapshot of a ClipboardItem, used to preserve data
/// after SwiftData deletes the model object (e.g. for undo-delete).
struct ClipboardItemSnapshot {
    let id: UUID
    let contentType: ClipboardItemType
    let textContent: String?
    let rtfData: Data?
    let imageData: Data?
    let thumbnailData: Data?
    let filePaths: [String]?
    let sourceAppBundleID: String?
    let sourceAppName: String?
    let createdAt: Date
    let lastUsedAt: Date
    let useCount: Int
    let isPinned: Bool
    let characterCount: Int?
    let sensitiveDataTypes: [String]?
    let isMasked: Bool
    let summary: String?
    let ocrText: String?
    let workspacePath: String?
    let workspaceName: String?
    let workspaceType: String?
    let embeddingVector: Data?
    let detectedLanguage: String?
    let isMarkdown: Bool
    let pinnedOrder: Int

    init(_ item: ClipboardItem) {
        self.id = item.id
        self.contentType = item.contentType
        self.textContent = item.textContent
        self.rtfData = item.rtfData
        self.imageData = item.imageData
        self.thumbnailData = item.thumbnailData
        self.filePaths = item.filePaths
        self.sourceAppBundleID = item.sourceAppBundleID
        self.sourceAppName = item.sourceAppName
        self.createdAt = item.createdAt
        self.lastUsedAt = item.lastUsedAt
        self.useCount = item.useCount
        self.isPinned = item.isPinned
        self.characterCount = item.characterCount
        self.sensitiveDataTypes = item.sensitiveDataTypes
        self.isMasked = item.isMasked
        self.summary = item.summary
        self.ocrText = item.ocrText
        self.workspacePath = item.workspacePath
        self.workspaceName = item.workspaceName
        self.workspaceType = item.workspaceType
        self.embeddingVector = item.embeddingVector
        self.detectedLanguage = item.detectedLanguage
        self.isMarkdown = item.isMarkdown
        self.pinnedOrder = item.pinnedOrder
    }

    func toClipboardItem() -> ClipboardItem {
        let item = ClipboardItem(
            contentType: contentType,
            textContent: textContent,
            rtfData: rtfData,
            imageData: imageData,
            thumbnailData: thumbnailData,
            filePaths: filePaths,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName
        )
        item.id = id
        item.createdAt = createdAt
        item.lastUsedAt = lastUsedAt
        item.useCount = useCount
        item.isPinned = isPinned
        item.characterCount = characterCount
        item.sensitiveDataTypes = sensitiveDataTypes
        item.isMasked = isMasked
        item.summary = summary
        item.ocrText = ocrText
        item.workspacePath = workspacePath
        item.workspaceName = workspaceName
        item.workspaceType = workspaceType
        item.embeddingVector = embeddingVector
        item.detectedLanguage = detectedLanguage
        item.isMarkdown = isMarkdown
        item.pinnedOrder = pinnedOrder
        return item
    }
}
