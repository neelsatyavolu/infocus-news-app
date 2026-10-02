import SwiftUI
import UIKit

/// InFocus Design System 2026 (DESIGN.md §2, §10, §13): Ink surfaces in dark,
/// Mist 20 in light, InFocus Green fills with Soft White text, Green on Dark
/// for small marks, Record Red only for the LIVE dot.
enum Brand {
    static let radius: CGFloat = 6
    static let tagRadius: CGFloat = 4
    static let gutter: CGFloat = 16
    /// Widest a page column gets (iPad, landscape): about 70 characters of body text.
    static let readableWidth: CGFloat = 760

    // Surfaces
    static let background = Color.dynamic(dark: 0x0F110F, light: 0xF4F6F5)
    static let card = Color.dynamic(dark: 0x1A1D1A, light: 0xFFFFFF)
    static let raised = Color.dynamic(dark: 0x252925, light: 0xE9EEEB)
    static let line = Color.dynamic(dark: 0x2B302B, light: 0xD5DCD7)
    /// Borders that show where a control is (3:1 contrast).
    static let controlLine = Color.dynamic(dark: 0x6B726D, light: 0x7F8782)

    // Text
    static let text = Color.dynamic(dark: 0xECEFEA, light: 0x0F110F)
    static let secondary = Color.dynamic(dark: 0xDCE2DE, light: 0x4B524D)
    static let muted = Color.dynamic(dark: 0xA3ABA6, light: 0x535A55)

    // Brand
    static let ink = Color(hex: 0x0F110F)
    static let softWhite = Color(hex: 0xECEFEA)
    static let fill = Color(hex: 0x0B6E3E)
    static let fillPressed = Color.dynamic(dark: 0x0E7D47, light: 0x085A32)
    /// Green for text, links, icons and small marks (never a large fill).
    static let green = Color.dynamic(dark: 0x2BB36E, light: 0x0B6E3E)
    static let greenTint = Color.dynamic(dark: 0x2BB36E, light: 0x0B6E3E, alpha: 0.14)
    static let recordRed = Color(hex: 0xEE3A2A)

    // Status
    static let danger = Color.dynamic(dark: 0xFF7A8A, light: 0xC21F3A)
    static let dangerTint = Color.dynamic(dark: 0x3A1218, light: 0xFDECEE)
    static let warning = Color.dynamic(dark: 0xF2A516, light: 0xB45309)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(uiColor: UIColor(hex: hex, alpha: alpha))
    }

    static func dynamic(dark: UInt32, light: UInt32, alpha: Double = 1) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light, alpha: alpha)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
