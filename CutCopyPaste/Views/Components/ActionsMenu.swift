import SwiftUI

struct ActionsMenu: View {
    let item: ClipboardItem
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

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

            // Copy as... formats
            if let text = item.textContent {
                Section("Copy as...") {
                    ForEach(CopyFormat.allCases, id: \.rawValue) { format in
                        Button {
                            appState.copyFormattedText(text, format: format)
                        } label: {
                            Label(format.displayName, systemImage: format.systemImage)
                        }
                    }

                    // Markdown code block with detected language
                    if let lang = item.detectedLanguage {
                        Button {
                            let formatted = "```\(lang)\n\(text)\n```"
                            appState.copyText(formatted)
                        } label: {
                            Label("Code Block (\(SyntaxHighlighter.displayName(for: lang)))", systemImage: "curlybraces")
                        }
                    }
                }
            }

            // Share & Export
            Section("Share & Export") {
                if let text = item.textContent {
                    Button {
                        appState.copyText(ShareService.shared.formatForSlack(text, language: item.detectedLanguage))
                    } label: {
                        Label("Copy for Slack", systemImage: "bubble.left")
                    }

                    Button {
                        appState.copyText(ShareService.shared.formatForDiscord(text, language: item.detectedLanguage))
                    } label: {
                        Label("Copy for Discord", systemImage: "bubble.left.fill")
                    }

                    if item.contentType == .link {
                        Button {
                            appState.copyText(ShareService.shared.formatAsMarkdownLink(text))
                        } label: {
                            Label("Copy as Markdown Link", systemImage: "link.badge.plus")
                        }
                    }
                }

                Button {
                    ShareService.shared.exportToFile(item)
                } label: {
                    Label("Export to File...", systemImage: "square.and.arrow.up")
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
                .foregroundStyle(isHovered ? .purple : .secondary)
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(isHovered ? Color.purple.opacity(0.08) : Color.primary.opacity(0.06))
                }
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .onHover { hovering in
            withAnimation(Constants.Animation.quick) {
                isHovered = hovering
            }
        }
        .help("Transforms & Actions")
    }
}
