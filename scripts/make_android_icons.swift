#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation
import ImageIO

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let projectRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let sourceURL = projectRoot
    .appendingPathComponent("PrintClock")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")
    .appendingPathComponent("icon_1024.png")
let resURL = projectRoot
    .appendingPathComponent("android")
    .appendingPathComponent("app/src/main/res")

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let artwork = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Could not load \(sourceURL.path)")
}

let colorSpace = CGColorSpaceCreateDeviceRGB()

func render(size: Int, insetFraction: CGFloat) -> CGImage {
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

    let inset = CGFloat(size) * insetFraction
    context.draw(artwork, in: bounds.insetBy(dx: inset, dy: inset))

    guard let image = context.makeImage() else {
        fatalError("Could not render a \(size)px image")
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

// Legacy launcher icons (used below API 26 and as a fallback).
let legacy: [(String, Int)] = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192)
]
for (folder, size) in legacy {
    write(
        render(size: size, insetFraction: 0),
        to: resURL.appendingPathComponent(folder).appendingPathComponent("ic_launcher.png")
    )
    write(
        render(size: size, insetFraction: 0),
        to: resURL.appendingPathComponent(folder).appendingPathComponent("ic_launcher_round.png")
    )
}

// 108dp adaptive-icon foreground: leave room for the launcher mask.
write(
    render(size: 432, insetFraction: 1.0 / 6.0),
    to: resURL
        .appendingPathComponent("drawable-nodpi")
        .appendingPathComponent("ic_launcher_foreground.png")
)

write(
    render(size: 256, insetFraction: 0),
    to: resURL
        .appendingPathComponent("drawable-nodpi")
        .appendingPathComponent("app_icon.png")
)
