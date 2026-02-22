import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let displayMode: DisplayMode
    let showTimestamps: Bool
    let showSourceApp: Bool
    let onCopy: (ClipboardItem) -> Void
    let onPin: (ClipboardItem) -> Void
    let onDelete: (ClipboardItem) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var appearedIDs: Set<UUID> = []

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Constants.UI.cardSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemRow(
                            item: item,
                            displayMode: displayMode,
                            showTimestamps: showTimestamps,
                            showSourceApp: showSourceApp,
                            isSelected: selectedIndex == index,
                            onCopy: { onCopy(item) },
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
                                let delay = Double(min(index, 15)) * Constants.Animation.staggerDelay
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
                    onCopy(items[index])
                }
                return .handled
            }
            .onKeyPress(.escape) {
                selectedIndex = nil
                return .handled
            }
            .onChange(of: items.map(\.id)) {
                // Reset selection when items change (search, category switch)
                selectedIndex = nil
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
