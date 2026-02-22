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

    @State private var selectedIndex: Int? = nil
    @State private var appearedIDs: Set<UUID> = []
    @State private var appearCounter: Int = 0

    private var selectedItemID: UUID? {
        guard let idx = selectedIndex, idx < items.count else { return nil }
        return items[idx].id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Constants.UI.cardSpacing) {
                    ForEach(items) { item in
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
                        .opacity(appearedIDs.contains(item.id) ? 1 : 0)
                        .offset(y: appearedIDs.contains(item.id) ? 0 : 6)
                        .onAppear {
                            if !appearedIDs.contains(item.id) {
                                let order = appearCounter
                                appearCounter += 1
                                let delay = Double(min(order, 10)) * Constants.Animation.staggerDelay
                                withAnimation(Constants.Animation.smooth.delay(delay)) {
                                    appearedIDs.insert(item.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
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
                // Reset selection when item count changes (search, category switch, delete)
                selectedIndex = nil
                appearCounter = 0
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
