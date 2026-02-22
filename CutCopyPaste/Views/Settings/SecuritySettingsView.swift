import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject private var preferences = UserPreferences.shared

    var body: some View {
        Form {
            Section {
                Toggle("Detect sensitive data in clipboard", isOn: $preferences.detectSensitiveData)
                Toggle("Auto-mask detected sensitive data", isOn: $preferences.autoMaskSensitive)
                    .disabled(!preferences.detectSensitiveData)
            } header: {
                Label("Sensitive Data Detection", systemImage: "exclamationmark.shield")
            } footer: {
                Text("Detects API keys, passwords, credit card numbers, private keys, and other sensitive data. No data is sent anywhere.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                Toggle("Auto-extract text from images (OCR)", isOn: $preferences.autoOCR)
            } header: {
                Label("Image Processing", systemImage: "doc.text.viewfinder")
            } footer: {
                Text("Automatically runs OCR on captured images so their text is searchable. Uses Apple Vision — no data leaves your Mac.")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if #available(macOS 26, *) {
                Section {
                    Toggle("Use on-device LLM for search", isOn: $preferences.useLLMSearch)
                } header: {
                    Label("AI Search", systemImage: "brain")
                } footer: {
                    Text("Uses Apple Intelligence to understand natural language search queries. Runs entirely on-device. When disabled or unavailable, falls back to keyword-based search.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Patterns")
                        .font(.subheadline.weight(.medium))

                    ForEach(SensitiveDataType.allCases, id: \.rawValue) { type in
                        HStack(spacing: 8) {
                            Image(systemName: type.iconSystemName)
                                .font(.system(size: 10))
                                .frame(width: 16)
                                .foregroundStyle(severityColor(type.severity))
                            Text(type.displayName)
                                .font(.system(size: 12))
                            Spacer()
                            Text(type.severity.rawValue.capitalized)
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(severityColor(type.severity).opacity(0.15)))
                                .foregroundStyle(severityColor(type.severity))
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func severityColor(_ severity: SensitiveDataType.Severity) -> Color {
        switch severity {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}
