import SwiftUI

struct SmartCollectionsView: View {
    let onSelect: (SmartCollection) -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Smart Collections")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if appState.activeSmartCollection != nil {
                    Button {
                        appState.activeSmartCollection = nil
                        appState.refreshItems()
                        onDismiss()
                    } label: {
                        Text("Clear Filter")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(SmartCollectionService.shared.collections) { collection in
                        let count = countFor(collection)
                        let isActive = appState.activeSmartCollection?.id == collection.id
                        CollectionCard(
                            collection: collection,
                            count: count,
                            isActive: isActive
                        ) {
                            onSelect(collection)
                        }
                    }
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func countFor(_ collection: SmartCollection) -> Int {
        appState.clipboardItems.filter(collection.predicate).count
    }
}

private struct CollectionCard: View {
    let collection: SmartCollection
    let count: Int
    let isActive: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: collection.systemImage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isActive ? .white : .accentColor)
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
                }

                Text(collection.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? .white : .primary)
                    .lineLimit(1)

                Text(collection.description)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(isActive ? .white.opacity(0.7) : .secondary.opacity(0.6))
                    .lineLimit(2)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? Color.accentColor : Color.primary.opacity(isHovered ? 0.06 : 0.03))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isActive ? Color.accentColor : Color.primary.opacity(0.06), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
