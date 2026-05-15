//
//  Widgetsharedmodels.swift
//  Awby
//
//  Created by seyedeh sepideh sadeghi far on 15/05/26.
//

import Foundation
import WidgetKit

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET SHARED MODELS
// ─────────────────────────────────────────────────────────────
// ⚠️ Add this file to TWO targets in Xcode:
//   • Your main app target  (AWBY)
//   • Your widget extension (AWBYWidgetExtension)
//
// In Xcode File Inspector (right panel) → Target Membership
// tick both checkboxes.
// ═════════════════════════════════════════════════════════════

// MARK: - App Group Identifier
// Replace with YOUR App Group ID (must match in both targets'
// Signing & Capabilities → App Groups)

let AWBYAppGroupID = "group.com.SeyedehSepidehSadeghiFar.awby"
let AWBYWidgetPaletteKey = "awby.widget.selectedPalette"


// MARK: - Codable Palette Model (shared between app and widget)

public struct WidgetPalette: Codable, Equatable {
    public var title: String
    public var colors: [WidgetColor]

    public struct WidgetColor: Codable, Equatable {
        public var name: String
        public var hex: String
    }

    // Placeholder shown in widget gallery before user picks a palette
    public static let placeholder = WidgetPalette(
        title: "Twilight Studio",
        colors: [
            .init(name: "Void",     hex: "#0D0A1A"),
            .init(name: "Iris",     hex: "#6C63FF"),
            .init(name: "Coral",    hex: "#FF6B6B"),
            .init(name: "Linen",    hex: "#F5F2EE"),
            .init(name: "Slate",    hex: "#4A3580"),
        ]
    )
}


// MARK: - Data Manager (read / write via shared UserDefaults)

public enum WidgetDataManager {

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AWBYAppGroupID)
    }

    /// Save a palette so the widget can read it.
    /// Call WidgetCenter.shared.reloadAllTimelines() after this.
    public static func save(_ palette: WidgetPalette) {
        guard let data = try? JSONEncoder().encode(palette) else { return }
        defaults?.set(data, forKey: AWBYWidgetPaletteKey)
    }

    /// Load the most recently saved widget palette.
    /// Returns nil if the user hasn't set one yet.
    public static func load() -> WidgetPalette? {
        guard
            let data = defaults?.data(forKey: AWBYWidgetPaletteKey),
            let palette = try? JSONDecoder().decode(WidgetPalette.self, from: data)
        else { return nil }
        return palette
    }

    /// Remove the saved widget palette.
    public static func clear() {
        defaults?.removeObject(forKey: AWBYWidgetPaletteKey)
    }
}
