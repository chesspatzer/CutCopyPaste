import XCTest
@testable import CutCopyPaste

final class QuickActionTests: XCTestCase {
    let service = QuickActionService.shared

    // MARK: - URL Actions

    func testURLActionsForLink() {
        let item = ClipboardItem(contentType: .link, textContent: "https://www.example.com/path?utm_source=google&ref=123")
        let actions = service.applicableActions(for: item)
        let names = actions.map { $0.name }
        XCTAssertTrue(names.contains(where: { $0.lowercased().contains("open") || $0.lowercased().contains("browser") }))
    }

    func testStripTrackingParamsAction() {
        let item = ClipboardItem(contentType: .link, textContent: "https://example.com?utm_source=google&utm_medium=cpc&ref=123")
        let actions = service.applicableActions(for: item)
        let stripAction = actions.first { $0.name.lowercased().contains("tracking") || $0.name.lowercased().contains("strip") }
        if let action = stripAction {
            let result = action.execute(item: item)
            if let result {
                XCTAssertFalse(result.contains("utm_source"))
                XCTAssertFalse(result.contains("utm_medium"))
            }
        }
    }

    func testExtractDomainAction() {
        let item = ClipboardItem(contentType: .link, textContent: "https://www.example.com/path")
        let actions = service.applicableActions(for: item)
        let domainAction = actions.first { $0.name.lowercased().contains("domain") }
        if let action = domainAction {
            let result = action.execute(item: item)
            XCTAssertNotNil(result)
            if let result {
                XCTAssertTrue(result.contains("example.com"))
            }
        }
    }

    // MARK: - JSON Actions

    func testJSONActionsForJSON() {
        let item = ClipboardItem(contentType: .text, textContent: "{\"name\": \"John\", \"age\": 30}")
        let actions = service.applicableActions(for: item)
        let names = actions.map { $0.name }
        XCTAssertTrue(names.contains(where: { $0.lowercased().contains("json") || $0.lowercased().contains("validate") }))
    }

    func testJSONExtractKeys() {
        let item = ClipboardItem(contentType: .text, textContent: "{\"name\": \"John\", \"age\": 30}")
        let actions = service.applicableActions(for: item)
        let keysAction = actions.first { $0.name.lowercased().contains("keys") }
        if let action = keysAction {
            let result = action.execute(item: item)
            XCTAssertNotNil(result)
            if let result {
                XCTAssertTrue(result.contains("name"))
                XCTAssertTrue(result.contains("age"))
            }
        }
    }

    // MARK: - UUID Actions

    func testUUIDDetection() {
        let item = ClipboardItem(contentType: .text, textContent: "550e8400-e29b-41d4-a716-446655440000")
        let actions = service.applicableActions(for: item)
        let names = actions.map { $0.name }
        XCTAssertTrue(names.contains(where: { $0.lowercased().contains("uuid") || $0.lowercased().contains("regenerate") }))
    }

    // MARK: - No Actions for Simple Text

    func testNoSpecialActionsForPlainText() {
        let item = ClipboardItem(contentType: .text, textContent: "hello world")
        let actions = service.applicableActions(for: item)
        // Should have few or no quick actions for simple text
        XCTAssertTrue(actions.count <= 2)
    }

    // MARK: - Image Items

    func testNoActionsForImage() {
        let item = ClipboardItem(contentType: .image)
        let actions = service.applicableActions(for: item)
        XCTAssertTrue(actions.isEmpty)
    }

    // MARK: - Timestamp Actions

    func testTimestampActions() {
        let item = ClipboardItem(contentType: .text, textContent: "1700000000")
        let actions = service.applicableActions(for: item)
        let names = actions.map { $0.name }
        XCTAssertTrue(names.contains(where: { $0.lowercased().contains("epoch") || $0.lowercased().contains("time") || $0.lowercased().contains("human") }))
    }

    // MARK: - Email Actions

    func testEmailExtraction() {
        let item = ClipboardItem(contentType: .text, textContent: "Contact us at info@example.com or support@test.org")
        let actions = service.applicableActions(for: item)
        let emailAction = actions.first { $0.name.lowercased().contains("email") }
        if let action = emailAction {
            let result = action.execute(item: item)
            XCTAssertNotNil(result)
            if let result {
                XCTAssertTrue(result.contains("info@example.com"))
            }
        }
    }
}
