import SwiftUI

struct MergeView: View {
    let items: [ClipboardItem]
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState
    @State private var separator: MergeSeparator = .newline
    @State private var customSeparator: String = ""

    enum MergeSeparator: String, CaseIterable {
        case newline = "Newline"
        case space = "Space"
        case comma = "Comma"
        case commaSpace = "Comma + Space"
        case tab = "Tab"
        case custom = "Custom"

        var value: String {
            switch self {
            case .newline: return "\n"
            case .space: return " "
            case .comma: return ","
            case .commaSpace: return ", "
            case .tab: return "\t"
            case .custom: return ""
            }
        }
    }

    private var preview: String {
        let sep = separator == .custom ? customSeparator : separator.value
        return items
            .compactMap(\.textContent)
            .joined(separator: sep)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Merge \(items.count) Clips")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
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
                VStack(alignment: .leading, spacing: 16) {
                    // Items list
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text(item.preview)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            }
                        }
                    }

                    // Separator picker
                    HStack {
                        Text("Separator:")
                            .font(.system(size: 11, weight: .medium))
                        Picker("", selection: $separator) {
                            ForEach(MergeSeparator.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    }

                    if separator == .custom {
                        TextField("Custom separator", text: $customSeparator)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.primary.opacity(0.03))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                    }
                            }
                    }

                    // Preview
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Preview")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        ScrollView {
                            Text(preview)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .frame(height: 70)
                        .background {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(Color.primary.opacity(0.03))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            HStack {
                Text("\(preview.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") { onDismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Copy Merged") {
                    appState.copyText(preview)
                    appState.clearMergeSelection()
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 420)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }
}
