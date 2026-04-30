//
//  Models.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//
import SwiftData
import SwiftUI
import FoundationModels

// --- Keep your existing Generable structs for the AI ---

@Generable(description: "A single color in a palette with a name and hex code")
struct GeneratedColor: Codable { // Ensure Codable is here
    @Guide(description: "A descriptive name for the color, e.g. 'Ocean Blue'")
    var name: String

    @Guide(description: "The hex color code including the # prefix, e.g. '#3A7BD5'")
    var hex: String
}

@Generable(description: "A color palette inspired by a given base color")
struct ColorPalette: Codable {
    @Guide(description: "A short, evocative title for the palette")
    var title: String

    @Guide(description: "Five harmonious colors that complement the base color")
    var colors: [GeneratedColor]
}

// --- New SwiftData Models for Storage ---

@Model
final class SavedPalette {
    var id: UUID
    var title: String
    var timestamp: Date
    
    // A palette contains many colors. When we delete a palette, delete its colors too (.cascade).
    @Relationship(deleteRule: .cascade)
    var colors: [SavedColor]

    init(title: String, colors: [SavedColor]) {
        self.id = UUID()
        self.title = title
        self.timestamp = Date()
        self.colors = colors
    }
}

@Model
final class SavedColor {
    var name: String
    var hex: String
    
    init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }
}
