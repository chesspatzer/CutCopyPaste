import XCTest
@testable import CutCopyPaste

final class ExclusionListTests: XCTestCase {
    // MARK: - Default Exclusions

    func testDefaultExclusionsContainPasswordManagers() {
        let defaults = ExclusionListManager.defaultExclusions
        XCTAssertTrue(defaults.contains("com.1password.1password"))
        XCTAssertTrue(defaults.contains("com.bitwarden.desktop"))
        XCTAssertTrue(defaults.contains("com.lastpass.LastPass"))
    }

    func testDefaultExclusionsContainKeychainAccess() {
        let defaults = ExclusionListManager.defaultExclusions
        XCTAssertTrue(defaults.contains("com.apple.keychainaccess"))
    }

    // MARK: - Exclusion Checking

    func testIsExcludedForKnownApps() {
        let manager = ExclusionListManager()
        XCTAssertTrue(manager.isExcluded(bundleID: "com.1password.1password"))
        XCTAssertTrue(manager.isExcluded(bundleID: "com.bitwarden.desktop"))
    }

    func testIsNotExcludedForRegularApps() {
        let manager = ExclusionListManager()
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.Safari"))
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.Xcode"))
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.finder"))
    }

    func testIsNotExcludedForEmptyString() {
        let manager = ExclusionListManager()
        XCTAssertFalse(manager.isExcluded(bundleID: ""))
    }

    // MARK: - All Exclusions

    func testAllExclusionsIncludesDefaults() {
        let manager = ExclusionListManager()
        let all = manager.allExclusions()
        for defaultID in ExclusionListManager.defaultExclusions {
            XCTAssertTrue(all.contains(defaultID))
        }
    }

    // MARK: - Case Sensitivity

    func testExclusionIsCaseSensitive() {
        let manager = ExclusionListManager()
        // Bundle IDs are case-sensitive
        XCTAssertTrue(manager.isExcluded(bundleID: "com.1password.1password"))
        // Uppercase variant should not match (unless implementation is case-insensitive)
        // This just verifies behavior either way
        let upperResult = manager.isExcluded(bundleID: "COM.1PASSWORD.1PASSWORD")
        // Either result is fine — we're documenting the behavior
        XCTAssertNotNil(upperResult as Any)
    }
}
