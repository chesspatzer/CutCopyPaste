import Foundation

/// Provides built-in smart collections for auto-grouping clipboard items.
final class SmartCollectionService {
    static let shared = SmartCollectionService()
    private init() {}

    let collections: [SmartCollection] = [
        SmartCollection(
            id: "code_snippets",
            name: "Code Snippets",
            systemImage: "chevron.left.forwardslash.chevron.right",
            description: "Items detected as source code",
            predicate: { $0.detectedLanguage != nil }
        ),
        SmartCollection(
            id: "urls_links",
            name: "URLs & Links",
            systemImage: "link",
            description: "All copied URLs and links",
            predicate: { $0.contentType == .link }
        ),
        SmartCollection(
            id: "images",
            name: "Images",
            systemImage: "photo.stack",
            description: "All copied images",
            predicate: { $0.contentType == .image }
        ),
        SmartCollection(
            id: "from_xcode",
            name: "From Xcode",
            systemImage: "hammer",
            description: "Items copied from Xcode",
            predicate: { $0.sourceAppBundleID == "com.apple.dt.Xcode" }
        ),
        SmartCollection(
            id: "from_browsers",
            name: "From Browsers",
            systemImage: "globe",
            description: "Items from Safari, Chrome, Firefox, Arc",
            predicate: {
                guard let bid = $0.sourceAppBundleID?.lowercased() else { return false }
                return bid.contains("safari") || bid.contains("chrome") || bid.contains("firefox") || bid.contains("arc")
            }
        ),
        SmartCollection(
            id: "from_terminal",
            name: "From Terminal",
            systemImage: "terminal",
            description: "Items from Terminal, iTerm, Warp",
            predicate: {
                guard let bid = $0.sourceAppBundleID?.lowercased() else { return false }
                return bid.contains("terminal") || bid.contains("iterm") || bid.contains("warp")
            }
        ),
        SmartCollection(
            id: "today",
            name: "Today",
            systemImage: "calendar",
            description: "Items copied today",
            predicate: { Calendar.current.isDateInToday($0.createdAt) }
        ),
        SmartCollection(
            id: "this_week",
            name: "This Week",
            systemImage: "calendar.badge.clock",
            description: "Items from this week",
            predicate: {
                let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
                return $0.createdAt >= start
            }
        ),
        SmartCollection(
            id: "frequently_used",
            name: "Frequently Used",
            systemImage: "arrow.counterclockwise",
            description: "Items pasted 3+ times",
            predicate: { $0.useCount >= 3 }
        ),
        SmartCollection(
            id: "long_text",
            name: "Long Text",
            systemImage: "doc.text",
            description: "Text items over 500 characters",
            predicate: { ($0.characterCount ?? 0) > 500 }
        ),
        SmartCollection(
            id: "with_ocr",
            name: "With OCR Text",
            systemImage: "text.viewfinder",
            description: "Images with extracted text",
            predicate: { $0.ocrText != nil && !($0.ocrText?.isEmpty ?? true) }
        ),
        SmartCollection(
            id: "sensitive",
            name: "Sensitive Data",
            systemImage: "exclamationmark.shield",
            description: "Items with detected sensitive data",
            predicate: { $0.sensitiveDataTypes != nil && !($0.sensitiveDataTypes?.isEmpty ?? true) }
        ),
    ]

    /// Filter items by a specific smart collection.
    func filter(_ items: [ClipboardItem], by collection: SmartCollection) -> [ClipboardItem] {
        items.filter(collection.predicate)
    }

    /// Get counts for all collections against the given items.
    func counts(for items: [ClipboardItem]) -> [String: Int] {
        var result: [String: Int] = [:]
        for collection in collections {
            result[collection.id] = items.filter(collection.predicate).count
        }
        return result
    }
}
