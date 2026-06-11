import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// ⚠️  ADD THIS FILE TO BOTH TARGETS IN XCODE
//     Main App target  +  Widget Extension target
//
// SETUP STEPS:
// 1. Main app target → Signing & Capabilities → + Capability
//    → App Groups → + → group.com.yourname.awby
// 2. Widget extension target → same App Groups capability → same group ID
// 3. Change appGroupID below to match exactly
// ─────────────────────────────────────────────────────────────────────────────

let appGroupID = "group.com.SeyedehSepidehSadeghiFar.awby"   // ← change this

// ═════════════════════════════════════════════════════════════
// MARK: - SHARED MODELS
// ═════════════════════════════════════════════════════════════

struct WidgetPaletteData: Codable, Equatable {
    let id:     String
    let title:  String
    let colors: [WidgetColorData]
    var style:  WidgetDisplayStyle

    struct WidgetColorData: Codable, Equatable {
        let name: String
        let hex:  String
    }

    static let placeholder = WidgetPaletteData(
        id: "placeholder",
        title: "Ocean Tones",
        colors: [
            .init(name: "Cerulean",  hex: "#2A9D8F"),
            .init(name: "Deep Navy", hex: "#1D3557"),
            .init(name: "Sky Blue",  hex: "#87CEEB"),
            .init(name: "Seafoam",   hex: "#2DD4BF"),
            .init(name: "Arctic",    hex: "#A8DADC"),
        ],
        style: .stripes
    )
}

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET DISPLAY STYLE
// ═════════════════════════════════════════════════════════════

enum WidgetDisplayStyle: String, Codable, CaseIterable, Identifiable {
    // ── Original styles (improved) ──────────────────────────
    case stripes  = "Stripes"
    case cards    = "Cards"
    case mosaic   = "Mosaic"
    // ── New styles ──────────────────────────────────────────
    case spectrum = "Spectrum"
    case ink      = "Ink"
    case arch     = "Arch"
    case minimal  = "Minimal"
    case neon     = "Neon"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stripes:  return "rectangle.split.3x1"
        case .cards:    return "list.bullet.rectangle"
        case .mosaic:   return "square.grid.2x2"
        case .spectrum: return "paintbrush.pointed.fill"
        case .ink:      return "drop.fill"
        case .arch:     return "rainbow"
        case .minimal:  return "minus.rectangle"
        case .neon:     return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .stripes:  return "Bold colour stripes"
        case .cards:    return "Colour list on dark"
        case .mosaic:   return "Square swatch grid"
        case .spectrum: return "Smooth gradient blend"
        case .ink:      return "Abstract ink circles"
        case .arch:     return "Stacked rainbow arches"
        case .minimal:  return "Clean, typography‑first"
        case .neon:     return "Glowing dots on dark"
        }
    }

    var isNew: Bool {
        switch self {
        case .spectrum, .ink, .arch, .minimal, .neon: return true
        default: return false
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - DATA MANAGER
// ═════════════════════════════════════════════════════════════

enum WidgetDataManager {
    private static let key      = "awby_widget_palette"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    static func save(_ palette: WidgetPaletteData) {
        guard let data = try? JSONEncoder().encode(palette) else { return }
        defaults?.set(data, forKey: key)
    }

    static func load() -> WidgetPaletteData? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetPaletteData.self, from: data)
    }

    static func clear() { defaults?.removeObject(forKey: key) }

    static var isSet: Bool { defaults?.data(forKey: key) != nil }
}

// ═════════════════════════════════════════════════════════════
// MARK: - COLOUR HELPER  (both targets)
// ═════════════════════════════════════════════════════════════

extension Color {
    init(widgetHex hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "#", with: "")
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >>  8) & 0xFF) / 255,
            blue:  Double( val        & 0xFF) / 255
        )
    }
}
