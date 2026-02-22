import SwiftUI

struct RuleEditorView: View {
    let rule: ClipboardRule?
    let onSave: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var name = ""
    @State private var sourceBundleID = ""
    @State private var sourceAppName = ""
    @State private var contentTypeFilter = ""
    @State private var transformType: ClipboardTransformType = .stripAnsi
    @State private var regexPattern = ""
    @State private var regexReplacement = ""
    @State private var testInput = ""
    @State private var testOutput = ""

    var isEditing: Bool { rule != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Rule" : "New Rule")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Rule Name", text: $name)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Source App (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Bundle ID (e.g., com.apple.Terminal)", text: $sourceBundleID)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                        }

                        VStack(alignment: .leading) {
                            Text("Content Type (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $contentTypeFilter) {
                                Text("All").tag("")
                                Text("Text").tag("text")
                                Text("Link").tag("link")
                                Text("Rich Text").tag("richText")
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Transform")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $transformType) {
                            ForEach(ClipboardTransformType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if transformType == .regexReplace {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Regex Pattern", text: $regexPattern)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                            TextField("Replacement", text: $regexReplacement)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                        }
                    }

                    // Test area
                    GroupBox("Test") {
                        VStack(spacing: 8) {
                            TextField("Test input", text: $testInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11, design: .monospaced))
                            HStack {
                                Button("Test") { runTest() }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                Text(testOutput)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            HStack {
                Spacer()
                Button("Cancel") { onDismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button(isEditing ? "Update" : "Create") {
                    save()
                    onDismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
        .onAppear {
            if let rule {
                name = rule.name
                sourceBundleID = rule.sourceBundleID ?? ""
                sourceAppName = rule.sourceAppName ?? ""
                contentTypeFilter = rule.contentTypeFilter ?? ""
                transformType = rule.transformTypeEnum ?? .stripAnsi
                regexPattern = rule.regexPattern ?? ""
                regexReplacement = rule.regexReplacement ?? ""
            }
        }
    }

    private func runTest() {
        guard !testInput.isEmpty else { return }
        let dummyRule = ClipboardRule(
            name: "test",
            sourceBundleID: nil,
            transformType: transformType,
            regexPattern: regexPattern.isEmpty ? nil : regexPattern,
            regexReplacement: regexReplacement.isEmpty ? nil : regexReplacement
        )
        Task {
            testOutput = await appState.ruleEngine.applyRules(
                to: testInput,
                contentType: .text,
                sourceBundleID: nil
            )
        }
    }

    private func save() {
        Task {
            if let rule {
                await appState.ruleEngine.updateRule(
                    rule.id,
                    name: name,
                    isEnabled: true,
                    sourceBundleID: sourceBundleID.isEmpty ? nil : sourceBundleID,
                    contentTypeFilter: contentTypeFilter.isEmpty ? nil : contentTypeFilter,
                    transformType: transformType,
                    regexPattern: regexPattern.isEmpty ? nil : regexPattern,
                    regexReplacement: regexReplacement.isEmpty ? nil : regexReplacement
                )
            } else {
                let newRule = ClipboardRule(
                    name: name,
                    sourceBundleID: sourceBundleID.isEmpty ? nil : sourceBundleID,
                    sourceAppName: sourceAppName.isEmpty ? nil : sourceAppName,
                    contentTypeFilter: contentTypeFilter.isEmpty ? nil : contentTypeFilter,
                    transformType: transformType,
                    regexPattern: regexPattern.isEmpty ? nil : regexPattern,
                    regexReplacement: regexReplacement.isEmpty ? nil : regexReplacement
                )
                await appState.ruleEngine.saveRule(newRule)
            }
            onSave()
        }
    }
}
