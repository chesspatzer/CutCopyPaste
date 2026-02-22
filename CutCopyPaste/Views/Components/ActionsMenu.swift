import SwiftUI

struct ActionsMenu: View {
    let item: ClipboardItem
    @EnvironmentObject var appState: AppState

    var body: some View {
        Menu {
            let transforms = TransformService.shared.applicableTransforms(for: item)
            if !transforms.isEmpty {
                Section("Transform") {
                    ForEach(transforms, id: \.id) { transform in
                        Button {
                            appState.applyTransform(transform, to: item)
                        } label: {
                            Label(transform.name, systemImage: transform.iconSystemName)
                        }
                    }
                }
            }

            let actions = QuickActionService.shared.applicableActions(for: item)
            if !actions.isEmpty {
                Section("Quick Actions") {
                    ForEach(actions, id: \.id) { action in
                        Button {
                            if let result = action.execute(item: item) {
                                appState.copyText(result)
                            }
                        } label: {
                            Label(action.name, systemImage: action.iconSystemName)
                        }
                    }
                }
            }

            if item.contentType == .image && item.ocrText == nil {
                Section("Image") {
                    Button {
                        appState.extractTextFromImage(item)
                    } label: {
                        Label("Extract Text (OCR)", systemImage: "text.viewfinder")
                    }
                }
            }

            if item.sensitiveDataTypes != nil && !(item.sensitiveDataTypes?.isEmpty ?? true) {
                Section("Security") {
                    Button {
                        appState.toggleMask(item)
                    } label: {
                        Label(item.isMasked ? "Unmask Content" : "Mask Content",
                              systemImage: item.isMasked ? "eye" : "eye.slash")
                    }
                }
            }
        } label: {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                }
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help("Transforms & Actions")
    }
}
