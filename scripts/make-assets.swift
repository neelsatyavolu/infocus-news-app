// Renders the app icon and wordmarks into the asset catalog from the
// InFocus 2026 Package (DESIGN.md §1): the white icon on an Ink field like
// the channel avatar,
// full-bleed and opaque (iOS masks the corners), and the color / white
// wordmarks for light / dark appearance.
//
//   swift scripts/make-assets.swift "<path to InFocus 2026 Package/01 Logos>"
import AppKit

let logos = CommandLine.arguments.dropFirst().first
    ?? "\(NSHomeDirectory())/Downloads/InFocus/Show Resources/InFocus 2026 Package/01 Logos"
let assets = "InFocus/Resources/Assets.xcassets"
let ink = NSColor(srgbRed: 0x0F / 255, green: 0x11 / 255, blue: 0x0F / 255, alpha: 1)

func load(_ path: String) -> NSImage {
    guard let image = NSImage(contentsOfFile: "\(logos)/\(path)") else { fatalError("missing \(logos)/\(path)") }
    return image
}

/// Draws into an sRGB bitmap (opaque: no alpha channel at all) and writes a PNG.
func render(width: Int, height: Int, opaque: Bool, to path: String, draw: (NSRect) -> Void) {
    let info = opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info.rawValue)!
    context.interpolationQuality = .high
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    draw(NSRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()
    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

// App icon: the white mark (Soft White + green ring) at the avatar's ~56% on Ink.
let icon = load("Icon/infocus-icon-white.png")
render(width: 1024, height: 1024, opaque: true, to: "\(assets)/AppIcon.appiconset/AppIcon.png") { canvas in
    ink.setFill()
    canvas.fill()
    let side = canvas.width * 0.56
    icon.draw(in: NSRect(x: (canvas.width - side) / 2, y: (canvas.height - side) / 2, width: side, height: side))
}

// Wordmarks at 3× of a 160pt-wide mark.
for (name, file) in [("Wordmark", "Wordmark/infocus-wordmark-color.png"), ("WordmarkDark", "Wordmark/infocus-wordmark-white.png")] {
    let image = load(file)
    let width = 480, height = Int((Double(width) * image.size.height / image.size.width).rounded())
    render(width: width, height: height, opaque: false, to: "\(assets)/Wordmark.imageset/\(name).png") { canvas in
        image.draw(in: canvas)
    }
}

// The bare mark (color on light, white on dark), for empty states and onboarding.
for (name, file) in [("Mark", "Icon/infocus-icon-color.png"), ("MarkDark", "Icon/infocus-icon-white.png")] {
    let image = load(file)
    render(width: 384, height: 384, opaque: false, to: "\(assets)/Mark.imageset/\(name).png") { canvas in
        image.draw(in: canvas)
    }
}
