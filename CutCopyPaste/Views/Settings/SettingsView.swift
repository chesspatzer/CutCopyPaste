import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush.pointed")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "command.square")
                }

            ExclusionsSettingsView()
                .tabItem {
                    Label("Exclusions", systemImage: "eye.slash")
                }

            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "shield")
                }

            RulesSettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Rules", systemImage: "wand.and.rays")
                }
        }
        .frame(width: 550, height: 420)
    }
}
