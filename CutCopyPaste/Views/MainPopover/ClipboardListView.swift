import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let displayMode: DisplayMode
    let showTimestamps: Bool
    let showSourceApp: Bool
    let onCopy: (ClipboardItem) -> Void
    let onAutoPaste: (ClipboardItem) -> Void
    let onPin: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void

    @AppStorage("timeGroupedHistory") private var timeGroupedHistory: Bool = true
    @State private var selectedIndex: Int? = nil

    private var selectedItemID: UUID? {
        guard let idx = selectedIndex, idx < items.count else { return nil }
        return items[idx].id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if timeGroupedHistory {
                    groupedContent
                } else {
                    flatContent
                }
            }
            .scrollIndicators(.hidden)
            .onKeyPress(.upArrow) {
                moveSelection(by: -1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.downArrow) {
                moveSelection(by: 1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.return) {
                if let index = selectedIndex, index < items.count {
                    onAutoPaste(items[index])
                }
                return .handled
            }
            .onKeyPress(.escape) {
                selectedIndex = nil
                return .handled
            }
            .onChange(of: items.count) {
                selectedIndex = nil
            }
        }
    }

    // MARK: - Flat List (no grouping)

    private var flatContent: some View {
        LazyVStack(spacing: displayMode == .compact ? 3 : Constants.UI.cardSpacing) {
            ForEach(items) { item in
                itemRow(item)
            }
        }
        .padding(.horizontal, displayMode == .compact ? 6 : 10)
        .padding(.vertical, displayMode == .compact ? 4 : 6)
    }

    // MARK: - Time-Grouped List

    private var groupedContent: some View {
        let sections = TimeGrouper.group(items)
        return LazyVStack(spacing: displayMode == .compact ? 3 : Constants.UI.cardSpacing) {
            ForEach(sections) { section in
                // Section header
                HStack(spacing: 6) {
                    Text(section.title)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.primary.opacity(0.10))
                        .frame(height: 0.5)
                    Text("\(section.items.count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, displayMode == .compact ? 8 : 12)
                .padding(.top, section.id == sections.first?.id ? 4 : 10)
                .padding(.bottom, 2)

                ForEach(section.items) { item in
                    itemRow(item)
                }
            }
        }
        .padding(.horizontal, displayMode == .compact ? 6 : 10)
        .padding(.vertical, displayMode == .compact ? 4 : 6)
    }

    // MARK: - Item Row

    @ViewBuilder
    private func itemRow(_ item: ClipboardItem) -> some View {
        ClipboardItemRow(
            item: item,
            displayMode: displayMode,
            showTimestamps: showTimestamps,
            showSourceApp: showSourceApp,
            isSelected: item.id == selectedItemID,
            onCopy: { onCopy(item) },
            onAutoPaste: { onAutoPaste(item) },
            onPin: { onPin(item) },
            onDelete: {
                withAnimation(Constants.Animation.snappy) {
                    onDelete(item)
                }
            }
        )
        .id(item.id)
    }

    private func moveSelection(by offset: Int, proxy: ScrollViewProxy) {
        let newIndex: Int
        if let current = selectedIndex {
            newIndex = max(0, min(items.count - 1, current + offset))
        } else {
            newIndex = offset > 0 ? 0 : items.count - 1
        }

        withAnimation(Constants.Animation.quick) {
            selectedIndex = newIndex
        }

        if newIndex < items.count {
            withAnimation(Constants.Animation.quick) {
                proxy.scrollTo(items[newIndex].id, anchor: .center)
            }
        }
    }
}
