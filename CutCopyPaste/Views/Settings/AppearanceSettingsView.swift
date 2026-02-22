import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared

    var body: some View {
        Form {
            Section {
                Picker("Appearance", selection: $prefs.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Theme")
            }

            Section {
                Picker("Display density", selection: $prefs.displayMode) {
                    ForEach(DisplayMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $prefs.showTimestamps) {
                    Label("Show timestamps", systemImage: "clock")
                }

                Toggle(isOn: $prefs.showSourceApp) {
                    Label("Show source app", systemImage: "app.badge")
                }

                Toggle(isOn: $prefs.timeGroupedHistory) {
                    Label("Group items by time", systemImage: "calendar.day.timeline.left")
                }
            } header: {
                Text("Item Display")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Width", systemImage: "arrow.left.and.right")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(prefs.popoverWidth))px")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $prefs.popoverWidth, in: 300...500, step: 10)
                        .tint(.accentColor)

                    HStack {
                        Label("Height", systemImage: "arrow.up.and.down")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(prefs.popoverHeight))px")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $prefs.popoverHeight, in: 350...700, step: 10)
                        .tint(.accentColor)
                }
            } header: {
                Text("Panel Size")
            }
        }
        .formStyle(.grouped)
    }
}
