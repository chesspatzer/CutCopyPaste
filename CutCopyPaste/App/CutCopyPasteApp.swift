import SwiftUI
import SwiftData

@main
struct CutCopyPasteApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appState: AppState

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
        self._appState = StateObject(wrappedValue: AppState(modelContainer: container))
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
        } label: {
            Image(systemName: "clipboard")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        // Analytics window
        Window("Analytics", id: "analytics") {
            AnalyticsDashboardView()
                .environmentObject(appState)
        }
        .defaultSize(width: 700, height: 500)
    }
}
