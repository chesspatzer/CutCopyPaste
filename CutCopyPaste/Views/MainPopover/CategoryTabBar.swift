import SwiftUI

enum CategoryFilter: String, CaseIterable, Identifiable {
    case all
    case text
    case images
    case links
    case pinned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:    return "All"
        case .text:   return "Text"
        case .images: return "Images"
        case .links:  return "Links"
        case .pinned: return "Pinned"
        }
    }

    var systemImage: String {
        switch self {
        case .all:    return "square.grid.2x2"
        case .text:   return "doc.text"
        case .images: return "photo"
        case .links:  return "link"
        case .pinned: return "pin.fill"
        }
    }

    var itemType: ClipboardItemType? {
        switch self {
        case .all, .pinned: return nil
        case .text:         return .text
        case .images:       return .image
        case .links:        return .link
        }
    }
}

struct CategoryTabBar: View {
    @Binding var selection: CategoryFilter
    @Namespace private var tabNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CategoryFilter.allCases) { category in
                Button {
                    withAnimation(Constants.Animation.snappy) {
                        selection = category
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: category.systemImage)
                            .font(.system(size: 10, weight: .semibold))
                        Text(category.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(selection == category ? .primary : .tertiary)
                    .background {
                        if selection == category {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }
}
