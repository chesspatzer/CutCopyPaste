import SwiftUI

struct WorkspaceFilterView: View {
    @EnvironmentObject var appState: AppState

    private var workspaces: [String] {
        // Only show workspaces that are actual project names, not just app names
        let meaningful = appState.clipboardItems.filter { item in
            guard let workspace = item.workspaceName else { return false }
            // Exclude if workspace name is the same as the source app (not a real project)
            return workspace != item.sourceAppName
        }
        let names = Set(meaningful.compactMap(\.workspaceName))
        return names.sorted()
    }

    var body: some View {
        if !workspaces.isEmpty {
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

                    ForEach(workspaces, id: \.self) { workspace in
                        WorkspaceChip(
                            name: workspace,
                            icon: workspaceIcon(for: workspace),
                            isSelected: appState.selectedWorkspace == workspace
                        ) {
                            withAnimation(Constants.Animation.snappy) {
                                appState.selectedWorkspace = appState.selectedWorkspace == workspace ? nil : workspace
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
            .padding(.bottom, 6)
        }
    }

    private func workspaceIcon(for workspace: String) -> String {
        let item = appState.clipboardItems.first { $0.workspaceName == workspace }
        switch item?.workspaceType {
        case "xcode":   return "hammer"
        case "vscode":  return "chevron.left.forwardslash.chevron.right"
        case "terminal": return "terminal"
        case "finder":  return "folder"
        default:        return "app"
        }
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
                    .font(.system(size: 9, weight: .semibold))
                Text(name)
                    .font(.system(size: 10, weight: .medium))
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
