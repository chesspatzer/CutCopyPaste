import Foundation
import SwiftData
import os

@ModelActor
actor StorageService {
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "Storage")

    // MARK: - Save

    func save(_ item: ClipboardItem) {
        modelContext.insert(item)
        try? modelContext.save()
        enforceRetentionLimits()
        logger.debug("Saved clipboard item: \(item.contentType.rawValue)")
    }

    // MARK: - Fetch

    func fetchItems(
        filterType: ClipboardItemType? = nil,
        searchText: String = "",
        pinnedOnly: Bool = false,
        limit: Int = 100
    ) -> [ClipboardItem] {
        var descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        guard var items = try? modelContext.fetch(descriptor) else { return [] }

        // Apply filters in-memory for simplicity with SwiftData predicate limitations
        if let filterType {
            items = items.filter { $0.contentType == filterType }
        }
        if pinnedOnly {
            items = items.filter { $0.isPinned }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter { item in
                item.textContent?.lowercased().contains(query) == true
                || item.sourceAppName?.lowercased().contains(query) == true
            }
        }

        return items
    }

    // MARK: - Deduplication

    func isDuplicateOfMostRecent(_ textContent: String?, contentType: ClipboardItemType) -> Bool {
        guard let text = textContent else { return false }
        var descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let mostRecent = (try? modelContext.fetch(descriptor))?.first else { return false }
        return mostRecent.textContent == text && mostRecent.contentType == contentType
    }

    func touchMostRecent() {
        var descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let item = (try? modelContext.fetch(descriptor))?.first {
            item.lastUsedAt = Date()
            item.useCount += 1
            try? modelContext.save()
        }
    }

    // MARK: - Touch (update usage stats on re-copy)

    func touchItem(_ itemID: UUID) {
        guard let item = fetchByID(itemID) else { return }
        item.lastUsedAt = Date()
        item.useCount += 1
        try? modelContext.save()
    }

    // MARK: - Pin / Unpin

    func togglePin(_ itemID: UUID) {
        guard let item = fetchByID(itemID) else { return }
        item.isPinned.toggle()
        try? modelContext.save()
    }

    // MARK: - Delete

    func delete(_ itemID: UUID) {
        guard let item = fetchByID(itemID) else { return }
        modelContext.delete(item)
        try? modelContext.save()
    }

    func clearAll(keepPinned: Bool = true) {
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let all = try? modelContext.fetch(descriptor) else { return }
        for item in all {
            if keepPinned && item.isPinned { continue }
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    // MARK: - Retention

    private func enforceRetentionLimits() {
        let prefs = UserPreferences.shared

        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let all = try? modelContext.fetch(descriptor) else { return }
        let unpinned = all.filter { !$0.isPinned }

        // Count-based limit
        if unpinned.count > prefs.maxHistoryCount {
            for item in unpinned.suffix(from: prefs.maxHistoryCount) {
                modelContext.delete(item)
            }
        }

        // Age-based limit
        if prefs.retentionDays > 0 {
            let cutoff = Calendar.current.date(
                byAdding: .day, value: -prefs.retentionDays, to: Date()
            )!
            for item in all where item.createdAt < cutoff && !item.isPinned {
                modelContext.delete(item)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Helpers

    private func fetchByID(_ id: UUID) -> ClipboardItem? {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}
