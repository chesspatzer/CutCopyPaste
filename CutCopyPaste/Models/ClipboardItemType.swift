import Foundation

enum ClipboardItemType: String, Codable, CaseIterable, Identifiable {
    case text
    case richText
    case image
    case file
    case link

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .text:     return "Text"
        case .richText: return "Rich Text"
        case .image:    return "Image"
        case .file:     return "File"
        case .link:     return "Link"
        }
    }

    var systemImage: String {
        switch self {
        case .text:     return "doc.text"
        case .richText: return "doc.richtext"
        case .image:    return "photo"
        case .file:     return "doc"
        case .link:     return "link"
        }
    }
}
