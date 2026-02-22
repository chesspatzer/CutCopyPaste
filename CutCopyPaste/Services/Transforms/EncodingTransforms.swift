import Foundation

struct Base64EncodeTransform: ClipboardTransform {
    let id = "base64_encode"
    let name = "Base64 Encode"
    let description = "Encode text as Base64"
    let iconSystemName = "lock"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        !text.isEmpty
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let data = text.data(using: .utf8) else {
            return .failure(.invalidInput("Could not encode text as UTF-8"))
        }
        return .success(data.base64EncodedString())
    }
}

struct Base64DecodeTransform: ClipboardTransform {
    let id = "base64_decode"
    let name = "Base64 Decode"
    let description = "Decode Base64 text"
    let iconSystemName = "lock.open"
    let inputSignatures: Set<ContentSignature> = [.base64]

    func canApply(to text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Data(base64Encoded: trimmed) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: trimmed),
              let decoded = String(data: data, encoding: .utf8) else {
            return .failure(.transformFailed("Invalid Base64 string"))
        }
        return .success(decoded)
    }
}

struct URLEncodeTransform: ClipboardTransform {
    let id = "url_encode"
    let name = "URL Encode"
    let description = "Percent-encode text for URLs"
    let iconSystemName = "link.badge.plus"
    let inputSignatures: Set<ContentSignature> = [.plainText]

    func canApply(to text: String) -> Bool {
        !text.isEmpty
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(.transformFailed("Could not URL-encode text"))
        }
        return .success(encoded)
    }
}

struct URLDecodeTransform: ClipboardTransform {
    let id = "url_decode"
    let name = "URL Decode"
    let description = "Decode percent-encoded text"
    let iconSystemName = "link"
    let inputSignatures: Set<ContentSignature> = [.urlEncoded]

    func canApply(to text: String) -> Bool {
        text.contains("%")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        guard let decoded = text.removingPercentEncoding else {
            return .failure(.transformFailed("Could not decode URL-encoded text"))
        }
        return .success(decoded)
    }
}
