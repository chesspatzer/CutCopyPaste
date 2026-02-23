import SwiftUI
import SwiftData

/// Sets `NSAppearance` directly on the hosting NSWindow.
/// `.preferredColorScheme` doesn't propagate to MenuBarExtra panels,
/// so we reach into the window and set it explicitly.
private struct WindowAppearanceSetter: NSViewRepresentable {
    let appearance: NSAppearance?

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.appearance = appearance
        }
    }
}

@main
struct CutCopyPasteApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appState: AppState
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    init() {
        let container: ModelContainer
        do {
            let config = ModelConfiguration(url: Constants.Storage.storeURL)
            container = try ModelContainer(
                for: ClipboardItem.self,
                     Snippet.self,
                     SnippetFolder.self,
                     ClipboardRule.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.modelContainer = container
        let state = AppState(modelContainer: container)
        self._appState = StateObject(wrappedValue: state)
    }

    var body: some Scene {
        // Menubar app
        MenuBarExtra {
            PopoverContentView()
                .environmentObject(appState)
                .frame(
                    width: appState.showDiffView ? 620 : appState.preferences.popoverWidth,
                    height: appState.showDiffView ? 520 : appState.preferences.popoverHeight
                )
                .animation(Constants.Animation.snappy, value: appState.showDiffView)
                .preferredColorScheme(appearanceMode.colorScheme)
                .background(WindowAppearanceSetter(appearance: appearanceMode.nsAppearance))
        } label: {
            Image(systemName: appState.unseenCopyCount > 0 ? "clipboard.fill" : "clipboard")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(appearanceMode.colorScheme)
        }

        // Analytics window
        Window("Analytics", id: "analytics") {
            AnalyticsDashboardView()
                .environmentObject(appState)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .defaultSize(width: 700, height: 500)
    }
}
