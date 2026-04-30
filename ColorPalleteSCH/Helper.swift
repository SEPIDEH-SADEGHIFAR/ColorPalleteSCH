import SwiftUI
import UIKit

extension Color {
    // 1. Initialize a Color from a Hex String (Universal)
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        
        // Default to black if hex is invalid
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            self = .black
            return
        }
        
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >>  8) & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    // 2. Convert a Color to a Hex String (Platform Aware)
    func toHex() -> String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        #if canImport(UIKit)
        // Code for iOS
        let uiColor = UIColor(self)
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        
        #elseif canImport(AppKit)
        // Code for macOS
        let nsColor = NSColor(self)
        // We must convert to RGB color space or it might fail
        guard let converted = nsColor.usingColorSpace(.deviceRGB) else { return nil }
        r = converted.redComponent
        g = converted.greenComponent
        b = converted.blueComponent
        
        #else
        // Fallback if neither is available
        return nil
        #endif
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r) * 255),
                      lroundf(Float(g) * 255),
                      lroundf(Float(b) * 255))
    }
}
