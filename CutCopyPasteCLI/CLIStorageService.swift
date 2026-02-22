import Foundation
import SwiftData

@available(macOS 14, *)
final class CLIStorageService {
    let container: ModelContainer

    init() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("CutCopyPaste")
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let storeURL = appDir.appendingPathComponent("CutCopyPaste.store")

        let config = ModelConfiguration(url: storeURL)
        container = try ModelContainer(
            for: ClipboardItem.self, Snippet.self, SnippetFolder.self, ClipboardRule.self,
            configurations: config
        )
    }

    @MainActor
    func fetchRecentItems(limit: Int = 20) throws -> [ClipboardItem] {
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return try container.mainContext.fetch(limited)
    }

    @MainActor
    func searchItems(query: String) throws -> [ClipboardItem] {
        let predicate = #Predicate<ClipboardItem> { item in
            item.textContent?.localizedStandardContains(query) == true
        }
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try container.mainContext.fetch(descriptor)
    }

    @MainActor
    func addTextItem(_ text: String) throws {
        let item = ClipboardItem(contentType: .text, textContent: text)
        container.mainContext.insert(item)
        try container.mainContext.save()
    }

    @MainActor
    func getItem(at index: Int) throws -> ClipboardItem? {
        let items = try fetchRecentItems(limit: index + 1)
        guard index < items.count else { return nil }
        return items[index]
    }
}
