import SwiftUI
import Carbon.HIToolbox

struct ShortcutsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Toggle panel", systemImage: "rectangle.and.hand.point.up.left")
                    Spacer()
                    Button {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        if isRecording {
                            Text("Press keys...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(.orange, lineWidth: 1.5)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(.orange.opacity(0.05))
                                        }
                                }
                        } else {
                            KeyboardShortcutBadge(display: currentShortcutDisplay)
                        }
                    }
                    .buttonStyle(.plain)
                    .animation(Constants.Animation.quick, value: isRecording)
                }

                #if !APPSTORE
                if appState.shortcutManager.needsAccessibilityPermission {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility permission required")
                                .font(.system(size: 12, weight: .medium))
                            Text("Global shortcuts need Accessibility access to work.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Open Settings") {
                            appState.shortcutManager.openAccessibilitySettings()
                        }
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
                #endif
            } header: {
                Text("Global Shortcut")
            } footer: {
                Text("Works from any application to toggle CutCopyPaste.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    shortcutRow(keys: ["Up", "Down"], action: "Navigate items")
                    shortcutRow(keys: ["Return"], action: "Copy selected item")
                    shortcutRow(keys: ["Esc"], action: "Deselect / close")
                    shortcutRow(keys: ["Double-click"], action: "Copy item")
                }
            } header: {
                Text("In-App Shortcuts")
            }
        }
        .formStyle(.grouped)
        .onDisappear {
            stopRecording()
        }
    }

    // MARK: - Recording

    private func startRecording() {
        // Temporarily unregister the global hotkey so it doesn't interfere
        appState.shortcutManager.unregister()
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            let keyCode = Int(event.keyCode)
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])

            // Require at least one modifier key
            guard !flags.isEmpty else {
                // Escape cancels recording
                if keyCode == 53 {
                    stopRecording()
                }
                return nil
            }

            // Convert NSEvent modifier flags to CGEventFlags
            var cgFlags: UInt64 = 0
            if flags.contains(.command)  { cgFlags |= CGEventFlags.maskCommand.rawValue }
            if flags.contains(.shift)    { cgFlags |= CGEventFlags.maskShift.rawValue }
            if flags.contains(.option)   { cgFlags |= CGEventFlags.maskAlternate.rawValue }
            if flags.contains(.control)  { cgFlags |= CGEventFlags.maskControl.rawValue }

            // Save the new shortcut
            let prefs = UserPreferences.shared
            prefs.globalToggleKeyCode = keyCode
            prefs.globalToggleModifiers = Int(cgFlags)

            stopRecording()
            return nil // Consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        // Re-register the global hotkey with the (possibly new) shortcut
        appState.shortcutManager.register()
    }

    // MARK: - Display

    private var currentShortcutDisplay: [String] {
        let prefs = UserPreferences.shared
        var parts: [String] = []
        let modifiers = CGEventFlags(rawValue: UInt64(prefs.globalToggleModifiers))

        if modifiers.contains(.maskCommand)   { parts.append("\u{2318}") }
        if modifiers.contains(.maskShift)     { parts.append("\u{21E7}") }
        if modifiers.contains(.maskAlternate) { parts.append("\u{2325}") }
        if modifiers.contains(.maskControl)   { parts.append("\u{2303}") }

        parts.append(keyCodeToString(prefs.globalToggleKeyCode))
        return parts
    }

    private func shortcutRow(keys: [String], action: String) -> some View {
        HStack {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                }
                        }
                }
            }

            Spacer()

            Text(action)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func keyCodeToString(_ keyCode: Int) -> String {
        let mapping: [Int: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "B", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        ]
        return mapping[keyCode] ?? "Key \(keyCode)"
    }
}

// MARK: - Keyboard Shortcut Badge

private struct KeyboardShortcutBadge: View {
    let display: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(display, id: \.self) { key in
                Text(key)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .frame(minWidth: 22, minHeight: 22)
                    .padding(.horizontal, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                            }
                            .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                    }
            }
        }
    }
}
