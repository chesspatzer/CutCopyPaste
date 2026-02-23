import AppKit
import os

struct WorkspaceContext: Equatable {
    let path: String?
    let name: String
    let type: WorkspaceType

    enum WorkspaceType: String {
        case xcode
        case vscode
        case terminal
        case finder
        case general
    }
}

final class WorkspaceDetector {
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "WorkspaceDetector")

    func detectCurrentWorkspace() -> WorkspaceContext? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return nil }

        let windowTitle = getFrontmostWindowTitle(pid: app.processIdentifier)

        switch bundleID {
        case "com.apple.dt.Xcode":
            return detectXcodeWorkspace(windowTitle: windowTitle)
        case "com.microsoft.VSCode", "com.microsoft.VSCodeInsiders":
            return detectVSCodeWorkspace(windowTitle: windowTitle)
        case "com.apple.Terminal", "com.googlecode.iterm2":
            return detectTerminalWorkspace(windowTitle: windowTitle, bundleID: bundleID)
        case "com.apple.finder":
            return detectFinderWorkspace(windowTitle: windowTitle)
        default:
            // Generic apps don't have meaningful workspace context
            return nil
        }
    }

    // MARK: - Window Title Extraction

    private func getFrontmostWindowTitle(pid: pid_t) -> String? {
        #if APPSTORE
        // CGWindowListCopyWindowInfo is not available in App Sandbox
        return nil
        #else
        let options: CGWindowListOption = [.excludeDesktopElements, .optionOnScreenOnly]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        return windowList.first {
            ($0[kCGWindowOwnerPID as String] as? Int32) == pid
                && ($0[kCGWindowLayer as String] as? Int) == 0
        }.flatMap {
            $0[kCGWindowName as String] as? String
        }
        #endif
    }

    // MARK: - App-specific detection

    private func detectXcodeWorkspace(windowTitle: String?) -> WorkspaceContext {
        // Xcode window title format: "ProjectName — TargetName" or "FileName — ProjectName"
        if let title = windowTitle {
            let parts = title.components(separatedBy: " — ")
            let projectName = parts.count > 1 ? parts.last! : parts.first!
            let cleaned = projectName
                .replacingOccurrences(of: " (Edited)", with: "")
                .trimmingCharacters(in: .whitespaces)
            return WorkspaceContext(path: nil, name: cleaned, type: .xcode)
        }
        return WorkspaceContext(path: nil, name: "Xcode", type: .xcode)
    }

    private func detectVSCodeWorkspace(windowTitle: String?) -> WorkspaceContext {
        // VS Code title format: "filename — foldername — Visual Studio Code"
        if let title = windowTitle {
            let parts = title.components(separatedBy: " — ")
            if parts.count >= 2 {
                let workspace = parts[parts.count - 2]
                    .replacingOccurrences(of: " [Extension Development Host]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return WorkspaceContext(path: nil, name: workspace, type: .vscode)
            }
        }
        return WorkspaceContext(path: nil, name: "VS Code", type: .vscode)
    }

    private func detectTerminalWorkspace(windowTitle: String?, bundleID: String) -> WorkspaceContext {
        // Terminal title often contains the cwd
        if let title = windowTitle {
            // Common patterns: "user@host: /path/to/dir" or "~ — bash — 80x24"
            if let pathRange = title.range(of: "(?:/[^\\s:]+)+", options: .regularExpression) {
                let path = String(title[pathRange])
                let name = (path as NSString).lastPathComponent
                return WorkspaceContext(path: path, name: name, type: .terminal)
            }
            // Home dir shorthand
            if title.contains("~") {
                return WorkspaceContext(
                    path: NSHomeDirectory(),
                    name: "Home",
                    type: .terminal
                )
            }
        }
        return WorkspaceContext(path: nil, name: "Terminal", type: .terminal)
    }

    private func detectFinderWorkspace(windowTitle: String?) -> WorkspaceContext {
        if let title = windowTitle, !title.isEmpty {
            return WorkspaceContext(path: nil, name: title, type: .finder)
        }
        return WorkspaceContext(path: nil, name: "Finder", type: .finder)
    }
}
