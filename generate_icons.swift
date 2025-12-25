#!/usr/bin/env swift

import Foundation
import CoreGraphics
import AppKit

// Create a simple clipboard icon that works well in both light and dark modes
func createClipboardIcon(size: CGFloat) -> NSImage {
    // Create bitmap representation with exact pixel dimensions
    let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: Int(size),
                                     pixelsHigh: Int(size),
                                     bitsPerSample: 8,
                                     samplesPerPixel: 4,
                                     hasAlpha: true,
                                     isPlanar: false,
                                     colorSpaceName: .deviceRGB,
                                     bitmapFormat: [],
                                     bytesPerRow: 0,
                                     bitsPerPixel: 0)!

    // Draw directly into the bitmap
    let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
    NSGraphicsContext.current = context

    // Clear background
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    // Create a simple clipboard design
    let rect = NSRect(x: size * 0.2, y: size * 0.15, width: size * 0.6, height: size * 0.7)

    // Main clipboard body (white/light gray)
    NSColor.white.set()
    let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.1, yRadius: size * 0.1)
    path.fill()

    // Border (dark gray for both modes)
    NSColor.gray.set()
    path.lineWidth = size * 0.02
    path.stroke()

    // Clip at the top
    let clipRect = NSRect(x: size * 0.35, y: size * 0.8, width: size * 0.3, height: size * 0.1)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: size * 0.05, yRadius: size * 0.05)
    NSColor.gray.set()
    clipPath.fill()

    NSGraphicsContext.current = nil

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(bitmapRep)
    return image
}

// Generate icons for all required pixel sizes based on Contents.json usage
// For macOS: size field is logical points, scale is multiplier
// icon_32x32.png: used for 16x16@2x (32px) and 32x32@1x (32px) → needs 32px
// icon_64x64.png: used for 32x32@2x (64px) → needs 64px
// icon_128x128.png: used for 128x128@1x (128px) → needs 128px
// icon_256x256.png: used for 128x128@2x (256px) and 256x256@1x (256px) → needs 256px
// icon_512x512.png: used for 256x256@2x (512px) and 512x512@1x (512px) → needs 512px
// icon_1024x1024.png: used for 512x512@2x (1024px) and iOS sizes → needs 1024px
let sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    let icon = createClipboardIcon(size: CGFloat(size))

    // Save as PNG - use the bitmap representation we created
    if let bitmapImage = icon.representations.first as? NSBitmapImageRep,
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {

        let filename = "icon_\(size)x\(size).png"
        let fileURL = URL(fileURLWithPath: filename)

        do {
            try pngData.write(to: fileURL)
            print("Generated \(filename)")
        } catch {
            print("Failed to save \(filename): \(error)")
        }
    }
}

print("Icon generation complete!")
