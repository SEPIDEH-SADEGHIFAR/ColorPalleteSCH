//
//  WidgetPickerView.swift
//  Awby
//
//  Created by seyedeh sepideh sadeghi far on 15/05/26.
//

import SwiftUI
import WidgetKit

struct WidgetPickerView: View {
    // 1. Define some awesome built-in themes
    let availablePalettes: [WidgetPalette] = [
        WidgetPalette.placeholder, // The 'Twilight Studio' default
        
        WidgetPalette(
            title: "Cyber Neon",
            colors: [
                .init(name: "Void", hex: "#0B0C10"),
                .init(name: "Laser", hex: "#66FCF1"),
                .init(name: "Teal", hex: "#45A29E"),
                .init(name: "Ash", hex: "#C5C6C7"),
                .init(name: "Slate", hex: "#1F2833")
            ]
        ),
        
        WidgetPalette(
            title: "Matcha Latte",
            colors: [
                .init(name: "Cream", hex: "#FDFFFC"),
                .init(name: "Foam", hex: "#E9F5DB"),
                .init(name: "Matcha", hex: "#CFE1B9"),
                .init(name: "Leaf", hex: "#B5C99A"),
                .init(name: "Wood", hex: "#97A97C")
            ]
        )
    ]
    
    // Track what is currently selected
    @State private var selectedPaletteTitle: String = WidgetDataManager.load()?.title ?? "Twilight Studio"
    
    var body: some View {
        NavigationView {
            List(availablePalettes, id: \.title) { palette in
                Button(action: {
                    saveAndRefreshWidget(palette: palette)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(palette.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Mini preview of the colors
                            HStack(spacing: 6) {
                                ForEach(palette.colors, id: \.hex) { color in
                                    Circle()
                                        .fill(Color(appHex: color.hex))
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Show a checkmark if it's the active palette
                        if selectedPaletteTitle == palette.title {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#6C63FF")) // AWBY Purple
                                .font(.title2)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray.opacity(0.3))
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain) // Keeps the whole row clickable without default blue flashes
            }
            .navigationTitle("Widget Themes")
        }
        .onAppear {
            // Ensure the checkmark is accurate when the view loads
            selectedPaletteTitle = WidgetDataManager.load()?.title ?? "Twilight Studio"
        }
    }
    
    // 2. The magic function that updates the widget
    private func saveAndRefreshWidget(palette: WidgetPalette) {
        print("🚨 THEME PICKER TAPPED: \(palette.title)")
        
        // Update the UI checkmark smoothly
        withAnimation(.spring(response: 0.3)) {
            selectedPaletteTitle = palette.title
        }
        
        // Save it using your shared manager
        WidgetDataManager.save(palette)
        
        // Tell iOS to immediately update the widgets on the Home Screen
        WidgetCenter.shared.reloadAllTimelines()
        
        // Give the user physical feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Diagnostic Print
        if let saved = WidgetDataManager.load() {
            print("✅ SUCCESS! Saved theme to App Group: \(saved.title)")
        } else {
            print("❌ FAILED! App Group is broken.")
        }
    }
}

// MARK: - Local Hex Helper
// Made fileprivate so it doesn't conflict with extensions in your other files!
fileprivate extension Color {
    init(appHex hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double( v        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
