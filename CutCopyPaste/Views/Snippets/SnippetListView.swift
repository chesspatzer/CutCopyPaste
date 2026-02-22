import SwiftUI

struct SnippetListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEditor = false
    @State private var editingSnippet: Snippet?
    @State private var fillInSnippet: Snippet?
    @State private var searchText = ""

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Add button
                HStack {
                    Text("\(filteredSnippets.count) snippets")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        editingSnippet = nil
                        withAnimation(Constants.Animation.snappy) {
                            showEditor = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("New Snippet")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

                // Snippet list
                if filteredSnippets.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(.quaternary)
                        Text("No snippets yet")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredSnippets) { snippet in
                                SnippetRow(snippet: snippet) {
                                    if snippet.placeholders.isEmpty {
                                        appState.insertSnippet(snippet, variables: [:])
                                    } else {
                                        withAnimation(Constants.Animation.snappy) {
                                            fillInSnippet = snippet
                                        }
                                    }
                                } onEdit: {
                                    editingSnippet = snippet
                                    withAnimation(Constants.Animation.snappy) {
                                        showEditor = true
                                    }
                                } onDelete: {
                                    Task { await appState.snippetService.delete(snippet.id) }
                                    Task { await appState.refreshSnippets() }
                                }
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                }
            }

            // Overlay-based editor (replaces .sheet)
            if showEditor {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(Constants.Animation.snappy) {
                            showEditor = false
                        }
                    }

                SnippetEditorView(
                    snippet: editingSnippet,
                    onSave: {
                        Task { await appState.refreshSnippets() }
                    },
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            showEditor = false
                        }
                    }
                )
                .environmentObject(appState)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            // Overlay-based fill-in view (replaces .sheet)
            if let snippet = fillInSnippet {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(Constants.Animation.snappy) {
                            fillInSnippet = nil
                        }
                    }

                SnippetFillInView(
                    snippet: snippet,
                    onInsert: { variables in
                        appState.insertSnippet(snippet, variables: variables)
                    },
                    onDismiss: {
                        withAnimation(Constants.Animation.snappy) {
                            fillInSnippet = nil
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
    }

    private var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return appState.snippets
        }
        let query = searchText.lowercased()
        return appState.snippets.filter {
            $0.title.lowercased().contains(query) || $0.content.lowercased().contains(query)
        }
    }
}

private struct SnippetRow: View {
    let snippet: Snippet
    let onInsert: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(snippet.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if snippet.isBuiltIn {
                        Text("Built-in")
                            .font(.system(size: 8, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                            .foregroundStyle(.blue)
                    }
                }
                Text(snippet.content)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 3) {
                    Button { onInsert() } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 11))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Insert")

                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Edit")

                    if !snippet.isBuiltIn {
                        Button { onDelete() } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadius, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        }
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) { onInsert() }
        .animation(Constants.Animation.quick, value: isHovered)
    }
}

extension Snippet: @retroactive Identifiable {}
