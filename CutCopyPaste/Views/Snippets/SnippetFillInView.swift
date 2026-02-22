import SwiftUI

struct SnippetFillInView: View {
    let snippet: Snippet
    let onInsert: ([String: String]) -> Void
    let onDismiss: () -> Void

    @State private var variables: [String: String] = [:]

    private var userPlaceholders: [String] {
        let builtIn = Set(["date", "time", "clipboard", "uuid", "timestamp"])
        return snippet.placeholders.filter { !builtIn.contains($0) }
    }

    private var preview: String {
        var result = snippet.content
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value.isEmpty ? "{{\(key)}}" : value)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        result = result.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: Date()))
        result = result.replacingOccurrences(of: "{{time}}", with: timeFormatter.string(from: Date()))
        result = result.replacingOccurrences(of: "{{clipboard}}", with: "[clipboard]")
        result = result.replacingOccurrences(of: "{{uuid}}", with: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
        result = result.replacingOccurrences(of: "{{timestamp}}", with: ISO8601DateFormatter().string(from: Date()))
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fill In Variables")
                        .font(.system(size: 13, weight: .semibold))
                    Text(snippet.title)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
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
                VStack(alignment: .leading, spacing: 14) {
                    if userPlaceholders.isEmpty {
                        Text("This snippet has no custom variables.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(userPlaceholders, id: \.self) { placeholder in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(placeholder)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                TextField("Enter value", text: Binding(
                                    get: { variables[placeholder] ?? "" },
                                    set: { variables[placeholder] = $0 }
                                ))
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
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
                Spacer()
                Button("Cancel") { onDismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Insert & Copy") {
                    onInsert(variables)
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
