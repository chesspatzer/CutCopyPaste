import Foundation
import SwiftData
import os

struct DailyCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct ContentTypeDistribution: Identifiable {
    let id = UUID()
    let type: ClipboardItemType
    let count: Int
    let percentage: Double
}

struct AppUsage: Identifiable {
    let id = UUID()
    let appName: String
    let bundleID: String?
    let count: Int
}

struct HourlyDistribution: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int
}

@ModelActor
actor AnalyticsService {
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "Analytics")

    // MARK: - Copies Over Time

    func copiesPerDay(lastDays: Int = 30) -> [DailyCount] {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -lastDays, to: Date()) else { return [] }

        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let items = try? modelContext.fetch(descriptor) else { return [] }
        let filtered = items.filter { $0.createdAt >= startDate }

        var dayMap: [Date: Int] = [:]
        for item in filtered {
            let day = calendar.startOfDay(for: item.createdAt)
            dayMap[day, default: 0] += 1
        }

        // Fill in missing days with 0
        var result: [DailyCount] = []
        var current = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        while current <= today {
            result.append(DailyCount(date: current, count: dayMap[current] ?? 0))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return result
    }

    // MARK: - Content Type Distribution

    func contentTypeDistribution() -> [ContentTypeDistribution] {
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let items = try? modelContext.fetch(descriptor), !items.isEmpty else { return [] }

        var typeCount: [ClipboardItemType: Int] = [:]
        for item in items {
            typeCount[item.contentType, default: 0] += 1
        }

        let total = Double(items.count)
        return typeCount.map { type, count in
            ContentTypeDistribution(type: type, count: count, percentage: Double(count) / total * 100)
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Peak Usage Hours

    func peakUsageHours() -> [HourlyDistribution] {
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let items = try? modelContext.fetch(descriptor) else { return [] }

        let calendar = Calendar.current
        var hourCount: [Int: Int] = [:]
        for item in items {
            let hour = calendar.component(.hour, from: item.createdAt)
            hourCount[hour, default: 0] += 1
        }

        return (0..<24).map { hour in
            HourlyDistribution(hour: hour, count: hourCount[hour] ?? 0)
        }
    }

    // MARK: - Top Source Apps

    func topSourceApps(limit: Int = 10) -> [AppUsage] {
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let items = try? modelContext.fetch(descriptor) else { return [] }

        var appCount: [String: (bundleID: String?, count: Int)] = [:]
        for item in items {
            let name = item.sourceAppName ?? "Unknown"
            let existing = appCount[name]
            appCount[name] = (item.sourceAppBundleID, (existing?.count ?? 0) + 1)
        }

        return appCount
            .map { AppUsage(appName: $0.key, bundleID: $0.value.bundleID, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Most Re-used Items

    func mostReusedItems(limit: Int = 10) -> [ClipboardItem] {
        var descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        guard let items = try? modelContext.fetch(descriptor) else { return [] }
        return items.filter { $0.useCount > 0 }
    }

    // MARK: - Summary Stats

    func totalItemsStored() -> Int {
        let descriptor = FetchDescriptor<ClipboardItem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func totalItemsToday() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let items = try? modelContext.fetch(descriptor) else { return 0 }
        return items.filter { $0.createdAt >= startOfDay }.count
    }

    func averageCopiesPerDay(lastDays: Int = 30) -> Double {
        let daily = copiesPerDay(lastDays: lastDays)
        guard !daily.isEmpty else { return 0 }
        let total = daily.reduce(0) { $0 + $1.count }
        return Double(total) / Double(daily.count)
    }
}
