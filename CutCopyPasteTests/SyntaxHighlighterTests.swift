import XCTest
@testable import CutCopyPaste

final class SyntaxHighlighterTests: XCTestCase {
    let highlighter = SyntaxHighlighter.shared

    // MARK: - Language Detection

    func testDetectSwift() {
        let code = """
        import SwiftUI

        struct ContentView: View {
            @State private var count = 0

            var body: some View {
                VStack {
                    Text("Hello \\(count)")
                    Button("Increment") {
                        count += 1
                    }
                }
            }
        }
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "swift")
    }

    func testDetectPython() {
        let code = """
        import os
        from pathlib import Path

        class FileProcessor:
            def __init__(self, path):
                self.path = path

            def process(self):
                for f in os.listdir(self.path):
                    if f.endswith('.txt'):
                        yield f

        proc = FileProcessor('/tmp')
        for item in proc.process():
            print(item)
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "python")
    }

    func testDetectJavaScript() {
        let code = """
        const express = require('express');
        const app = express();

        app.get('/api/users', async (req, res) => {
            const users = await fetchUsers();
            console.log('Found users:', users.length);
            res.json(users);
        });

        module.exports = app;
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "javascript")
    }

    func testDetectGo() {
        let code = """
        package main

        import "fmt"

        type Server struct {
            port int
        }

        func (s *Server) Start() {
            fmt.Println("Starting on port", s.port)
            go s.handleConnections()
        }

        func main() {
            server := &Server{port: 8080}
            server.Start()
        }
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "go")
    }

    func testDetectRust() {
        let code = """
        use std::collections::HashMap;

        pub struct Config {
            settings: HashMap<String, String>,
        }

        impl Config {
            pub fn new() -> Self {
                Config {
                    settings: HashMap::new(),
                }
            }

            fn get(&self, key: &str) -> Option<&String> {
                self.settings.get(key)
            }
        }
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "rust")
    }

    func testDetectJSON() {
        let code = """
        {
            "name": "John Doe",
            "age": 30,
            "address": {
                "street": "123 Main St",
                "city": "Springfield"
            }
        }
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "json")
    }

    func testDetectSQL() {
        let code = """
        SELECT u.name, u.email, COUNT(o.id) as order_count
        FROM users u
        LEFT JOIN orders o ON u.id = o.user_id
        WHERE u.active = 1
        GROUP BY u.id
        ORDER BY order_count DESC
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "sql")
    }

    func testDetectHTML() {
        let code = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Hello World</title>
        </head>
        <body>
            <div class="container">
                <h1>Welcome</h1>
                <p>Hello, world!</p>
            </div>
        </body>
        </html>
        """
        XCTAssertEqual(highlighter.detectLanguage(code), "html")
    }

    func testNoLanguageForPlainText() {
        let text = "This is just a normal sentence about something."
        XCTAssertNil(highlighter.detectLanguage(text))
    }

    func testNoLanguageForShortText() {
        XCTAssertNil(highlighter.detectLanguage("hi"))
    }

    // MARK: - Tokenization

    func testTokenizeSwiftHasKeywords() {
        let code = "func hello() { let x = 42; return x }"
        let tokens = highlighter.tokenize(code, language: "swift")
        let keywords = tokens.filter { $0.type == .keyword }
        XCTAssertFalse(keywords.isEmpty, "Should find keyword tokens")
    }

    func testTokenizeFindsStrings() {
        let code = "let name = \"Hello World\""
        let tokens = highlighter.tokenize(code, language: "swift")
        let strings = tokens.filter { $0.type == .string }
        XCTAssertFalse(strings.isEmpty, "Should find string tokens")
    }

    func testTokenizeFindsComments() {
        let code = "// This is a comment\nlet x = 1"
        let tokens = highlighter.tokenize(code, language: "swift")
        let comments = tokens.filter { $0.type == .comment }
        XCTAssertFalse(comments.isEmpty, "Should find comment tokens")
    }

    func testTokenizeFindsNumbers() {
        let code = "let x = 42"
        let tokens = highlighter.tokenize(code, language: "swift")
        let numbers = tokens.filter { $0.type == .number }
        XCTAssertFalse(numbers.isEmpty, "Should find number tokens")
    }

    func testTokenizePythonComments() {
        let code = "# This is a Python comment\nx = 42"
        let tokens = highlighter.tokenize(code, language: "python")
        let comments = tokens.filter { $0.type == .comment }
        XCTAssertFalse(comments.isEmpty, "Should find Python comment tokens")
    }

    // MARK: - Highlighting

    func testHighlightProducesAttributedString() {
        let code = "func hello() { return 42 }"
        let result = highlighter.highlight(code, language: "swift", isDark: false)
        XCTAssertGreaterThan(result.length, 0)
        XCTAssertEqual(result.string, code)
    }

    func testHighlightDarkMode() {
        let code = "let x = \"hello\""
        let light = highlighter.highlight(code, language: "swift", isDark: false)
        let dark = highlighter.highlight(code, language: "swift", isDark: true)
        // Both should have the same text
        XCTAssertEqual(light.string, dark.string)
        // But different colors (we can't easily compare NSColor, just verify no crash)
        XCTAssertGreaterThan(dark.length, 0)
    }

    // MARK: - Display Names

    func testDisplayNameForSwift() {
        XCTAssertEqual(SyntaxHighlighter.displayName(for: "swift"), "Swift")
    }

    func testDisplayNameForJavaScript() {
        XCTAssertEqual(SyntaxHighlighter.displayName(for: "javascript"), "JavaScript")
    }

    func testDisplayNameForUnknown() {
        XCTAssertEqual(SyntaxHighlighter.displayName(for: "brainfuck"), "Brainfuck")
    }
}
