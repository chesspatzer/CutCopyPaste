import Foundation

struct HexToRGBTransform: ClipboardTransform {
    let id = "hex_to_rgb"
    let name = "Hex → RGB"
    let description = "Convert hex color to rgb() format"
    let iconSystemName = "paintpalette"
    let inputSignatures: Set<ContentSignature> = [.hexColor]

    func canApply(to text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: "^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$",
                            options: .regularExpression) != nil
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var hex = String(trimmed.dropFirst()) // remove #

        // Expand shorthand (#ABC -> #AABBCC)
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }

        guard hex.count >= 6 else {
            return .failure(.invalidInput("Invalid hex color"))
        }

        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)

        if hex.count == 8 {
            let r = Int((value >> 24) & 0xFF)
            let g = Int((value >> 16) & 0xFF)
            let b = Int((value >> 8) & 0xFF)
            let a = Double(value & 0xFF) / 255.0
            return .success(String(format: "rgba(%d, %d, %d, %.2f)", r, g, b, a))
        } else {
            let r = Int((value >> 16) & 0xFF)
            let g = Int((value >> 8) & 0xFF)
            let b = Int(value & 0xFF)
            return .success("rgb(\(r), \(g), \(b))")
        }
    }
}

struct RGBToHexTransform: ClipboardTransform {
    let id = "rgb_to_hex"
    let name = "RGB → Hex"
    let description = "Convert rgb() color to hex format"
    let iconSystemName = "paintpalette"
    let inputSignatures: Set<ContentSignature> = [.rgbColor]

    func canApply(to text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("rgb(") || trimmed.hasPrefix("rgba(")
    }

    func apply(to text: String) -> Result<String, TransformError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "rgba?\\(\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)\\s*(?:,\\s*([\\d.]+))?\\s*\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return .failure(.invalidInput("Could not parse rgb() color"))
        }

        guard let rRange = Range(match.range(at: 1), in: trimmed),
              let gRange = Range(match.range(at: 2), in: trimmed),
              let bRange = Range(match.range(at: 3), in: trimmed),
              let r = Int(trimmed[rRange]),
              let g = Int(trimmed[gRange]),
              let b = Int(trimmed[bRange]) else {
            return .failure(.invalidInput("Invalid RGB values"))
        }

        if match.range(at: 4).location != NSNotFound,
           let aRange = Range(match.range(at: 4), in: trimmed),
           let a = Double(trimmed[aRange]) {
            let alpha = Int(a * 255)
            return .success(String(format: "#%02X%02X%02X%02X", r, g, b, alpha))
        }

        return .success(String(format: "#%02X%02X%02X", r, g, b))
    }
}
