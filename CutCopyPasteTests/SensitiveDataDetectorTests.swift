import XCTest
@testable import CutCopyPaste

final class SensitiveDataDetectorTests: XCTestCase {
    let detector = SensitiveDataDetector.shared

    // MARK: - AWS Keys

    func testDetectsAWSAccessKey() {
        let text = "AKIAIOSFODNN7EXAMPLE"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .awsAccessKey })
    }

    func testDetectsAWSSecretKey() {
        let text = "aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .awsSecretKey })
    }

    // MARK: - API Keys

    func testDetectsOpenAIKey() {
        // Regex pattern is sk-[A-Za-z0-9]{20,} (no hyphens allowed after sk-)
        let text = "sk-abcdefghijklmnopqrstuvwxyz1234567890abcdef"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .openAIKey })
    }

    func testDetectsStripeKey() {
        let text = "sk_test_4eC39HqLyjWDarjtT1zdp7dc"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .stripeKey })
    }

    func testDetectsGitHubToken() {
        let text = "ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .githubToken })
    }

    func testDetectsGenericAPIKey() {
        let text = "api_key=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .genericAPIKey })
    }

    // MARK: - Credit Cards

    func testDetectsCreditCard() {
        // Valid Visa test number
        let text = "4111111111111111"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .creditCard })
    }

    func testDoesNotDetectInvalidCreditCard() {
        let text = "1234567890123456"
        let matches = detector.detect(in: text)
        XCTAssertFalse(matches.contains { $0.type == .creditCard })
    }

    // MARK: - SSN

    func testDetectsSSN() {
        let text = "SSN: 123-45-6789"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .ssn })
    }

    // MARK: - PEM Keys

    func testDetectsPEMKey() {
        let text = "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWep4PAtGoSo0TBmP\n-----END RSA PRIVATE KEY-----"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .pemPrivateKey })
    }

    // MARK: - Connection Strings

    func testDetectsMongoDBConnectionString() {
        let text = "mongodb://user:password@localhost:27017/mydb"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .connectionString })
    }

    func testDetectsPostgresConnectionString() {
        let text = "postgres://user:pass@host:5432/db"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .connectionString })
    }

    // MARK: - Passwords

    func testDetectsPassword() {
        let text = "password = \"MyS3cretP@ss\""
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.contains { $0.type == .password })
    }

    // MARK: - No False Positives

    func testNoFalsePositivesOnNormalText() {
        let text = "Hello, this is a normal text without any secrets."
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.isEmpty)
    }

    func testNoFalsePositivesOnCode() {
        let text = "let x = 42\nprint(x)"
        let matches = detector.detect(in: text)
        XCTAssertTrue(matches.isEmpty)
    }

    // MARK: - Redaction

    func testRedaction() {
        let text = "My key is AKIAIOSFODNN7EXAMPLE and nothing else"
        let matches = detector.detect(in: text)
        let redacted = detector.redact(text, matches: matches)
        XCTAssertFalse(redacted.contains("AKIAIOSFODNN7EXAMPLE"))
        XCTAssertTrue(redacted.contains("***"))
    }

    // MARK: - Multiple Matches

    func testMultipleMatches() {
        let text = "AWS: AKIAIOSFODNN7EXAMPLE\nStripe: sk_test_4eC39HqLyjWDarjtT1zdp7dc"
        let matches = detector.detect(in: text)
        XCTAssertGreaterThanOrEqual(matches.count, 2)
    }

    // MARK: - Severity

    func testSeverityLevels() {
        XCTAssertEqual(SensitiveDataType.awsSecretKey.severity, .high)
        XCTAssertEqual(SensitiveDataType.creditCard.severity, .high)
        XCTAssertEqual(SensitiveDataType.ssn.severity, .high)
        XCTAssertEqual(SensitiveDataType.pemPrivateKey.severity, .high)
    }

    func testAllTypesHaveDisplayNames() {
        for type in SensitiveDataType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.iconSystemName.isEmpty)
        }
    }
}
