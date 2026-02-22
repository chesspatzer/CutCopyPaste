import SwiftUI

struct SettingsView: View {
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
        }
        .frame(width: 500, height: 400)
    }
}
