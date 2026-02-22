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
    @State private var appearedIDs: Set<UUID> = []
    @State private var appearCounter: Int = 0
    @State private var initialLoadComplete: Bool = false

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
                appearCounter = 0
                initialLoadComplete = false
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
        let alreadyAppeared = appearedIDs.contains(item.id) || initialLoadComplete
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
        .opacity(alreadyAppeared ? 1 : 0)
        .offset(y: alreadyAppeared ? 0 : 6)
        .onAppear {
            if !appearedIDs.contains(item.id) && !initialLoadComplete {
                let order = appearCounter
                appearCounter += 1
                // Only animate the first visible batch (roughly 8 items)
                if order < 8 {
                    let delay = Double(order) * Constants.Animation.staggerDelay
                    withAnimation(Constants.Animation.smooth.delay(delay)) {
                        appearedIDs.insert(item.id)
                    }
                } else {
                    // Skip animation for items beyond the initial batch
                    appearedIDs.insert(item.id)
                    initialLoadComplete = true
                }
            }
        }
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
