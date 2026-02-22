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
