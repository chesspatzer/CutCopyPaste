import AppKit

/// Handles exporting and sharing clipboard items in various formats.
final class ShareService {
    static let shared = ShareService()
    private init() {}

    // MARK: - Export to File

    /// Opens NSSavePanel to save item content to a file.
    @MainActor
    func exportToFile(_ item: ClipboardItem) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true

        switch item.contentType {
        case .text, .richText, .link:
            panel.allowedContentTypes = [.plainText]
            panel.nameFieldStringValue = "clipboard-export.txt"
        case .image:
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "clipboard-export.png"
        case .file:
            return // Files already exist on disk
        }

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                switch item.contentType {
                case .text, .richText, .link:
                    guard let text = item.textContent else { return }
                    try text.write(to: url, atomically: true, encoding: .utf8)
                case .image:
                    guard let data = item.imageData else { return }
                    try data.write(to: url)
                case .file:
                    break
                }
            } catch {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Export Failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    // MARK: - Slack Format

    /// Formats text as a Slack code snippet (triple backtick block).
    func formatForSlack(_ text: String, language: String?) -> String {
        let lang = language ?? ""
        return "```\(lang)\n\(text)\n```"
    }

    // MARK: - Discord Format

    /// Formats text as a Discord code block.
    func formatForDiscord(_ text: String, language: String?) -> String {
        let lang = language ?? ""
        return "```\(lang)\n\(text)\n```"
    }

    // MARK: - Markdown Link

    /// Formats a URL as a markdown link.
    func formatAsMarkdownLink(_ urlString: String) -> String {
        let url = URL(string: urlString)
        let domain = url?.host ?? urlString
        return "[\(domain)](\(urlString))"
    }

    // MARK: - GitHub Gist

    /// Attempts to create a GitHub Gist using the `gh` CLI.
    /// Returns the gist URL if successful, nil if gh is not available.
    func createGist(_ text: String, filename: String, description: String) -> String? {
        #if APPSTORE
        // Subprocess execution is not allowed in App Sandbox
        return nil
        #else
        // Write content to a temp file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(filename)

        do {
            try text.write(to: tempFile, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        // Try gh gist create
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "gist", "create", tempFile.path, "--desc", description, "--public"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // gh not available
        }

        return nil
        #endif
    }
}
