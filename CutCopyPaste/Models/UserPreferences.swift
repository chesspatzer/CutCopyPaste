import Foundation
import SwiftUI

enum DisplayMode: String, CaseIterable, Identifiable {
    case compact
    case comfortable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact:     return "Compact"
        case .comfortable: return "Comfortable"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }
}

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    // MARK: - History

    @AppStorage("maxHistoryCount") var maxHistoryCount: Int = 500
    @AppStorage("retentionDays") var retentionDays: Int = 30 // 0 = forever
    @AppStorage("deduplicateConsecutive") var deduplicateConsecutive: Bool = true

    // MARK: - Appearance

    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system
    @AppStorage("displayMode") var displayMode: DisplayMode = .comfortable
    @AppStorage("popoverWidth") var popoverWidth: Double = 400
    @AppStorage("popoverHeight") var popoverHeight: Double = 560
    @AppStorage("showSourceApp") var showSourceApp: Bool = true
    @AppStorage("showTimestamps") var showTimestamps: Bool = true

    // MARK: - Shortcuts

    @AppStorage("globalToggleKeyCode") var globalToggleKeyCode: Int = 9 // V key
    @AppStorage("globalToggleModifiers") var globalToggleModifiers: Int = 0x000900 // Cmd+Shift

    // MARK: - Exclusions

    @AppStorage("excludedBundleIDs") var excludedBundleIDsRaw: String = ""

    var excludedBundleIDs: Set<String> {
        get {
            Set(excludedBundleIDsRaw.split(separator: ",").map(String.init))
        }
        set {
            excludedBundleIDsRaw = newValue.sorted().joined(separator: ",")
        }
    }

    // MARK: - Security

    @AppStorage("detectSensitiveData") var detectSensitiveData: Bool = true
    @AppStorage("autoMaskSensitive") var autoMaskSensitive: Bool = false

    // MARK: - OCR

    @AppStorage("autoOCR") var autoOCR: Bool = false

    // MARK: - Snippets

    @AppStorage("snippetsSeeded") var snippetsSeeded: Bool = false

    // MARK: - Paste Stack

    @AppStorage("pasteStackMode") var pasteStackMode: String = "queue"

    // MARK: - Launch

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("playSoundOnCopy") var playSoundOnCopy: Bool = false

    private init() {}
}
