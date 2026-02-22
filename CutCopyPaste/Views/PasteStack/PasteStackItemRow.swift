import SwiftUI

struct PasteStackItemRow: View {
    let item: PasteStackManager.PasteStackItem
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TypeBadge(type: item.contentType)

            Text(item.preview)
                .font(.system(size: 11))
                .lineLimit(1)
                .foregroundStyle(.primary.opacity(0.85))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
