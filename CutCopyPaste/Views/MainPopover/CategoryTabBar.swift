import SwiftUI

enum CategoryFilter: String, CaseIterable, Identifiable {
    case all
    case text
    case images
    case links
    case pinned
    case snippets

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:    return "All"
        case .text:   return "Text"
        case .images: return "Images"
        case .links:  return "Links"
        case .pinned:   return "Pinned"
        case .snippets: return "Snippets"
        }
    }

    var systemImage: String {
        switch self {
        case .all:      return "square.grid.2x2"
        case .text:     return "doc.text"
        case .images:   return "photo"
        case .links:    return "link"
        case .pinned:   return "pin.fill"
        case .snippets: return "text.badge.plus"
        }
    }

    var itemType: ClipboardItemType? {
        switch self {
        case .all, .pinned, .snippets: return nil
        case .text:                    return .text
        case .images:                  return .image
        case .links:                   return .link
        }
    }
}

struct CategoryTabBar: View {
    @Binding var selection: CategoryFilter
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(CategoryFilter.allCases) { category in
                Button {
                    withAnimation(Constants.Animation.snappy) {
                        selection = category
                    }
                } label: {
                    let isSelected = selection == category
                    HStack(spacing: 3) {
                        Image(systemName: category.systemImage)
                            .font(.system(size: 10, weight: .semibold))
                        Text(category.displayName)
                            .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(category.displayName)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }
}
