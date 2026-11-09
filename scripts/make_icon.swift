#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation
import ImageIO

// Renders the PrintClock app icon set from the artwork in assets/.
// Usage: swift scripts/make_icon.swift [output-directory]

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = projectRoot.appendingPathComponent("assets/PrintClockIconSource.jpg")

let outputDirectory: URL
if CommandLine.arguments.count > 1 {
    outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
} else {
    outputDirectory = projectRoot
        .appendingPathComponent("PrintClock")
        .appendingPathComponent("Assets.xcassets")
        .appendingPathComponent("AppIcon.appiconset")
}

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Could not load \(sourceURL.path)")
}

// The 1376x768 artwork has its rounded-square icon at this location.
let iconRect = CGRect(x: 388, y: 84, width: 600, height: 600)
guard let croppedArtwork = artwork.cropping(to: iconRect) else {
    fatalError("Could not crop the icon artwork")
}

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

let colorSpace = CGColorSpaceCreateDeviceRGB()
let sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create a \(size)px context")
    }

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    context.clear(bounds)
    context.interpolationQuality = .high
    context.setShouldAntialias(true)

    // Match the rounded-square silhouette of the artwork.
    let radius = CGFloat(size) * 0.218
    context.addPath(CGPath(
        roundedRect: bounds,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    ))
    context.clip()
    context.draw(croppedArtwork, in: bounds)

    guard let scaled = context.makeImage() else {
        fatalError("Could not render the \(size)px icon")
    }

    let destinationURL = outputDirectory.appendingPathComponent("icon_\(size).png")
    guard let destination = CGImageDestinationCreateWithURL(
        destinationURL as CFURL,
        "public.png" as CFString,
        1,
        nil
    ) else {
        fatalError("Could not create \(destinationURL.path)")
    }

    CGImageDestinationAddImage(destination, scaled, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not write \(destinationURL.path)")
    }

    print("Wrote \(destinationURL.path)")
}
