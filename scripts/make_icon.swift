#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

// Renders the 1024pt app icon. Usage: swift make_icon.swift <output-directory>

let arguments = CommandLine.arguments
let outputDirectory = arguments.count > 1
    ? arguments[1]
    : "TimeCalculator/Assets.xcassets/AppIcon.appiconset"

let canvas: CGFloat = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(canvas),
    pixelsHigh: Int(canvas),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Could not create bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Could not create drawing context")
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

// Background squircle
let inset: CGFloat = 54
let backgroundRect = CGRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let backgroundPath = CGPath(
    roundedRect: backgroundRect,
    cornerWidth: 218,
    cornerHeight: 218,
    transform: nil
)

context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -22),
    blur: 46,
    color: NSColor.black.withAlphaComponent(0.38).cgColor
)
context.addPath(backgroundPath)
context.setFillColor(NSColor.black.cgColor)
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(backgroundPath)
context.clip()

let backgroundGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        NSColor(srgbRed: 0.20, green: 0.16, blue: 0.58, alpha: 1).cgColor,
        NSColor(srgbRed: 0.43, green: 0.28, blue: 0.85, alpha: 1).cgColor,
        NSColor(srgbRed: 0.61, green: 0.40, blue: 0.96, alpha: 1).cgColor
    ] as CFArray,
    locations: [0, 0.55, 1]
)!

context.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 150, y: 930),
    end: CGPoint(x: 930, y: 110),
    options: []
)

// Soft light from the top-left
let glow = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        NSColor.white.withAlphaComponent(0.24).cgColor,
        NSColor.white.withAlphaComponent(0).cgColor
    ] as CFArray,
    locations: [0, 1]
)!

context.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: 320, y: 820),
    startRadius: 0,
    endCenter: CGPoint(x: 320, y: 820),
    endRadius: 660,
    options: []
)

context.restoreGState()

// Clock
let center = CGPoint(x: 512, y: 516)
let ringRadius: CGFloat = 246

context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -12),
    blur: 28,
    color: NSColor.black.withAlphaComponent(0.22).cgColor
)
context.setFillColor(NSColor.white.withAlphaComponent(0.06).cgColor)
context.fillEllipse(in: CGRect(
    x: center.x - ringRadius,
    y: center.y - ringRadius,
    width: ringRadius * 2,
    height: ringRadius * 2
))
context.restoreGState()

context.setStrokeColor(NSColor.white.withAlphaComponent(0.96).cgColor)
context.setLineWidth(45)
context.strokeEllipse(in: CGRect(
    x: center.x - ringRadius,
    y: center.y - ringRadius,
    width: ringRadius * 2,
    height: ringRadius * 2
))

// Tick marks
func point(angleDegrees: CGFloat, radius: CGFloat) -> CGPoint {
    let radians = angleDegrees * .pi / 180
    return CGPoint(
        x: center.x + sin(radians) * radius,
        y: center.y + cos(radians) * radius
    )
}

context.setLineCap(.round)

for tick in 0..<12 {
    let angle = CGFloat(tick) * 30
    let isMajor = tick % 3 == 0
    let innerRadius: CGFloat = isMajor ? 190 : 200
    let outerRadius: CGFloat = 218

    context.setStrokeColor(NSColor.white.withAlphaComponent(isMajor ? 0.72 : 0.40).cgColor)
    context.setLineWidth(isMajor ? 13 : 8)
    context.move(to: point(angleDegrees: angle, radius: innerRadius))
    context.addLine(to: point(angleDegrees: angle, radius: outerRadius))
    context.strokePath()
}

// Hands: 7:48
let hourAngle: CGFloat = (7 + 48.0 / 60.0) * 30
let minuteAngle: CGFloat = 48 * 6

context.setLineCap(.round)

context.setStrokeColor(NSColor.white.cgColor)
context.setLineWidth(31)
context.move(to: center)
context.addLine(to: point(angleDegrees: hourAngle, radius: 118))
context.strokePath()

context.setStrokeColor(NSColor(srgbRed: 1.0, green: 0.69, blue: 0.27, alpha: 1).cgColor)
context.setLineWidth(22)
context.move(to: center)
context.addLine(to: point(angleDegrees: minuteAngle, radius: 174))
context.strokePath()

// Center cap
context.setFillColor(NSColor(srgbRed: 1.0, green: 0.69, blue: 0.27, alpha: 1).cgColor)
context.fillEllipse(in: CGRect(x: center.x - 23, y: center.y - 23, width: 46, height: 46))
context.setFillColor(NSColor.white.cgColor)
context.fillEllipse(in: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20))

NSGraphicsContext.restoreGraphicsState()

// Save
try FileManager.default.createDirectory(
    atPath: outputDirectory,
    withIntermediateDirectories: true
)

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}

let outputURL = URL(fileURLWithPath: outputDirectory)
    .appendingPathComponent("icon_1024.png")
try png.write(to: outputURL)
print("Wrote \(outputURL.path)")
