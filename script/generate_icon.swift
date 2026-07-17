#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_icon.swift OUTPUT.png\n", stderr)
    exit(2)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
let background = NSBezierPath(
    roundedRect: canvas.insetBy(dx: 40, dy: 40),
    xRadius: 220,
    yRadius: 220
)
NSGradient(
    colors: [
        NSColor(calibratedRed: 0.03, green: 0.42, blue: 0.68, alpha: 1),
        NSColor(calibratedRed: 0.04, green: 0.76, blue: 0.76, alpha: 1),
    ]
)?.draw(in: background, angle: -55)

let bowlRect = NSRect(x: 196, y: 185, width: 632, height: 610)
let bowl = NSBezierPath(ovalIn: bowlRect)
NSColor.white.withAlphaComponent(0.18).setFill()
bowl.fill()
NSColor.white.withAlphaComponent(0.9).setStroke()
bowl.lineWidth = 34
bowl.stroke()

let water = NSBezierPath()
water.move(to: NSPoint(x: 233, y: 500))
water.curve(
    to: NSPoint(x: 791, y: 500),
    controlPoint1: NSPoint(x: 380, y: 455),
    controlPoint2: NSPoint(x: 645, y: 548)
)
water.appendArc(
    withCenter: NSPoint(x: 512, y: 490),
    radius: 280,
    startAngle: 0,
    endAngle: 180,
    clockwise: true
)
water.close()
NSColor(calibratedRed: 0.03, green: 0.55, blue: 0.82, alpha: 0.78).setFill()
water.fill()

let fishBody = NSBezierPath(ovalIn: NSRect(x: 350, y: 385, width: 285, height: 165))
NSColor(calibratedRed: 1, green: 0.62, blue: 0.18, alpha: 1).setFill()
fishBody.fill()

let tail = NSBezierPath()
tail.move(to: NSPoint(x: 620, y: 466))
tail.line(to: NSPoint(x: 755, y: 570))
tail.line(to: NSPoint(x: 755, y: 365))
tail.close()
tail.fill()

NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 405, y: 480, width: 30, height: 30)).fill()

for bubble in [
    NSRect(x: 300, y: 630, width: 42, height: 42),
    NSRect(x: 690, y: 650, width: 58, height: 58),
    NSRect(x: 650, y: 585, width: 28, height: 28),
] {
    NSColor.white.withAlphaComponent(0.72).setStroke()
    let path = NSBezierPath(ovalIn: bubble)
    path.lineWidth = 12
    path.stroke()
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("failed to render icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
