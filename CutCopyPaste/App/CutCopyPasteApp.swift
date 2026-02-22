import SwiftUI
import SwiftData

@main
struct CutCopyPasteApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appState: AppState

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ClipboardItem.self)
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
                    width: appState.preferences.popoverWidth,
                    height: appState.preferences.popoverHeight
                )
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
    }
}
