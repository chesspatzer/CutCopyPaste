import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct GeneralSettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared
    @EnvironmentObject private var appState: AppState
    @State private var showClearConfirmation = false
    @State private var showResetConfirmation = false
    @State private var loginError: String?
    @State private var exportStatus: String?

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
                    Text("\(prefs.maxHistoryCount) items")
                        .foregroundStyle(.secondary)
                    Stepper(
                        "",
                        value: $prefs.maxHistoryCount,
                        in: 50...5000,
                        step: 50
                    )
                    .labelsHidden()
                    .fixedSize()
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

                if let loginError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 12))
                        Text(loginError)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $prefs.playSoundOnCopy) {
                    Label("Sound on capture", systemImage: "speaker.wave.2")
                }

                LabeledContent {
                    Picker("", selection: $prefs.clipboardCheckInterval) {
                        Text("0.25s (Fastest)").tag(0.25)
                        Text("0.5s (Default)").tag(0.5)
                        Text("1.0s").tag(1.0)
                        Text("2.0s (Battery saver)").tag(2.0)
                    }
                    .labelsHidden()
                    .frame(width: 160)
                    .onChange(of: prefs.clipboardCheckInterval) {
                        appState.clipboardMonitor.restartMonitoring()
                    }
                } label: {
                    Label("Check interval", systemImage: "timer")
                        .foregroundStyle(.primary)
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Button {
                    exportHistory()
                } label: {
                    Label("Export History...", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    importHistory()
                } label: {
                    Label("Import History...", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let status = exportStatus {
                    Text(status)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data Transfer")
            }

            Section {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear All History", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Settings to Defaults", systemImage: "arrow.counterclockwise")
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
        .alert("Reset All Settings?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                UserPreferences.shared.resetToDefaults()
            }
        } message: {
            Text("This will restore all settings to their default values. Your clipboard history will not be affected.")
        }
    }

    // MARK: - Launch at Login

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "Failed to \(enabled ? "enable" : "disable"): \(error.localizedDescription)"
            DispatchQueue.main.async {
                prefs.launchAtLogin = !enabled
            }
        }
    }

    // MARK: - Export

    private func exportHistory() {
        Task {
            let items = await appState.storageService.fetchItems(limit: 10000)

            let exportItems: [[String: Any]] = items.map { item in
                var dict: [String: Any] = [
                    "id": item.id.uuidString,
                    "contentType": item.contentType.rawValue,
                    "createdAt": ISO8601DateFormatter().string(from: item.createdAt),
                    "isPinned": item.isPinned,
                    "useCount": item.useCount,
                    "isMasked": item.isMasked,
                ]
                if let text = item.textContent { dict["textContent"] = text }
                if let app = item.sourceAppName { dict["sourceAppName"] = app }
                if let bid = item.sourceAppBundleID { dict["sourceAppBundleID"] = bid }
                if let summary = item.summary { dict["summary"] = summary }
                if let ocrText = item.ocrText { dict["ocrText"] = ocrText }
                if let charCount = item.characterCount { dict["characterCount"] = charCount }
                if let paths = item.filePaths { dict["filePaths"] = paths }
                if let ws = item.workspaceName { dict["workspaceName"] = ws }
                if let sensitive = item.sensitiveDataTypes { dict["sensitiveDataTypes"] = sensitive }
                if let imageData = item.imageData {
                    dict["imageData"] = imageData.base64EncodedString()
                }
                return dict
            }

            let wrapper: [String: Any] = [
                "version": 1,
                "exportDate": ISO8601DateFormatter().string(from: Date()),
                "itemCount": exportItems.count,
                "items": exportItems,
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: wrapper, options: [.prettyPrinted, .sortedKeys]) else {
                await MainActor.run { exportStatus = "Failed to serialize data" }
                return
            }

            await MainActor.run {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.json]
                panel.nameFieldStringValue = "CutCopyPaste-Export-\(dateStamp()).json"
                panel.title = "Export Clipboard History"

                if panel.runModal() == .OK, let url = panel.url {
                    do {
                        try jsonData.write(to: url)
                        exportStatus = "Exported \(exportItems.count) items"
                    } catch {
                        exportStatus = "Export failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - Import

    private func importHistory() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.title = "Import Clipboard History"
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            do {
                let data = try Data(contentsOf: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let items = json["items"] as? [[String: Any]] else {
                    await MainActor.run { exportStatus = "Invalid file format" }
                    return
                }

                var imported = 0
                for dict in items {
                    guard let typeRaw = dict["contentType"] as? String,
                          let contentType = ClipboardItemType(rawValue: typeRaw) else { continue }

                    let item = ClipboardItem(
                        contentType: contentType,
                        textContent: dict["textContent"] as? String,
                        filePaths: dict["filePaths"] as? [String],
                        sourceAppBundleID: dict["sourceAppBundleID"] as? String,
                        sourceAppName: dict["sourceAppName"] as? String
                    )

                    if let dateStr = dict["createdAt"] as? String,
                       let date = ISO8601DateFormatter().date(from: dateStr) {
                        item.createdAt = date
                        item.lastUsedAt = date
                    }
                    item.isPinned = dict["isPinned"] as? Bool ?? false
                    item.useCount = dict["useCount"] as? Int ?? 0
                    item.isMasked = dict["isMasked"] as? Bool ?? false
                    item.summary = dict["summary"] as? String
                    item.ocrText = dict["ocrText"] as? String
                    item.characterCount = dict["characterCount"] as? Int
                    item.sensitiveDataTypes = dict["sensitiveDataTypes"] as? [String]
                    item.workspaceName = dict["workspaceName"] as? String

                    if let b64 = dict["imageData"] as? String {
                        item.imageData = Data(base64Encoded: b64)
                    }

                    await appState.storageService.save(item)
                    imported += 1
                }

                await MainActor.run {
                    exportStatus = "Imported \(imported) items"
                    appState.refreshItems()
                }
            } catch {
                await MainActor.run { exportStatus = "Import failed: \(error.localizedDescription)" }
            }
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
