import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isFocused ? .secondary : .tertiary)

            TextField("Search your clipboard...", text: $text)
                .textFieldStyle(.plain)
                .font(Constants.Typography.search)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    withAnimation(Constants.Animation.quick) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isFocused
                                ? Color.accentColor.opacity(0.4)
                                : Color.primary.opacity(isHovered ? 0.08 : 0.04),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(isFocused ? 0.06 : 0), radius: 8, y: 2)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(Constants.Animation.quick, value: isFocused)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search clipboard history")
        .onAppear {
            isFocused = true
        }
    }
}
