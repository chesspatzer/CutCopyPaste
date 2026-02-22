import SwiftUI

struct RulesSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var rules: [ClipboardRule] = []
    @State private var showEditor = false
    @State private var editingRule: ClipboardRule?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard Rules")
                    .font(.headline)
                Spacer()
                Button {
                    editingRule = nil
                    showEditor = true
                } label: {
                    Label("Add Rule", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            if rules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "wand.and.rays")
                        .font(.system(size: 32))
                        .foregroundStyle(.quaternary)
                    Text("No rules configured")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Text("Rules automatically transform clipboard content based on the source app.")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(rules) { rule in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { _ in toggleRule(rule) }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.name)
                                    .font(.system(size: 12, weight: .medium))
                                HStack(spacing: 4) {
                                    if let app = rule.sourceAppName ?? rule.sourceBundleID {
                                        Text(app)
                                            .font(.system(size: 9))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                                            .foregroundStyle(.blue)
                                    }
                                    if let type = rule.transformTypeEnum {
                                        Text(type.displayName)
                                            .font(.system(size: 9))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.purple.opacity(0.1)))
                                            .foregroundStyle(.purple)
                                    }
                                }
                            }

                            Spacer()

                            Button {
                                editingRule = rule
                                showEditor = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)

                            Button {
                                deleteRule(rule)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            RuleEditorView(rule: editingRule, onSave: {
                loadRules()
            }, onDismiss: {
                showEditor = false
            })
            .environmentObject(appState)
        }
        .onAppear { loadRules() }
    }

    private func loadRules() {
        Task {
            rules = await appState.ruleEngine.fetchRules()
        }
    }

    private func toggleRule(_ rule: ClipboardRule) {
        Task {
            await appState.ruleEngine.toggleRule(rule.id)
            loadRules()
        }
    }

    private func deleteRule(_ rule: ClipboardRule) {
        Task {
            await appState.ruleEngine.deleteRule(rule.id)
            loadRules()
        }
    }
}

extension ClipboardRule: @retroactive Identifiable {}
