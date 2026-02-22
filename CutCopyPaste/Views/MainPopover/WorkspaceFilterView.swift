import SwiftUI

struct WorkspaceFilterView: View {
    @EnvironmentObject var appState: AppState
    @State private var cachedWorkspaces: [(name: String, icon: String)] = []
    @State private var lastItemCount: Int = 0

    var body: some View {
        if !cachedWorkspaces.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    WorkspaceChip(
                        name: "All",
                        icon: "tray.full",
                        isSelected: appState.selectedWorkspace == nil
                    ) {
                        withAnimation(Constants.Animation.snappy) {
                            appState.selectedWorkspace = nil
                        }
                    }

                    ForEach(cachedWorkspaces, id: \.name) { workspace in
                        WorkspaceChip(
                            name: workspace.name,
                            icon: workspace.icon,
                            isSelected: appState.selectedWorkspace == workspace.name
                        ) {
                            withAnimation(Constants.Animation.snappy) {
                                appState.selectedWorkspace = appState.selectedWorkspace == workspace.name ? nil : workspace.name
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 6)
        }

        Color.clear.frame(height: 0)
            .onAppear { rebuildWorkspaces() }
            .onChange(of: appState.clipboardItems.count) { rebuildWorkspaces() }
    }

    private func rebuildWorkspaces() {
        let items = appState.clipboardItems
        guard items.count != lastItemCount else { return }
        lastItemCount = items.count

        var seen = Set<String>()
        var result: [(name: String, icon: String)] = []
        for item in items {
            guard let workspace = item.workspaceName,
                  workspace != item.sourceAppName,
                  !seen.contains(workspace) else { continue }
            seen.insert(workspace)
            let icon: String
            switch item.workspaceType {
            case "xcode":   icon = "hammer"
            case "vscode":  icon = "chevron.left.forwardslash.chevron.right"
            case "terminal": icon = "terminal"
            case "finder":  icon = "folder"
            default:        icon = "app"
            }
            result.append((name: workspace, icon: icon))
        }
        cachedWorkspaces = result.sorted { $0.name < $1.name }
    }
}

private struct WorkspaceChip: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(Constants.Typography.micro)
                Text(name)
                    .font(Constants.Typography.chip)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(isSelected ? .primary : .tertiary)
            .background {
                Capsule()
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
            }
        }
        .buttonStyle(.plain)
    }
}
