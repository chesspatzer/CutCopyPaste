import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared
    @EnvironmentObject private var appState: AppState
    @State private var showClearConfirmation = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Label {
                        Text("Max history")
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                    Stepper(
                        "\(prefs.maxHistoryCount) items",
                        value: $prefs.maxHistoryCount,
                        in: 50...5000,
                        step: 50
                    )
                    .labelsHidden()
                }

                LabeledContent {
                    Picker("", selection: $prefs.retentionDays) {
                        Text("Never").tag(0)
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                } label: {
                    Label("Auto-delete after", systemImage: "calendar.badge.clock")
                        .foregroundStyle(.primary)
                }

                Toggle(isOn: $prefs.deduplicateConsecutive) {
                    Label("Skip consecutive duplicates", systemImage: "doc.on.doc")
                }
            } header: {
                Text("History")
            }

            Section {
                Toggle(isOn: $prefs.launchAtLogin) {
                    Label("Launch at login", systemImage: "power")
                }
                .onChange(of: prefs.launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

                Toggle(isOn: $prefs.playSoundOnCopy) {
                    Label("Sound on capture", systemImage: "speaker.wave.2")
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear All History", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } header: {
                Text("Data")
            }
        }
        .formStyle(.grouped)
        .alert("Clear Clipboard History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear (Keep Pinned)", role: .destructive) {
                appState.clearAll()
            }
        } message: {
            Text("This will delete all clipboard history except pinned items. This cannot be undone.")
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently handle
        }
    }
}
