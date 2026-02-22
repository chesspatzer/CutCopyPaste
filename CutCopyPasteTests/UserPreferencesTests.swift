import XCTest
@testable import CutCopyPaste

final class UserPreferencesTests: XCTestCase {
    // MARK: - Default Values

    func testDefaultMaxHistory() {
        let prefs = UserPreferences.shared
        // After reset, should be default
        let originalValue = prefs.maxHistoryCount
        XCTAssertGreaterThan(originalValue, 0)
    }

    func testDefaultDisplayMode() {
        let prefs = UserPreferences.shared
        XCTAssertNotNil(prefs.displayMode)
    }

    func testDefaultAppearanceMode() {
        let prefs = UserPreferences.shared
        XCTAssertNotNil(prefs.appearanceMode)
    }

    // MARK: - Exclusion List

    func testExclusionListSetGet() {
        let prefs = UserPreferences.shared
        let original = prefs.excludedBundleIDs
        prefs.excludedBundleIDs = Set(["com.test.app1", "com.test.app2"])
        XCTAssertTrue(prefs.excludedBundleIDs.contains("com.test.app1"))
        XCTAssertTrue(prefs.excludedBundleIDs.contains("com.test.app2"))
        XCTAssertEqual(prefs.excludedBundleIDs.count, 2)
        // Restore
        prefs.excludedBundleIDs = original
    }

    func testExclusionListEmpty() {
        let prefs = UserPreferences.shared
        let original = prefs.excludedBundleIDs
        prefs.excludedBundleIDs = Set<String>()
        XCTAssertTrue(prefs.excludedBundleIDs.isEmpty)
        prefs.excludedBundleIDs = original
    }

    // MARK: - Appearance Mode

    func testAppearanceModeColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    func testAppearanceModeDisplayNames() {
        XCTAssertEqual(AppearanceMode.system.displayName, "System")
        XCTAssertEqual(AppearanceMode.light.displayName, "Light")
        XCTAssertEqual(AppearanceMode.dark.displayName, "Dark")
    }

    func testAppearanceModeSystemImages() {
        for mode in AppearanceMode.allCases {
            XCTAssertFalse(mode.systemImage.isEmpty)
        }
    }

    // MARK: - Display Mode

    func testDisplayModeValues() {
        XCTAssertEqual(DisplayMode.allCases.count, 2)
        XCTAssertEqual(DisplayMode.compact.displayName, "Compact")
        XCTAssertEqual(DisplayMode.comfortable.displayName, "Comfortable")
    }

    // MARK: - Reset to Defaults

    func testResetToDefaults() {
        let prefs = UserPreferences.shared
        // Change something
        let originalMax = prefs.maxHistoryCount
        prefs.maxHistoryCount = 9999
        XCTAssertEqual(prefs.maxHistoryCount, 9999)

        prefs.resetToDefaults()

        // After reset, should be back to default (500)
        XCTAssertEqual(prefs.maxHistoryCount, 500)

        // Restore if needed
        prefs.maxHistoryCount = originalMax
    }

    func testResetPreservesOnboarding() {
        let prefs = UserPreferences.shared
        let originalOnboarding = prefs.hasCompletedOnboarding
        prefs.hasCompletedOnboarding = true
        prefs.resetToDefaults()
        // hasCompletedOnboarding should NOT be reset
        XCTAssertTrue(prefs.hasCompletedOnboarding)
        prefs.hasCompletedOnboarding = originalOnboarding
    }

    // MARK: - Popover Dimensions

    func testPopoverDimensionDefaults() {
        let prefs = UserPreferences.shared
        XCTAssertGreaterThanOrEqual(prefs.popoverWidth, 300)
        XCTAssertGreaterThanOrEqual(prefs.popoverHeight, 350)
    }
}
