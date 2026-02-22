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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(CategoryFilter.allCases) { category in
                    let isSelected = selection == category
                    Button {
                        withAnimation(Constants.Animation.snappy) {
                            selection = category
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 10, weight: .medium))
                            Text(category.displayName)
                                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .background {
                            Capsule()
                                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
