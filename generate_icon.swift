#!/usr/bin/swift

import AppKit

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let outputDir = "CutCopyPaste/Resources/Assets.xcassets/AppIcon.appiconset"

for (name, px) in sizes {
    let size = CGSize(width: px, height: px)
    let image = NSImage(size: size, flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        // Background: blue-to-purple gradient with rounded rect
        let cornerRadius = CGFloat(px) * 0.22
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(path)
        ctx.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors = [
            CGColor(red: 0.25, green: 0.47, blue: 0.95, alpha: 1.0),  // Blue
            CGColor(red: 0.55, green: 0.30, blue: 0.90, alpha: 1.0),  // Purple
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(gradient,
                start: CGPoint(x: 0, y: CGFloat(px)),
                end: CGPoint(x: CGFloat(px), y: 0),
                options: [])
        }

        // Draw clipboard shape in white
        ctx.setFillColor(CGColor.white)

        let scale = CGFloat(px) / 512.0

        // Clipboard body
        let bodyW = 260 * scale
        let bodyH = 320 * scale
        let bodyX = (CGFloat(px) - bodyW) / 2
        let bodyY = (CGFloat(px) - bodyH) / 2 - 15 * scale
        let bodyRadius = 24 * scale
        let bodyRect = CGRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
        let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyRadius, cornerHeight: bodyRadius, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
        ctx.addPath(bodyPath)
        ctx.fillPath()

        // Clipboard clip (top tab)
        let clipW = 120 * scale
        let clipH = 50 * scale
        let clipX = (CGFloat(px) - clipW) / 2
        let clipY = bodyY + bodyH - 20 * scale
        let clipRadius = 12 * scale
        let clipRect = CGRect(x: clipX, y: clipY, width: clipW, height: clipH)
        let clipPath = CGPath(roundedRect: clipRect, cornerWidth: clipRadius, cornerHeight: clipRadius, transform: nil)
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
        ctx.addPath(clipPath)
        ctx.fillPath()

        // Inner lines (text lines on clipboard)
        ctx.setFillColor(CGColor(red: 0.25, green: 0.47, blue: 0.95, alpha: 0.35))
        let lineInset = 45 * scale
        let lineH = 16 * scale
        let lineSpacing = 36 * scale

        for i in 0..<4 {
            let lineY = bodyY + 40 * scale + CGFloat(i) * lineSpacing
            let lineW = (i == 3) ? (bodyW - lineInset * 2) * 0.6 : (bodyW - lineInset * 2)
            let lineRect = CGRect(x: bodyX + lineInset, y: lineY, width: lineW, height: lineH)
            let linePath = CGPath(roundedRect: lineRect, cornerWidth: lineH / 2, cornerHeight: lineH / 2, transform: nil)
            ctx.addPath(linePath)
            ctx.fillPath()
        }

        return true
    }

    // Convert to PNG
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(name)")
        continue
    }

    let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    do {
        try png.write(to: url)
        print("Generated \(name).png (\(px)x\(px))")
    } catch {
        print("Failed to write \(name): \(error)")
    }
}

print("Done!")
