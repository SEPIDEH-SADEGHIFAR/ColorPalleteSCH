//
//  ManualPaletteView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//

import SwiftUI
import SwiftData

struct ManualPaletteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Form Fields
    @State private var title: String = ""
    @State private var colors: [Color] = [.blue, .purple, .pink, .orange, .yellow]
    @State private var colorNames: [String] = ["Primary", "Secondary", "Accent 1", "Accent 2", "Background"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Palette Details")) {
                    TextField("Palette Name", text: $title)
                }

                Section(header: Text("Colors")) {
                    ForEach(0..<5) { index in
                        HStack {
                            ColorPicker("", selection: $colors[index])
                                .labelsHidden()
                            
                            TextField("Color Name", text: $colorNames[index])
                        }
                    }
                }
            }
            .navigationTitle("New Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePalette()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func savePalette() {
        // 1. Convert SwiftUI Colors to SavedColors
        var savedColors: [SavedColor] = []
        
        for index in 0..<5 {
            let hexString = colors[index].toHex() ?? "#000000"
            let name = colorNames[index].isEmpty ? "Color \(index + 1)" : colorNames[index]
            savedColors.append(SavedColor(name: name, hex: hexString))
        }

        // 2. Create the Palette
        let newPalette = SavedPalette(title: title, colors: savedColors)

        // 3. Save to SwiftData
        modelContext.insert(newPalette)
        dismiss()
    }
}
