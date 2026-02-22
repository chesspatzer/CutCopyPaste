import ArgumentParser
import Foundation
import AppKit

@available(macOS 14, *)
@main
struct CCPCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ccp",
        abstract: "CutCopyPaste CLI — interact with your clipboard history from the terminal.",
        subcommands: [List.self, Copy.self, Paste.self, Search.self],
        defaultSubcommand: List.self
    )
}

// MARK: - List

@available(macOS 14, *)
extension CCPCommand {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List recent clipboard items")

        @Option(name: .shortAndLong, help: "Number of items to show")
        var count: Int = 10

        @Flag(name: .shortAndLong, help: "Show full content instead of truncated preview")
        var full: Bool = false

        mutating func run() throws {
            let service = try CLIStorageService()
            let items = try MainActor.assumeIsolated {
                try service.fetchRecentItems(limit: count)
            }

            if items.isEmpty {
                print("No clipboard items found.")
                return
            }

            for (index, item) in items.enumerated() {
                let typeLabel = item.contentType.rawValue.padding(toLength: 6, withPad: " ", startingAt: 0)
                let date = item.createdAt.formatted(date: .abbreviated, time: .shortened)
                let content: String
                if full {
                    content = item.textContent ?? item.preview
                } else {
                    content = String((item.textContent ?? item.preview).prefix(80))
                        .replacingOccurrences(of: "\n", with: "\\n")
                }

                let pinned = item.isPinned ? " 📌" : ""
                let source = item.sourceAppName.map { " [\($0)]" } ?? ""
                print("[\(index)] \(typeLabel) \(date)\(source)\(pinned)")
                print("    \(content)")
                if index < items.count - 1 { print() }
            }
        }
    }
}

// MARK: - Copy

@available(macOS 14, *)
extension CCPCommand {
    struct Copy: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Add text to clipboard history")

        @Argument(help: "The text to add to clipboard history")
        var text: String

        mutating func run() throws {
            let service = try CLIStorageService()
            try MainActor.assumeIsolated {
                try service.addTextItem(text)
            }

            // Also place on system pasteboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

            print("Copied to clipboard and saved to history.")
        }
    }
}

// MARK: - Paste

@available(macOS 14, *)
extension CCPCommand {
    struct Paste: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Output a clipboard item from history")

        @Argument(help: "Index of the item to paste (0 = most recent)")
        var index: Int = 0

        mutating func run() throws {
            let service = try CLIStorageService()
            let item = try MainActor.assumeIsolated {
                try service.getItem(at: index)
            }

            guard let item else {
                print("No item at index \(index).", to: &StandardError.shared)
                throw ExitCode.failure
            }

            if let text = item.textContent {
                print(text, terminator: "")
            } else if let filePaths = item.filePaths {
                for path in filePaths {
                    print(path)
                }
            } else {
                print("Item at index \(index) has no text content.", to: &StandardError.shared)
                throw ExitCode.failure
            }
        }
    }
}

// MARK: - Search

@available(macOS 14, *)
extension CCPCommand {
    struct Search: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Search clipboard history")

        @Argument(help: "Search query")
        var query: String

        mutating func run() throws {
            let service = try CLIStorageService()
            let items = try MainActor.assumeIsolated {
                try service.searchItems(query: query)
            }

            if items.isEmpty {
                print("No items matching \"\(query)\".")
                return
            }

            print("Found \(items.count) item(s) matching \"\(query)\":\n")
            for (index, item) in items.enumerated() {
                let date = item.createdAt.formatted(date: .abbreviated, time: .shortened)
                let content = String((item.textContent ?? item.preview).prefix(100))
                    .replacingOccurrences(of: "\n", with: "\\n")
                print("[\(index)] \(date)")
                print("    \(content)")
                if index < items.count - 1 { print() }
            }
        }
    }
}

// MARK: - Stderr Helper

struct StandardError: TextOutputStream {
    static var shared = StandardError()
    mutating func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
