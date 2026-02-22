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
            // -- Everyday --
            ("Date & Time Stamp", "{{date}} at {{time}}"),

            ("Meeting Notes", """
            # Meeting Notes — {{date}}

            **Attendees:** {{attendees}}
            **Topic:** {{topic}}

            ## Discussion
            - {{notes}}

            ## Action Items
            - [ ] {{action}}

            ## Next Steps
            {{next}}
            """),

            ("Bug Report", """
            ## Bug Report

            **Title:** {{title}}
            **Severity:** {{severity}}
            **Environment:** {{environment}}

            ### Steps to Reproduce
            1. {{step1}}
            2. {{step2}}
            3. {{step3}}

            ### Expected Behavior
            {{expected}}

            ### Actual Behavior
            {{actual}}

            ### Screenshots / Logs
            {{details}}
            """),

            ("PR Description", """
            ## Summary
            {{summary}}

            ## Changes
            - {{change1}}
            - {{change2}}

            ## Test Plan
            - [ ] {{test1}}
            - [ ] {{test2}}

            ## Screenshots
            {{screenshots}}
            """),

            ("Email Reply", """
            Hi {{name}},

            Thanks for reaching out about {{topic}}.

            {{response}}

            Let me know if you have any questions.

            Best,
            {{sender}}
            """),

            // -- Code --
            ("TODO Comment", "// TODO({{author}}): {{description}} [{{date}}]"),

            ("Function Skeleton", """
            /// {{description}}
            /// - Parameter {{param}}: {{paramDesc}}
            /// - Returns: {{returnDesc}}
            func {{name}}({{param}}: {{paramType}}) -> {{returnType}} {
                {{body}}
            }
            """),

            ("API Request (fetch)", """
            const response = await fetch('{{url}}', {
              method: '{{method}}',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer {{token}}'
              },
              body: JSON.stringify({{body}})
            });
            const data = await response.json();
            """),

            ("Python Script Header", """
            #!/usr/bin/env python3
            \"\"\"{{description}}\"\"\"

            import argparse
            import logging

            logger = logging.getLogger(__name__)


            def main():
                parser = argparse.ArgumentParser(description="{{description}}")
                parser.add_argument("{{arg}}", help="{{argHelp}}")
                args = parser.parse_args()

                {{body}}


            if __name__ == "__main__":
                logging.basicConfig(level=logging.INFO)
                main()
            """),

            ("SQL Query Template", """
            SELECT
                {{columns}}
            FROM {{table}}
            WHERE {{condition}}
            ORDER BY {{orderBy}}
            LIMIT {{limit}};
            """),

            ("Shell Script Header", """
            #!/usr/bin/env bash
            set -euo pipefail

            # {{description}}
            # Usage: ./{{scriptName}} {{args}}

            {{body}}
            """),

            ("Regex Pattern", "/{{pattern}}/{{flags}} — {{description}}"),

            // -- Responses --
            ("Code Review Comment", """
            **{{severity}}**: {{issue}}

            {{suggestion}}

            ```{{language}}
            {{code}}
            ```
            """),

            ("Standup Update", """
            **Yesterday:** {{yesterday}}
            **Today:** {{today}}
            **Blockers:** {{blockers}}
            """),

            ("Changelog Entry", """
            ## [{{version}}] — {{date}}

            ### Added
            - {{added}}

            ### Changed
            - {{changed}}

            ### Fixed
            - {{fixed}}
            """),
        ]

        for (index, (title, content)) in builtIns.enumerated() {
            let snippet = Snippet(title: title, content: content, isBuiltIn: true, sortOrder: index)
            modelContext.insert(snippet)
        }
        try? modelContext.save()
        logger.info("Seeded \(builtIns.count) built-in snippets")
    }

    /// Replace old built-in snippets with the improved set.
    func replaceBuiltInSnippets() {
        let existing = fetchSnippets()
        for snippet in existing where snippet.isBuiltIn {
            modelContext.delete(snippet)
        }
        try? modelContext.save()
        seedBuiltInSnippets()
    }

    // MARK: - Helpers

    private func fetchSnippetByID(_ id: UUID) -> Snippet? {
        let descriptor = FetchDescriptor<Snippet>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}
