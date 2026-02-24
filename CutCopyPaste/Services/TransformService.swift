import Foundation

enum TransformError: LocalizedError {
    case invalidInput(String)
    case transformFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .transformFailed(let msg): return "Transform failed: \(msg)"
        }
    }
}

protocol ClipboardTransform: Identifiable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconSystemName: String { get }
    var inputSignatures: Set<ContentSignature> { get }

    func canApply(to text: String) -> Bool
    func apply(to text: String) -> Result<String, TransformError>
}

final class TransformService: @unchecked Sendable {
    static let shared = TransformService()

    private var transforms: [any ClipboardTransform] = []

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        transforms = [
            // Case transforms
            CamelToSnakeTransform(),
            SnakeToCamelTransform(),
            ToKebabCaseTransform(),
            // Encoding transforms
            Base64EncodeTransform(),
            Base64DecodeTransform(),
            URLEncodeTransform(),
            URLDecodeTransform(),
            // JSON transforms
            JSONPrettifyTransform(),
            JSONMinifyTransform(),
            JSONToSwiftStructTransform(),
            // cURL transform
            CurlToURLSessionTransform(),
            // SQL transform
            SQLToSwiftDataTransform(),
            // Markdown transform
            MarkdownToPlainTextTransform(),
            // XML transform
            XMLPrettifyTransform(),
            // Color transforms
            HexToRGBTransform(),
            RGBToHexTransform(),
            // Code formatting
            StripLineNumbersTransform(),
            NormalizeWhitespaceTransform(),
            SortLinesTransform(),
            RemoveDuplicateLinesTransform(),
        ]
    }

    func applicableTransforms(for text: String) -> [any ClipboardTransform] {
        let signatures = ContentAnalyzer.analyze(text)
        return transforms.filter { transform in
            !transform.inputSignatures.isDisjoint(with: signatures)
            && transform.canApply(to: text)
        }
    }

    func applicableTransforms(for item: ClipboardItem) -> [any ClipboardTransform] {
        guard let text = item.textContent else { return [] }
        return applicableTransforms(for: text)
    }

    func apply(_ transform: any ClipboardTransform, to text: String) -> Result<String, TransformError> {
        transform.apply(to: text)
    }
}
