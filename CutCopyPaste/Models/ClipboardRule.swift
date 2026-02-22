import Foundation
import SwiftData

enum ClipboardTransformType: String, Codable, CaseIterable {
    case stripAnsi
    case prettifyJson
    case stripTrackingParams
    case regexReplace
    case trimWhitespace
    case lowercaseAll
    case uppercaseAll

    var displayName: String {
        switch self {
        case .stripAnsi:           return "Strip ANSI Codes"
        case .prettifyJson:        return "Prettify JSON"
        case .stripTrackingParams: return "Strip Tracking Params"
        case .regexReplace:        return "Regex Replace"
        case .trimWhitespace:      return "Trim Whitespace"
        case .lowercaseAll:        return "Lowercase"
        case .uppercaseAll:        return "Uppercase"
        }
    }
}

@Model
final class ClipboardRule {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var isEnabled: Bool
    var sourceBundleID: String?
    var sourceAppName: String?
    var contentTypeFilter: String?
    var transformType: String
    var regexPattern: String?
    var regexReplacement: String?
    var sortOrder: Int
    var createdAt: Date

    var transformTypeEnum: ClipboardTransformType? {
        ClipboardTransformType(rawValue: transformType)
    }

    init(
        name: String,
        isEnabled: Bool = true,
        sourceBundleID: String? = nil,
        sourceAppName: String? = nil,
        contentTypeFilter: String? = nil,
        transformType: ClipboardTransformType,
        regexPattern: String? = nil,
        regexReplacement: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.isEnabled = isEnabled
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.contentTypeFilter = contentTypeFilter
        self.transformType = transformType.rawValue
        self.regexPattern = regexPattern
        self.regexReplacement = regexReplacement
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
