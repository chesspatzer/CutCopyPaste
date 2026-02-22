import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Binding var searchMode: SearchMode
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    @State private var isInvalidRegex = false

    private var isRegex: Bool { searchMode == .regex }

    private var modeIcon: String {
        isRegex ? "chevron.left.forwardslash.chevron.right" : "magnifyingglass"
    }

    private var modeIconColor: Color {
        isRegex ? Color.accentColor : (isFocused ? Color.secondary : Color.gray)
    }

    private var modeBackground: Color {
        isRegex ? Color.accentColor.opacity(0.12) : Color.clear
    }

    private var borderColor: Color {
        if isInvalidRegex { return Color.orange.opacity(0.6) }
        if isFocused { return Color.accentColor.opacity(0.5) }
        return Color.primary.opacity(isHovered ? 0.14 : 0.08)
    }

    private var searchFont: Font {
        isRegex ? .system(size: 13, weight: .regular, design: .monospaced) : Constants.Typography.search
    }

    var body: some View {
        HStack(spacing: 6) {
            modeToggleButton
            searchTextField
            regexWarning
            clearButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background { searchBackground }
        .onHover { isHovered = $0 }
        .animation(Constants.Animation.quick, value: isFocused)
        .animation(Constants.Animation.quick, value: searchMode)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search clipboard history")
        .onAppear { isFocused = true }
        .onChange(of: text) {
            if isRegex && !text.isEmpty {
                isInvalidRegex = (try? NSRegularExpression(pattern: text)) == nil
            } else {
                isInvalidRegex = false
            }
        }
    }

    private var modeToggleButton: some View {
        Button {
            withAnimation(Constants.Animation.quick) {
                searchMode = isRegex ? .natural : .regex
                isInvalidRegex = false
            }
        } label: {
            Image(systemName: modeIcon)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(modeIconColor)
                .frame(width: 22, height: 22)
                .background(Circle().fill(modeBackground))
        }
        .buttonStyle(.plain)
        .help(isRegex ? "Regex mode (click for natural)" : "Natural language (click for regex)")
    }

    private var searchTextField: some View {
        TextField(isRegex ? "Regex pattern..." : "Search your clipboard...", text: $text)
            .textFieldStyle(.plain)
            .font(searchFont)
            .focused($isFocused)
    }

    @ViewBuilder
    private var regexWarning: some View {
        if isInvalidRegex {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(.orange)
                .help("Invalid regex pattern")
                .transition(.scale.combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var clearButton: some View {
        if !text.isEmpty {
            Button {
                withAnimation(Constants.Animation.quick) {
                    text = ""
                    isInvalidRegex = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var searchBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(isFocused ? 0.06 : 0), radius: 8, y: 2)
    }
}
