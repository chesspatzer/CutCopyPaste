import SwiftUI

struct SnippetFolderManagerView: View {
    @EnvironmentObject var appState: AppState
    @State private var newFolderName = ""
    @State private var showAddFolder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Folders")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    showAddFolder.toggle()
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }

            if showAddFolder {
                HStack {
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                    Button("Add") {
                        guard !newFolderName.isEmpty else { return }
                        let folder = SnippetFolder(name: newFolderName)
                        Task {
                            await appState.snippetService.saveFolder(folder)
                            await appState.refreshSnippets()
                        }
                        newFolderName = ""
                        showAddFolder = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(newFolderName.isEmpty)
                }
            }

            if appState.snippetFolders.isEmpty {
                Text("No folders created")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(appState.snippetFolders) { folder in
                    HStack {
                        Image(systemName: folder.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text(folder.name)
                            .font(.system(size: 12))
                        Spacer()
                        Button {
                            Task {
                                await appState.snippetService.deleteFolder(folder.id)
                                await appState.refreshSnippets()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundStyle(.red.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

extension SnippetFolder: @retroactive Identifiable {}
