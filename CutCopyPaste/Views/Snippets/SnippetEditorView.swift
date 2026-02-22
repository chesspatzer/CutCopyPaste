import SwiftUI

struct SnippetEditorView: View {
    let snippet: Snippet?
    let onSave: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedFolderID: UUID?

    var isEditing: Bool { snippet != nil }

    private let builtInVars: Set<String> = ["date", "time", "clipboard", "uuid", "timestamp"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? "Edit Snippet" : "New Snippet")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Use {{placeholder}} syntax for variables")
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

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Title")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Bug Report Template", text: $title)
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

                    // Content editor
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Content")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        TextEditor(text: $content)
                            .font(.system(size: 11.5, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(minHeight: 120, maxHeight: 180)
                            .background {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.primary.opacity(0.03))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                    }
                            }
                    }

                    // Detected placeholders
                    if !userPlaceholders.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Custom Variables")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                ForEach(userPlaceholders, id: \.self) { placeholder in
                                    Text(placeholder)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background {
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.1))
                                        }
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }

                    // Built-in variables hint
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 9))
                        Text("Built-in: {{date}}, {{time}}, {{clipboard}}, {{uuid}}, {{timestamp}}")
                            .font(.system(size: 9.5))
                    }
                    .foregroundStyle(.quaternary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            // Footer buttons
            HStack {
                Spacer()
                Button("Cancel") { onDismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button(isEditing ? "Update" : "Create") {
                    save()
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(title.isEmpty || content.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if let snippet {
                title = snippet.title
                content = snippet.content
                selectedFolderID = snippet.folderID
            }
        }
    }

    private var userPlaceholders: [String] {
        let pattern = "\\{\\{(\\w+)\\}\\}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        var seen = Set<String>()
        var result: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let name = String(content[range])
                if !builtInVars.contains(name), seen.insert(name).inserted {
                    result.append(name)
                }
            }
        }
        return result
    }

    private func save() {
        Task {
            if let snippet {
                await appState.snippetService.update(snippet.id, title: title, content: content, folderID: selectedFolderID)
            } else {
                let newSnippet = Snippet(title: title, content: content, folderID: selectedFolderID)
                await appState.snippetService.save(newSnippet)
            }
            onSave()
        }
    }
}
