import AppKit
import SwiftUI

@MainActor
enum IconGenerator {
    struct Entry {
        let filename: String
        let size: CGFloat
        let idiom: String
        let scale: String
    }

    static let entries: [Entry] = [
        .init(filename: "icon_16x16.png",     size: 16,   idiom: "mac", scale: "1x"),
        .init(filename: "icon_16x16@2x.png",  size: 32,   idiom: "mac", scale: "2x"),
        .init(filename: "icon_32x32.png",     size: 32,   idiom: "mac", scale: "1x"),
        .init(filename: "icon_32x32@2x.png",  size: 64,   idiom: "mac", scale: "2x"),
        .init(filename: "icon_128x128.png",   size: 128,  idiom: "mac", scale: "1x"),
        .init(filename: "icon_128x128@2x.png", size: 256, idiom: "mac", scale: "2x"),
        .init(filename: "icon_256x256.png",   size: 256,  idiom: "mac", scale: "1x"),
        .init(filename: "icon_256x256@2x.png", size: 512, idiom: "mac", scale: "2x"),
        .init(filename: "icon_512x512.png",   size: 512,  idiom: "mac", scale: "1x"),
        .init(filename: "icon_512x512@2x.png", size: 1024, idiom: "mac", scale: "2x"),
    ]

    @discardableResult
    static func exportToDesktop() throws -> URL {
        let fm = FileManager.default
        let desktop = fm.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")

        let iconset = desktop.appendingPathComponent("PulseAppIcon.appiconset")
        if fm.fileExists(atPath: iconset.path) {
            try fm.removeItem(at: iconset)
        }
        try fm.createDirectory(at: iconset, withIntermediateDirectories: true)

        for entry in entries {
            guard let data = renderPNG(size: entry.size) else { continue }
            try data.write(to: iconset.appendingPathComponent(entry.filename))
        }

        try writeContentsJSON(to: iconset)
        return iconset
    }

    private static func renderPNG(size: CGFloat) -> Data? {
        let view = AppIconView()
            .frame(width: size, height: size)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        guard let cgImage = renderer.cgImage else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = NSSize(width: size, height: size)
        return rep.representation(using: .png, properties: [:])
    }

    private static func writeContentsJSON(to directory: URL) throws {
        let images = entries.map { entry -> [String: String] in
            let pointSize = entry.scale == "2x" ? Int(entry.size / 2) : Int(entry.size)
            return [
                "idiom": entry.idiom,
                "scale": entry.scale,
                "size": "\(pointSize)x\(pointSize)",
                "filename": entry.filename
            ]
        }
        let payload: [String: Any] = [
            "images": images,
            "info": ["author": "xcode", "version": 1]
        ]
        let data = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.prettyPrinted, .sortedKeys]
        )
        try data.write(to: directory.appendingPathComponent("Contents.json"))
    }
}
