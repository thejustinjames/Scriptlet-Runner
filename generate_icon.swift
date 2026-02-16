#!/usr/bin/env swift

import AppKit
import Foundation

// Create a golden pig face icon on black background

func createPigIcon(pixelSize: Int) -> NSImage {
    let size = NSSize(width: pixelSize, height: pixelSize)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context

    let cgContext = context.cgContext

    let w = CGFloat(pixelSize)
    let h = CGFloat(pixelSize)

    // Black background
    cgContext.setFillColor(CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0))
    cgContext.fill(CGRect(x: 0, y: 0, width: w, height: h))

    let centerX = w / 2
    let centerY = h / 2
    let faceRadius = w * 0.35

    // Golden colors
    let goldMain = CGColor(red: 0.85, green: 0.65, blue: 0.20, alpha: 1.0)
    let goldLight = CGColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1.0)
    let goldDark = CGColor(red: 0.70, green: 0.50, blue: 0.15, alpha: 1.0)
    let goldVeryDark = CGColor(red: 0.45, green: 0.30, blue: 0.10, alpha: 1.0)
    let pink = CGColor(red: 0.95, green: 0.70, blue: 0.65, alpha: 1.0)

    // Ears (behind face)
    let earRadius = w * 0.15
    let earY = centerY + faceRadius * 0.6

    // Left ear
    cgContext.setFillColor(goldMain)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius * 0.8 - earRadius/2,
        y: earY - earRadius/2,
        width: earRadius * 1.2,
        height: earRadius * 1.4
    ))

    // Left ear inner
    cgContext.setFillColor(pink)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius * 0.75 - earRadius/3,
        y: earY - earRadius/3,
        width: earRadius * 0.6,
        height: earRadius * 0.8
    ))

    // Right ear
    cgContext.setFillColor(goldMain)
    cgContext.fillEllipse(in: CGRect(
        x: centerX + faceRadius * 0.8 - earRadius/2 - earRadius * 0.2,
        y: earY - earRadius/2,
        width: earRadius * 1.2,
        height: earRadius * 1.4
    ))

    // Right ear inner
    cgContext.setFillColor(pink)
    cgContext.fillEllipse(in: CGRect(
        x: centerX + faceRadius * 0.8 - earRadius/3 - earRadius * 0.2,
        y: earY - earRadius/3,
        width: earRadius * 0.6,
        height: earRadius * 0.8
    ))

    // Main face - golden gradient effect (draw multiple circles)
    cgContext.setFillColor(goldDark)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius,
        y: centerY - faceRadius,
        width: faceRadius * 2,
        height: faceRadius * 2
    ))

    cgContext.setFillColor(goldMain)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius * 0.95,
        y: centerY - faceRadius * 0.92,
        width: faceRadius * 1.9,
        height: faceRadius * 1.9
    ))

    // Highlight on face
    cgContext.setFillColor(goldLight)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius * 0.5,
        y: centerY + faceRadius * 0.1,
        width: faceRadius * 0.8,
        height: faceRadius * 0.6
    ))

    // Snout
    let snoutWidth = faceRadius * 0.8
    let snoutHeight = faceRadius * 0.5
    let snoutY = centerY - faceRadius * 0.3

    cgContext.setFillColor(goldLight)
    cgContext.fillEllipse(in: CGRect(
        x: centerX - snoutWidth/2,
        y: snoutY - snoutHeight/2,
        width: snoutWidth,
        height: snoutHeight
    ))

    // Nostrils
    let nostrilRadius = snoutWidth * 0.12
    cgContext.setFillColor(goldVeryDark)

    // Left nostril
    cgContext.fillEllipse(in: CGRect(
        x: centerX - snoutWidth * 0.2 - nostrilRadius,
        y: snoutY - nostrilRadius * 0.8,
        width: nostrilRadius * 1.5,
        height: nostrilRadius * 1.6
    ))

    // Right nostril
    cgContext.fillEllipse(in: CGRect(
        x: centerX + snoutWidth * 0.2 - nostrilRadius * 0.5,
        y: snoutY - nostrilRadius * 0.8,
        width: nostrilRadius * 1.5,
        height: nostrilRadius * 1.6
    ))

    // Eyes
    let eyeRadius = faceRadius * 0.18
    let eyeY = centerY + faceRadius * 0.2
    let eyeSpacing = faceRadius * 0.45

    // Eye whites
    cgContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    cgContext.fillEllipse(in: CGRect(
        x: centerX - eyeSpacing - eyeRadius,
        y: eyeY - eyeRadius,
        width: eyeRadius * 2,
        height: eyeRadius * 2
    ))
    cgContext.fillEllipse(in: CGRect(
        x: centerX + eyeSpacing - eyeRadius,
        y: eyeY - eyeRadius,
        width: eyeRadius * 2,
        height: eyeRadius * 2
    ))

    // Pupils
    let pupilRadius = eyeRadius * 0.55
    cgContext.setFillColor(CGColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 1))
    cgContext.fillEllipse(in: CGRect(
        x: centerX - eyeSpacing - pupilRadius,
        y: eyeY - pupilRadius * 0.8,
        width: pupilRadius * 2,
        height: pupilRadius * 2
    ))
    cgContext.fillEllipse(in: CGRect(
        x: centerX + eyeSpacing - pupilRadius,
        y: eyeY - pupilRadius * 0.8,
        width: pupilRadius * 2,
        height: pupilRadius * 2
    ))

    // Eye shine
    let shineRadius = pupilRadius * 0.4
    cgContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
    cgContext.fillEllipse(in: CGRect(
        x: centerX - eyeSpacing - pupilRadius * 0.3,
        y: eyeY + pupilRadius * 0.2,
        width: shineRadius,
        height: shineRadius
    ))
    cgContext.fillEllipse(in: CGRect(
        x: centerX + eyeSpacing - pupilRadius * 0.3,
        y: eyeY + pupilRadius * 0.2,
        width: shineRadius,
        height: shineRadius
    ))

    // Cheek blush
    cgContext.setFillColor(CGColor(red: 0.95, green: 0.60, blue: 0.55, alpha: 0.4))
    cgContext.fillEllipse(in: CGRect(
        x: centerX - faceRadius * 0.75 - faceRadius * 0.15,
        y: centerY - faceRadius * 0.15,
        width: faceRadius * 0.3,
        height: faceRadius * 0.2
    ))
    cgContext.fillEllipse(in: CGRect(
        x: centerX + faceRadius * 0.75 - faceRadius * 0.15,
        y: centerY - faceRadius * 0.15,
        width: faceRadius * 0.3,
        height: faceRadius * 0.2
    ))

    NSGraphicsContext.restoreGraphicsState()

    let image = NSImage(size: size)
    image.addRepresentation(rep)
    return image
}

func savePNG(image: NSImage, to path: String) {
    guard let rep = image.representations.first as? NSBitmapImageRep,
          let pngData = rep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Failed to save \(path): \(error)")
    }
}

// Icon sizes for macOS app icon (exact pixel sizes needed)
let sizes: [(pixelSize: Int, suffix: String)] = [
    (16, "16x16"),
    (32, "16x16@2x"),
    (32, "32x32"),
    (64, "32x32@2x"),
    (128, "128x128"),
    (256, "128x128@2x"),
    (256, "256x256"),
    (512, "256x256@2x"),
    (512, "512x512"),
    (1024, "512x512@2x")
]

let basePath = "/Users/justin/Documents/GitHub/scriptletRunner/ScriptletRunner/Assets.xcassets/AppIcon.appiconset"

for (pixelSize, suffix) in sizes {
    let image = createPigIcon(pixelSize: pixelSize)
    let filename = "icon_\(suffix).png"
    savePNG(image: image, to: "\(basePath)/\(filename)")
}

print("Icon generation complete!")
