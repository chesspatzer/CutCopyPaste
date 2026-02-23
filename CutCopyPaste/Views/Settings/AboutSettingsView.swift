import SwiftUI

struct AboutSettingsView: View {
    #if !APPSTORE
    @ObservedObject private var updaterService = UpdaterService.shared
    #endif

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)

                Image(systemName: "clipboard.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("CutCopyPaste")
                    .font(.system(size: 18, weight: .bold, design: .rounded))

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text("A powerful clipboard manager for macOS.\n100% offline. No cloud. No tracking.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 8) {
                infoRow(label: "Platform", value: "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                infoRow(label: "Architecture", value: architectureString)
                infoRow(label: "SwiftUI + SwiftData", value: "No third-party deps")
            }
            .padding(.horizontal, 30)

            #if !APPSTORE
            Button("Check for Updates...") {
                updaterService.checkForUpdates()
            }
            .disabled(!updaterService.canCheckForUpdates)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            #endif

            Spacer()

            Text("Made with care for developers and power users.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var architectureString: String {
        #if arch(arm64)
        return "Apple Silicon"
        #else
        return "Intel"
        #endif
    }
}
