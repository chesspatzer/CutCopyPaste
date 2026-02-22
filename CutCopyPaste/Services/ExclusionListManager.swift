import Foundation

final class ExclusionListManager {
    static let defaultExclusions: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "org.keepassxc.keepassxc",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
    ]

    func isExcluded(bundleID: String) -> Bool {
        let userExclusions = UserPreferences.shared.excludedBundleIDs
        return Self.defaultExclusions.contains(bundleID) || userExclusions.contains(bundleID)
    }

    func allExclusions() -> Set<String> {
        Self.defaultExclusions.union(UserPreferences.shared.excludedBundleIDs)
    }
}
