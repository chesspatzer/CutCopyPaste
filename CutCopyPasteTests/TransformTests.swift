import XCTest
@testable import CutCopyPaste

final class TransformTests: XCTestCase {
    // MARK: - Case Transforms

    func testCamelToSnake() {
        let t = CamelToSnakeTransform()
        XCTAssertTrue(t.canApply(to: "myVariableName"))
        let result = t.apply(to: "myVariableName")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("my_variable_name"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testCamelToSnakeMultiWord() {
        let t = CamelToSnakeTransform()
        let result = t.apply(to: "getHTTPResponse")
        if case .success(let output) = result {
            XCTAssertTrue(output.lowercased().contains("get"))
            XCTAssertTrue(output.contains("_"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testSnakeToCamel() {
        let t = SnakeToCamelTransform()
        XCTAssertTrue(t.canApply(to: "my_variable_name"))
        let result = t.apply(to: "my_variable_name")
        if case .success(let output) = result {
            XCTAssertEqual(output, "myVariableName")
        } else {
            XCTFail("Transform failed")
        }
    }

    func testToKebabCase() {
        let t = ToKebabCaseTransform()
        let result = t.apply(to: "myVariableName")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("my-variable-name"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testToKebabCaseFromSnake() {
        let t = ToKebabCaseTransform()
        let result = t.apply(to: "my_variable_name")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("my-variable-name"))
        } else {
            XCTFail("Transform failed")
        }
    }

    // MARK: - Encoding Transforms

    func testBase64Encode() {
        let t = Base64EncodeTransform()
        XCTAssertTrue(t.canApply(to: "Hello"))
        let result = t.apply(to: "Hello World")
        if case .success(let output) = result {
            XCTAssertEqual(output, "SGVsbG8gV29ybGQ=")
        } else {
            XCTFail("Transform failed")
        }
    }

    func testBase64Decode() {
        let t = Base64DecodeTransform()
        XCTAssertTrue(t.canApply(to: "SGVsbG8gV29ybGQ="))
        let result = t.apply(to: "SGVsbG8gV29ybGQ=")
        if case .success(let output) = result {
            XCTAssertEqual(output, "Hello World")
        } else {
            XCTFail("Transform failed")
        }
    }

    func testBase64DecodeInvalid() {
        let t = Base64DecodeTransform()
        XCTAssertFalse(t.canApply(to: "not base64 !!!"))
    }

    func testURLEncode() {
        let t = URLEncodeTransform()
        let result = t.apply(to: "hello world & more")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("hello%20world"))
            XCTAssertFalse(output.contains(" "))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testURLDecode() {
        let t = URLDecodeTransform()
        XCTAssertTrue(t.canApply(to: "hello%20world"))
        let result = t.apply(to: "hello%20world%26more")
        if case .success(let output) = result {
            XCTAssertEqual(output, "hello world&more")
        } else {
            XCTFail("Transform failed")
        }
    }

    // MARK: - JSON Transforms

    func testJSONPrettify() {
        let t = JSONPrettifyTransform()
        let input = "{\"name\":\"John\",\"age\":30}"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("  "))
            XCTAssertTrue(output.contains("\"name\""))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testJSONMinify() {
        let t = JSONMinifyTransform()
        let input = "{\n  \"name\": \"John\",\n  \"age\": 30\n}"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertFalse(output.contains("\n"))
            XCTAssertTrue(output.contains("\"name\""))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testJSONPrettifyInvalidJSON() {
        let t = JSONPrettifyTransform()
        XCTAssertFalse(t.canApply(to: "not json"))
    }

    func testJSONToSwiftStruct() {
        let t = JSONToSwiftStructTransform()
        let input = "{\"name\": \"John\", \"age\": 30, \"active\": true}"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("struct"))
            XCTAssertTrue(output.contains("Codable"))
            XCTAssertTrue(output.contains("String"))
            XCTAssertTrue(output.contains("Int") || output.contains("Double"))
            XCTAssertTrue(output.contains("Bool"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testJSONToSwiftStructNotObject() {
        let t = JSONToSwiftStructTransform()
        XCTAssertFalse(t.canApply(to: "[1,2,3]"))
    }

    // MARK: - cURL Transform

    func testCurlToURLSession() {
        let t = CurlToURLSessionTransform()
        let input = "curl -X POST https://api.example.com/data -H 'Content-Type: application/json' -d '{\"key\":\"value\"}'"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("URLRequest"))
            XCTAssertTrue(output.contains("api.example.com"))
            XCTAssertTrue(output.contains("POST"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testCurlCannotApplyToNonCurl() {
        let t = CurlToURLSessionTransform()
        XCTAssertFalse(t.canApply(to: "not a curl command"))
    }

    // MARK: - SQL Transform

    func testSQLToSwiftData() {
        let t = SQLToSwiftDataTransform()
        let input = "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT, age INTEGER)"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("@Model"))
            XCTAssertTrue(output.contains("class"))
            XCTAssertTrue(output.contains("name"))
            XCTAssertTrue(output.contains("String"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testSQLCannotApplyToNonSQL() {
        let t = SQLToSwiftDataTransform()
        XCTAssertFalse(t.canApply(to: "SELECT * FROM users"))
    }

    // MARK: - Markdown Transform

    func testMarkdownToPlainText() {
        let t = MarkdownToPlainTextTransform()
        let input = "# Heading\n\n**Bold** and *italic* text with `code`."
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertFalse(output.contains("#"))
            XCTAssertFalse(output.contains("**"))
            XCTAssertFalse(output.contains("`"))
            XCTAssertTrue(output.contains("Heading"))
            XCTAssertTrue(output.contains("Bold"))
        } else {
            XCTFail("Transform failed")
        }
    }

    // MARK: - XML Transform

    func testXMLPrettify() {
        let t = XMLPrettifyTransform()
        let input = "<root><child>value</child></root>"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("root"))
            XCTAssertTrue(output.contains("child"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testXMLCannotApplyToNonXML() {
        let t = XMLPrettifyTransform()
        XCTAssertFalse(t.canApply(to: "just text"))
    }

    // MARK: - Color Transforms

    func testHexToRGB() {
        let t = HexToRGBTransform()
        XCTAssertTrue(t.canApply(to: "#FF5733"))
        let result = t.apply(to: "#FF5733")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("rgb("))
            XCTAssertTrue(output.contains("255"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testHexToRGBShort() {
        let t = HexToRGBTransform()
        XCTAssertTrue(t.canApply(to: "#F00"))
        let result = t.apply(to: "#F00")
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("rgb("))
            XCTAssertTrue(output.contains("255"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testRGBToHex() {
        let t = RGBToHexTransform()
        XCTAssertTrue(t.canApply(to: "rgb(255, 87, 51)"))
        let result = t.apply(to: "rgb(255, 87, 51)")
        if case .success(let output) = result {
            XCTAssertTrue(output.hasPrefix("#"))
            XCTAssertEqual(output.count, 7) // #RRGGBB
        } else {
            XCTFail("Transform failed")
        }
    }

    func testRGBToHexWithAlpha() {
        let t = RGBToHexTransform()
        XCTAssertTrue(t.canApply(to: "rgba(255, 87, 51, 0.5)"))
    }

    // MARK: - Code Formatting Transforms

    func testStripLineNumbers() {
        let t = StripLineNumbersTransform()
        let input = "  1  func hello() {\n  2      print(\"hi\")\n  3  }\n  4  \n  5  // end"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            XCTAssertTrue(output.contains("func hello()"))
            XCTAssertFalse(output.hasPrefix("  1"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testNormalizeWhitespace() {
        let t = NormalizeWhitespaceTransform()
        // canApply checks for trailing spaces before \n
        let input = "hello   \n" + "world   \n"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            // Trailing whitespace should be stripped from each line
            XCTAssertFalse(output.contains("   \n"))
        } else {
            XCTFail("Transform failed")
        }
    }

    func testSortLines() {
        let t = SortLinesTransform()
        let input = "banana\napple\ncherry"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            let lines = output.components(separatedBy: "\n")
            XCTAssertEqual(lines.first, "apple")
            XCTAssertEqual(lines.last, "cherry")
        } else {
            XCTFail("Transform failed")
        }
    }

    func testRemoveDuplicateLines() {
        let t = RemoveDuplicateLinesTransform()
        let input = "apple\nbanana\napple\ncherry\nbanana"
        XCTAssertTrue(t.canApply(to: input))
        let result = t.apply(to: input)
        if case .success(let output) = result {
            let lines = output.components(separatedBy: "\n")
            XCTAssertEqual(lines.count, 3)
            XCTAssertEqual(lines, ["apple", "banana", "cherry"])
        } else {
            XCTFail("Transform failed")
        }
    }

    func testRemoveDuplicateLinesNoDuplicates() {
        let t = RemoveDuplicateLinesTransform()
        let input = "a\nb\nc"
        XCTAssertFalse(t.canApply(to: input))
    }

    // MARK: - TransformService Integration

    func testTransformServiceApplicableTransforms() {
        let service = TransformService.shared
        let json = "{\"name\": \"John\"}"
        let transforms = service.applicableTransforms(for: json)
        let names = transforms.map { $0.name }
        XCTAssertTrue(names.contains(where: { $0.lowercased().contains("prettify") || $0.lowercased().contains("json") }))
    }

    func testTransformServiceNoTransformsForPlainText() {
        let service = TransformService.shared
        let transforms = service.applicableTransforms(for: "hello")
        // Base64 encode should still be available for any non-empty text
        XCTAssertTrue(transforms.contains(where: { $0.name.lowercased().contains("base64") }))
    }
}
