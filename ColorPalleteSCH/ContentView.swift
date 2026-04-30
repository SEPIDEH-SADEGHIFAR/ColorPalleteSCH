import SwiftUI
import SwiftData
import FoundationModels

struct ContentView: View { // This is your Generator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedColor: Color = .blue
    @State private var palette: ColorPalette? = nil
    @State private var isGenerating = false
    @State private var errorMessage: String? = nil
    
    // Define the AI Session here
    let session = LanguageModelSession(instructions: "You are a color theory expert.")

    var body: some View {
        VStack(spacing: 24) {
            ColorPicker("Base Color", selection: $selectedColor)
            
            Button(action: generatePalette) {
                Text(isGenerating ? "Generating..." : "Generate Palette")
            }
            .disabled(isGenerating)
            
            if let palette {
                // This will now work because we created PaletteView.swift
                PaletteView(palette: palette)
                
                Button("Save Palette") {
                    savePalette()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    func generatePalette() {
        isGenerating = true
        // This will now work because we created Helpers.swift
        let hex = selectedColor.toHex() ?? "#000000"
        
        Task {
            do {
                let prompt = "Generate 5 colors based on \(hex)"
                let response = try await session.respond(to: prompt, generating: ColorPalette.self)
                palette = response.content
            } catch {
                print(error)
            }
            isGenerating = false
        }
    }
    
    func savePalette() {
        guard let p = palette else { return }
        
        let savedColors = p.colors.map { SavedColor(name: $0.name, hex: $0.hex) }
        let newPalette = SavedPalette(title: p.title, colors: savedColors)
        
        modelContext.insert(newPalette)
        dismiss()
    }
}
