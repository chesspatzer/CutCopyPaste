import Vision
import AppKit
import os

actor OCRService {
    static let shared = OCRService()
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "OCR")

    func extractText(from imageData: Data) async throws -> String {
        guard let nsImage = NSImage(data: imageData),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
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
