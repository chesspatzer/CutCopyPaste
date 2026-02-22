import SwiftUI

struct ExclusionsSettingsView: View {
    @ObservedObject private var prefs = UserPreferences.shared
    @State private var newBundleID = ""
    @State private var showingRunningApps = false

    var body: some View {
        Form {
            Section {
                Text("Clipboard content from these apps will not be captured.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                ForEach(ExclusionListManager.defaultExclusions.sorted(), id: \.self) { bundleID in
                    ExclusionRow(
                        bundleID: bundleID,
                        isDefault: true,
                        onRemove: nil
                    )
                }

                ForEach(prefs.excludedBundleIDs.sorted(), id: \.self) { bundleID in
                    ExclusionRow(
                        bundleID: bundleID,
                        isDefault: false,
                        onRemove: {
                            withAnimation(Constants.Animation.snappy) {
                                var ids = prefs.excludedBundleIDs
                                ids.remove(bundleID)
                                prefs.excludedBundleIDs = ids
                            }
                        }
                    )
                }
            } header: {
                Text("Excluded Apps")
            }

            Section {
                HStack(spacing: 8) {
                    TextField("com.example.app", text: $newBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Button {
                        let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        withAnimation(Constants.Animation.snappy) {
                            var ids = prefs.excludedBundleIDs
                            ids.insert(trimmed)
                            prefs.excludedBundleIDs = ids
                        }
                        newBundleID = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(newBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Button {
                    showingRunningApps = true
                } label: {
                    Label("Choose from running apps", systemImage: "app.dashed")
                }
            } header: {
                Text("Add Exclusion")
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingRunningApps) {
            RunningAppsPickerView { bundleID in
                withAnimation(Constants.Animation.snappy) {
                    var ids = prefs.excludedBundleIDs
                    ids.insert(bundleID)
                    prefs.excludedBundleIDs = ids
                }
            }
        }
    }
}

// MARK: - Exclusion Row

private struct ExclusionRow: View {
    let bundleID: String
    let isDefault: Bool
    let onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isDefault ? "lock.shield" : "xmark.app")
                .font(.system(size: 11))
                .foregroundStyle(isDefault ? Color.secondary : Color.orange)
                .frame(width: 16)

            Text(bundleID)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(isDefault ? .secondary : .primary)

            Spacer()

            if isDefault {
                Text("Built-in")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.primary.opacity(0.04))
                    }
            } else if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red.opacity(0.7))
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Running Apps Picker

struct RunningAppsPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Select App to Exclude")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            TextField("Filter apps...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.bottom, 8)

            List(filteredApps, id: \.bundleIdentifier) { app in
                Button {
                    if let id = app.bundleIdentifier {
                        onSelect(id)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(app.localizedName ?? "Unknown")
                                .font(.system(size: 13))
                            Text(app.bundleIdentifier ?? "")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(height: 300)
        }
        .frame(width: 480)
    }

    private var filteredApps: [NSRunningApplication] {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }

        if searchText.isEmpty { return apps }
        let query = searchText.lowercased()
        return apps.filter {
            ($0.localizedName ?? "").lowercased().contains(query)
            || ($0.bundleIdentifier ?? "").lowercased().contains(query)
        }
    }
}
