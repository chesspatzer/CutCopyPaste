import Foundation
import SwiftData
import AppKit
import os

@ModelActor
actor SnippetService {
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "SnippetService")

    // MARK: - Snippets

    func fetchSnippets(folderID: UUID? = nil, searchText: String = "") -> [Snippet] {
        var descriptor = FetchDescriptor<Snippet>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.title)]
        )
        guard var items = try? modelContext.fetch(descriptor) else { return [] }

        if let folderID {
            items = items.filter { $0.folderID == folderID }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(query)
                || $0.content.lowercased().contains(query)
            }
        }

        return items
    }

    func save(_ snippet: Snippet) {
        modelContext.insert(snippet)
        try? modelContext.save()
        logger.debug("Saved snippet: \(snippet.title)")
    }

    func update(_ snippetID: UUID, title: String, content: String, folderID: UUID?) {
        guard let snippet = fetchSnippetByID(snippetID) else { return }
        snippet.title = title
        snippet.content = content
        snippet.folderID = folderID
        try? modelContext.save()
    }

    func delete(_ snippetID: UUID) {
        guard let snippet = fetchSnippetByID(snippetID) else { return }
        modelContext.delete(snippet)
        try? modelContext.save()
    }

    func touchSnippet(_ snippetID: UUID) {
        guard let snippet = fetchSnippetByID(snippetID) else { return }
        snippet.lastUsedAt = Date()
        snippet.useCount += 1
        try? modelContext.save()
    }

    // MARK: - Folders

    func fetchFolders() -> [SnippetFolder] {
        let descriptor = FetchDescriptor<SnippetFolder>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func saveFolder(_ folder: SnippetFolder) {
        modelContext.insert(folder)
        try? modelContext.save()
    }

    func deleteFolder(_ folderID: UUID) {
        // Move snippets in this folder to uncategorized
        let snippets = fetchSnippets(folderID: folderID)
        for snippet in snippets {
            snippet.folderID = nil
        }

        let descriptor = FetchDescriptor<SnippetFolder>(
            predicate: #Predicate { $0.id == folderID }
        )
        if let folder = (try? modelContext.fetch(descriptor))?.first {
            modelContext.delete(folder)
        }
        try? modelContext.save()
    }

    // MARK: - Template Resolution

    func resolveTemplate(_ snippet: Snippet, variables: [String: String]) -> String {
        var result = snippet.content

        // Built-in variables
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let builtIn: [String: String] = [
            "date": dateFormatter.string(from: Date()),
            "time": timeFormatter.string(from: Date()),
            "clipboard": NSPasteboard.general.string(forType: .string) ?? "",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "uuid": UUID().uuidString,
        ]

        // Replace all placeholders
        let allVars = builtIn.merging(variables) { _, user in user }
        for (key, value) in allVars {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        return result
    }

    // MARK: - Seeding

    func seedBuiltInSnippets() {
        let existing = fetchSnippets()
        guard existing.filter({ $0.isBuiltIn }).isEmpty else { return }

        let builtIns: [(String, String)] = [
            ("Date Stamp", "{{date}} {{time}}"),
            ("Code Comment Block", "// MARK: - {{section}}\n// TODO: {{description}}"),
            ("Bug Report", "## Bug Report\n**Steps to reproduce:**\n1. {{steps}}\n**Expected:** {{expected}}\n**Actual:** {{actual}}"),
            ("Email Reply", "Hi {{name}},\n\nThank you for your email regarding {{topic}}.\n\n{{clipboard}}\n\nBest regards"),
            ("Console Log", "print(\"DEBUG [\\(#function)] {{variable}} = \\({{variable}})\")"),
            ("Guard Statement", "guard let {{variable}} = {{variable}} else {\n    return\n}"),
        ]

        for (index, (title, content)) in builtIns.enumerated() {
            let snippet = Snippet(title: title, content: content, isBuiltIn: true, sortOrder: index)
            modelContext.insert(snippet)
        }
        try? modelContext.save()
        logger.info("Seeded \(builtIns.count) built-in snippets")
    }

    // MARK: - Helpers

    private func fetchSnippetByID(_ id: UUID) -> Snippet? {
        let descriptor = FetchDescriptor<Snippet>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}
