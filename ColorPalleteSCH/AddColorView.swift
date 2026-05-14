//
//  AddColorView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//
import SwiftUI
import SwiftData

struct AddColorView: View {
    @Environment(\.dismiss) private var dismiss
    
    // We pass the palette so we know where to save the new color
    var palette: SavedPalette
    
    @State private var selectedColor: Color = .blue // Default start color
    @State private var colorName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ColorPicker("Pick a Color", selection: $selectedColor)
                        .padding(.vertical, 4)
                    
                    TextField("Color Name (e.g. Ocean Blue)", text: $colorName)
                } footer: {
                    Text("Choose a color and give it a name to add it to your palette.")
                }
            }
            .navigationTitle("Add New Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color("AppText"))
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveColor()
                    }
                    .tint(Color("AppText"))
                }
            }
        }
        // This makes the sheet only take up half the screen (optional, looks nice!)
        .presentationDetents([.medium])
    }

    private func saveColor() {
        // 1. Create the Hex String
        let hexString = selectedColor.toHex() ?? "#000000"
        
        // 2. Use a default name if the user didn't type one
        let finalName = colorName.isEmpty ? "Custom Color" : colorName
        
        // 3. Create the new SavedColor
        let newColor = SavedColor(name: finalName, hex: hexString)
        
        // 4. Add it to the palette
        palette.colors.append(newColor)
        
        dismiss()
    }
}
