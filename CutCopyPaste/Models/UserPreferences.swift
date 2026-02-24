import Foundation
import SwiftUI

enum SearchMode: String, CaseIterable {
    case natural
    case regex
}

enum CopyFormat: String, CaseIterable {
    case plainText
    case markdownCodeBlock
    case htmlPreBlock
    case quotedText
    case escapedString
    case singleLine

    var displayName: String {
        switch self {
        case .plainText:         return "Plain Text"
        case .markdownCodeBlock: return "Markdown Code Block"
        case .htmlPreBlock:      return "HTML <pre> Block"
        case .quotedText:        return "Quoted Text"
        case .escapedString:     return "Escaped String"
        case .singleLine:        return "Single Line"
        }
    }

    var systemImage: String {
        switch self {
        case .plainText:         return "doc.plaintext"
        case .markdownCodeBlock: return "chevron.left.forwardslash.chevron.right"
        case .htmlPreBlock:      return "chevron.left.slash.chevron.right"
        case .quotedText:        return "text.quote"
        case .escapedString:     return "character.textbox"
        case .singleLine:        return "text.alignleft"
        }
    }
}

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

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }
}

final class UserPreferences: ObservableObject, @unchecked Sendable {
    static let shared = UserPreferences()

    // MARK: - History

    @AppStorage("maxHistoryCount") var maxHistoryCount: Int = 500
    @AppStorage("retentionDays") var retentionDays: Int = 30 // 0 = forever
    @AppStorage("deduplicateConsecutive") var deduplicateConsecutive: Bool = true

    // MARK: - Appearance

    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system
    @AppStorage("displayMode") var displayMode: DisplayMode = .comfortable
    @AppStorage("popoverWidth") var popoverWidth: Double = 420
    @AppStorage("popoverHeight") var popoverHeight: Double = 750
    @AppStorage("showSourceApp") var showSourceApp: Bool = true
    @AppStorage("showTimestamps") var showTimestamps: Bool = true

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
    @AppStorage("respectConcealedTypes") var respectConcealedTypes: Bool = true

    // MARK: - Monitoring

    @AppStorage("clipboardCheckInterval") var clipboardCheckInterval: Double = 0.5

    // MARK: - AI Search

    @AppStorage("useLLMSearch") var useLLMSearch: Bool = true

    // MARK: - OCR

    @AppStorage("autoOCR") var autoOCR: Bool = true

    // MARK: - Snippets

    @AppStorage("snippetsSeeded") var snippetsSeeded: Bool = false
    @AppStorage("snippetsSeededV2") var snippetsSeededV2: Bool = false

    // MARK: - Launch

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("playSoundOnCopy") var playSoundOnCopy: Bool = false

    // MARK: - Display

    @AppStorage("timeGroupedHistory") var timeGroupedHistory: Bool = true

    // MARK: - Onboarding

    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

    private init() {}

    // MARK: - Reset

    func resetToDefaults() {
        // Explicitly set @AppStorage properties back to their declared defaults
        maxHistoryCount = 500
        retentionDays = 30
        deduplicateConsecutive = true
        appearanceMode = .system
        displayMode = .comfortable
        popoverWidth = 420
        popoverHeight = 750
        showSourceApp = true
        showTimestamps = true
        excludedBundleIDsRaw = ""
        detectSensitiveData = true
        autoMaskSensitive = false
        respectConcealedTypes = true
        clipboardCheckInterval = 0.5
        useLLMSearch = true
        autoOCR = true
        launchAtLogin = false
        playSoundOnCopy = false
        timeGroupedHistory = true
        objectWillChange.send()
    }
}
