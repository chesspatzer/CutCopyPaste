import Foundation

/// A smart collection automatically groups clipboard items by a predicate.
struct SmartCollection: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let description: String
    let predicate: @Sendable (ClipboardItem) -> Bool
}
