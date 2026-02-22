import AppKit
import Foundation

extension Data {
    /// Convert TIFF data to compressed PNG.
    func compressedAsPNG() -> Data? {
        guard let rep = NSBitmapImageRep(data: self) else { return nil }
        return rep.representation(using: .png, properties: [.compressionFactor: 0.8])
    }
}
