import SwiftUI

extension Color {
    static let pulseGreen  = Color(hex: 0x1D9E75)
    static let pulseAmber  = Color(hex: 0xEF9F27)
    static let pulseRed    = Color(hex: 0xE24B4A)
    static let pulseBlue   = Color(hex: 0x378ADD)
    static let pulsePurple = Color(hex: 0x7F77DD)
    static let pulseDark   = Color(hex: 0x0D1219)
    static let pulseNavy   = Color(hex: 0x1A2535)
    static let pulseGlowSparkle = Color(hex: 0x5DCAA5)

    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

#if canImport(AppKit)
import AppKit

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }

    static let pulseGreen  = NSColor(hex: 0x1D9E75)
    static let pulseAmber  = NSColor(hex: 0xEF9F27)
    static let pulseRed    = NSColor(hex: 0xE24B4A)
    static let pulseBlue   = NSColor(hex: 0x378ADD)
    static let pulsePurple = NSColor(hex: 0x7F77DD)
}
#endif
