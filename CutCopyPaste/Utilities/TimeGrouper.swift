import Foundation

/// Groups clipboard items by time period for sectioned display.
enum TimeGrouper {
    struct Section: Identifiable {
        let id: String
        let title: String
        let items: [ClipboardItem]
    }

    /// Groups items into time-based sections. Pinned items are placed in a "Pinned" section first.
    static func group(_ items: [ClipboardItem]) -> [Section] {
        var sections: [Section] = []

        // Separate pinned items
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }

        if !pinned.isEmpty {
            sections.append(Section(id: "pinned", title: "Pinned", items: pinned))
        }

        // Group remaining by time period
        let calendar = Calendar.current
        let now = Date()

        var justNow: [ClipboardItem] = []
        var today: [ClipboardItem] = []
        var yesterday: [ClipboardItem] = []
        var thisWeek: [ClipboardItem] = []
        var thisMonth: [ClipboardItem] = []
        var earlier: [ClipboardItem] = []

        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? startOfToday
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? startOfToday

        for item in unpinned {
            let date = item.createdAt
            if date >= fiveMinutesAgo {
                justNow.append(item)
            } else if date >= startOfToday {
                today.append(item)
            } else if date >= startOfYesterday {
                yesterday.append(item)
            } else if date >= startOfWeek {
                thisWeek.append(item)
            } else if date >= startOfMonth {
                thisMonth.append(item)
            } else {
                earlier.append(item)
            }
        }

        if !justNow.isEmpty { sections.append(Section(id: "just_now", title: "Just Now", items: justNow)) }
        if !today.isEmpty { sections.append(Section(id: "today", title: "Today", items: today)) }
        if !yesterday.isEmpty { sections.append(Section(id: "yesterday", title: "Yesterday", items: yesterday)) }
        if !thisWeek.isEmpty { sections.append(Section(id: "this_week", title: "This Week", items: thisWeek)) }
        if !thisMonth.isEmpty { sections.append(Section(id: "this_month", title: "This Month", items: thisMonth)) }
        if !earlier.isEmpty { sections.append(Section(id: "earlier", title: "Earlier", items: earlier)) }

        return sections
    }
}
