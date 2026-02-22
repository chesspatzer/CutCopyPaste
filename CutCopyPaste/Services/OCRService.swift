import Vision
import AppKit
import os

actor OCRService {
    static let shared = OCRService()
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "OCR")

    private let minimumConfidence: Float = 0.3

    struct RecognizedLine {
        let text: String
        let confidence: Float
        let boundingBox: CGRect  // Normalized coordinates, origin bottom-left
    }

    func extractText(from imageData: Data) async throws -> String {
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        let rawLines = try await performRecognition(on: cgImage)
        return cleanUpOCRText(rawLines)
    }

    // MARK: - Vision Recognition

    private func performRecognition(on cgImage: CGImage) async throws -> [RecognizedLine] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let lines: [RecognizedLine] = observations.compactMap { observation in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return RecognizedLine(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.visionError(error))
            }
        }
    }

    // MARK: - Text Cleanup

    func cleanUpOCRText(_ rawLines: [RecognizedLine]) -> String {
        // 1. Filter out low-confidence observations
        let confidentLines = rawLines.filter { $0.confidence >= minimumConfidence }
        guard !confidentLines.isEmpty else { return "" }

        // 2. Sort by vertical position (top to bottom: higher Y = higher on page in normalized coords)
        let sorted = confidentLines.sorted { a, b in
            // Higher minY means higher on page — we want top-first
            if abs(a.boundingBox.minY - b.boundingBox.minY) > 0.005 {
                return a.boundingBox.minY > b.boundingBox.minY
            }
            // Same vertical line — sort left to right
            return a.boundingBox.minX < b.boundingBox.minX
        }

        // 3. Normalize whitespace and filter stray characters
        var cleaned: [(text: String, box: CGRect)] = sorted.compactMap { line in
            let normalized = normalizeWhitespace(line.text)
            if isStrayCharacters(normalized) { return nil }
            return (normalized, line.boundingBox)
        }
        guard !cleaned.isEmpty else { return "" }

        // 4. Remove consecutive duplicate lines
        cleaned = removeConsecutiveDuplicates(cleaned)

        // 5. Compute typical line height and spacing to detect paragraph gaps
        let lineHeights = cleaned.map { $0.box.height }
        let medianHeight = median(lineHeights)

        // 6. Build output with spatial-aware line spacing
        var result = cleaned[0].text

        for i in 1..<cleaned.count {
            let prev = cleaned[i - 1]
            let curr = cleaned[i]

            // Gap = bottom of previous line minus top of current line (normalized coords: prev bottom > curr top)
            let prevBottom = prev.box.minY
            let currTop = curr.box.maxY
            let gap = prevBottom - currTop

            // Determine spacing based on gap relative to line height
            if gap > medianHeight * 1.5 {
                // Large gap — paragraph break (blank line)
                result += "\n\n" + curr.text
            } else if gap > medianHeight * 0.8 {
                // Medium gap — possible section break, use blank line
                result += "\n\n" + curr.text
            } else {
                // Normal line spacing — decide whether to join or newline
                let shouldJoin = shouldJoinLines(prev.text, curr.text)
                if shouldJoin {
                    result += " " + curr.text
                } else {
                    result += "\n" + curr.text
                }
            }
        }

        // 7. Final cleanup: collapse excessive blank lines
        result = collapseBlankLines(result)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Line Joining Heuristics

    private func shouldJoinLines(_ prev: String, _ curr: String) -> Bool {
        let prevTrimmed = prev.trimmingCharacters(in: .whitespaces)
        let currTrimmed = curr.trimmingCharacters(in: .whitespaces)

        // Don't join if current line starts a new structural block
        if startsNewBlock(currTrimmed) { return false }

        // Don't join code-like lines (contain braces, semicolons, or heavy indentation)
        if looksLikeCode(prevTrimmed) || looksLikeCode(currTrimmed) { return false }

        // If previous ends with hyphen (word wrap), join without space
        // (handled by caller — here we just signal "join")
        if prevTrimmed.hasSuffix("-") { return true }

        // If previous line ends with sentence-terminating punctuation
        let lastChar = prevTrimmed.last
        let endsSentence = lastChar == "." || lastChar == "!" || lastChar == "?"

        if endsSentence {
            // If next line starts lowercase, it's likely a continuation (e.g. "Dr. smith")
            if let first = currTrimmed.first, first.isLowercase { return true }
            // Otherwise it's a new sentence — don't join (keep on separate line)
            return false
        }

        // If previous ends with colon, comma, or semicolon — keep separate
        if lastChar == ":" { return false }

        // Mid-line text that doesn't end with punctuation — likely a wrapped line
        return true
    }

    private func startsNewBlock(_ line: String) -> Bool {
        if line.isEmpty { return true }
        // Bullet points and list markers
        if line.hasPrefix("•") || line.hasPrefix("◦") || line.hasPrefix("▪") { return true }
        if line.hasPrefix("- ") || line.hasPrefix("* ") { return true }
        // Numbered lists (e.g. "1.", "2)", "a.")
        if let first = line.first, (first.isNumber || (first.isLetter && line.count > 1)) {
            let prefix = String(line.prefix(4))
            if prefix.contains(".") || prefix.contains(")") {
                let digits = prefix.prefix(while: { $0.isNumber })
                if !digits.isEmpty { return true }
            }
        }
        // Headings (all caps short lines)
        if line.count < 60 && line == line.uppercased() && line.contains(where: { $0.isLetter }) {
            let letters = line.filter { $0.isLetter }
            if letters.count >= 3 { return true }
        }
        // Markdown-style headings
        if line.hasPrefix("#") { return true }
        return false
    }

    private func looksLikeCode(_ line: String) -> Bool {
        // Lines with code-like syntax patterns
        let codeIndicators: [String] = ["{", "}", "()", "=>", "->", "func ", "def ", "class ",
                                         "var ", "let ", "const ", "import ", "return ", ";"]
        let matches = codeIndicators.filter { line.contains($0) }
        return matches.count >= 1 && line.contains(where: { $0 == "{" || $0 == "}" || $0 == ";" })
            || matches.count >= 2
    }

    // MARK: - Helpers

    private func normalizeWhitespace(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        // Collapse runs of spaces/tabs into single space (preserve intentional indentation at start)
        let leadingSpaces = trimmed.prefix(while: { $0 == " " || $0 == "\t" })
        let rest = trimmed.dropFirst(leadingSpaces.count)
        let collapsed = rest.replacing(/[ \t]{2,}/, with: " ")
        return String(leadingSpaces) + collapsed
    }

    private func isStrayCharacters(_ line: String) -> Bool {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        guard stripped.count <= 2 else { return false }
        // Keep meaningful short tokens: letters, digits, code brackets/braces
        let meaningfulChars: Set<Character> = ["{", "}", "(", ")", "[", "]", "<", ">"]
        return !stripped.contains(where: { $0.isLetter || $0.isNumber || meaningfulChars.contains($0) })
    }

    private func removeConsecutiveDuplicates(_ lines: [(text: String, box: CGRect)]) -> [(text: String, box: CGRect)] {
        guard !lines.isEmpty else { return [] }
        var result = [lines[0]]
        for i in 1..<lines.count {
            let current = lines[i].text.trimmingCharacters(in: .whitespaces)
            let previous = lines[i - 1].text.trimmingCharacters(in: .whitespaces)
            if current.isEmpty || current != previous {
                result.append(lines[i])
            }
        }
        return result
    }

    private func median(_ values: [CGFloat]) -> CGFloat {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        }
        return sorted[mid]
    }

    private func collapseBlankLines(_ text: String) -> String {
        text.replacing(/\n{3,}/, with: "\n\n")
    }

    enum OCRError: LocalizedError {
        case invalidImage
        case visionError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Could not process image data"
            case .visionError(let e): return "OCR failed: \(e.localizedDescription)"
            }
        }
    }
}
