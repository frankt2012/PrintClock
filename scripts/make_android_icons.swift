#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation
import ImageIO

// Renders the Android launcher icons from the circular Android artwork in assets/.
// The macOS app icon is generated separately by scripts/make_icon.swift.

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = projectRoot.appendingPathComponent("assets/PrintClockAndroidIconSource.jpg")
let resURL = projectRoot
    .appendingPathComponent("android")
    .appendingPathComponent("app/src/main/res")

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Could not load \(sourceURL.path)")
}

let colorSpace = CGColorSpaceCreateDeviceRGB()

/// The artwork is a circular icon on a dark square. Cut out the disc so the
/// adaptive-icon background shows through the corners.
func makeDisc() -> CGImage {
    let size = 1024
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Could not create the disc context")
    }

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    context.clear(bounds)
    context.interpolationQuality = .high
    context.setShouldAntialias(true)
    context.addEllipse(in: bounds.insetBy(dx: 82, dy: 82))
    context.clip()
    context.draw(artwork, in: bounds)

    guard let image = context.makeImage() else {
        fatalError("Could not render the disc")
    }
    return image
}

func renderDisc(size: Int, discFraction: CGFloat = 1.0) -> CGImage {
    let disc = makeDisc()
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

    let discSize = CGFloat(size) * discFraction
    let inset = (CGFloat(size) - discSize) / 2
    context.draw(disc, in: bounds.insetBy(dx: inset, dy: inset))

    guard let image = context.makeImage() else {
        fatalError("Could not render a \(size)px icon")
    }
    return image
}

func write(_ image: CGImage, to url: URL) {
    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        "public.png" as CFString,
        1,
        nil
    ) else {
        fatalError("Could not write \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not finalize \(url.path)")
    }
    print("Wrote \(url.path)")
}

let legacy: [(String, Int)] = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192)
]
for (folder, size) in legacy {
    let image = renderDisc(size: size)
    write(
        image,
        to: resURL.appendingPathComponent(folder).appendingPathComponent("ic_launcher.png")
    )
    write(
        image,
        to: resURL.appendingPathComponent(folder).appendingPathComponent("ic_launcher_round.png")
    )
}

// 108dp adaptive-icon foreground: the disc fits inside the launcher mask.
write(
    renderDisc(size: 432, discFraction: 2.0 / 3.0),
    to: resURL
        .appendingPathComponent("drawable-nodpi")
        .appendingPathComponent("ic_launcher_foreground.png")
)

// Header and widget artwork.
write(
    renderDisc(size: 256),
    to: resURL
        .appendingPathComponent("drawable-nodpi")
        .appendingPathComponent("app_icon.png")
)
