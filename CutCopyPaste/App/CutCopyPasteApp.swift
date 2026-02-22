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

        // Wire up global hotkey to toggle the MenuBarExtra panel
        state.shortcutManager.onTogglePopover = {
            // The MenuBarExtra panel is the first NSPanel with the app's content
            if let panel = NSApp.windows.first(where: { $0 is NSPanel && $0.className.contains("StatusBarWindow") }) {
                if panel.isVisible {
                    panel.orderOut(nil)
                } else {
                    panel.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                // Fallback: simulate click on status item
                // Find any panel that looks like our MenuBarExtra
                for window in NSApp.windows {
                    if window is NSPanel && window.level == .statusBar {
                        if window.isVisible {
                            window.orderOut(nil)
                        } else {
                            window.makeKeyAndOrderFront(nil)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                        return
                    }
                }
            }
        }
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
            Image(systemName: "clipboard")
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
