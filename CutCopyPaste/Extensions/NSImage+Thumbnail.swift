import AppKit

extension NSImage {
    /// Resize image to fit within maxSize, preserving aspect ratio. Returns PNG data.
    func resizedForThumbnail(maxSize: CGFloat) -> Data? {
        let currentSize = self.size
        guard currentSize.width > 0, currentSize.height > 0 else { return nil }

        let scale: CGFloat
        if currentSize.width > currentSize.height {
            scale = maxSize / currentSize.width
        } else {
            scale = maxSize / currentSize.height
        }

        let newSize = CGSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: currentSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()

        guard let tiff = newImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
