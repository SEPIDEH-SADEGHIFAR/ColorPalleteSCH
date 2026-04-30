//
//  SavedPaletteDetailView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far
//

import SwiftUI
import SwiftData

struct SavedPaletteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var palette: SavedPalette
    
    // State to control the sheets
    @State private var isAddingColor = false
    @State private var colorToExport: SavedColor? // For single color export
    @State private var showPaletteExport = false    // For full palette export

    var body: some View {
        List {
            Section(header: Text("Colors")) {
                ForEach(palette.colors) { color in
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: color.hex))
                            .frame(width: 50, height: 50)
                            .shadow(radius: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5) // Thinner border
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(color.name).font(.headline)
                            Text(color.hex).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle()) // Makes the whole row tappable
                    .onTapGesture {
                        colorToExport = color // Open single color sticker sheet
                    }
                }
                .onDelete(perform: deleteColor)
            }
        }
        .navigationTitle(palette.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showPaletteExport = true }) {
                    Label("Export Palette", systemImage: "square.and.arrow.up.on.square")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { isAddingColor = true }) {
                    Label("Add Color", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingColor) {
            AddColorView(palette: palette)
        }
        .sheet(item: $colorToExport) { color in
            ExportColorPreviewView(color: color)
        }
        .sheet(isPresented: $showPaletteExport) {
            ExportPalettePreviewView(palette: palette)
        }
    }

    private func deleteColor(at offsets: IndexSet) {
        for index in offsets {
            let colorToDelete = palette.colors[index]
            modelContext.delete(colorToDelete)
        }
    }
}

// MARK: - Export Styles Enum (Full Palette)

enum PaletteExportStyle: String, CaseIterable, Identifiable {
    case stripes = "Stripes"
    case retro = "Retro Grid"
    case pill = "Pill List"
    
    var id: String { self.rawValue }
}

// MARK: - Full Palette Export Views

struct ExportPalettePreviewView: View {
    let palette: SavedPalette
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedStyle: PaletteExportStyle = .stripes
    @State private var renderedImage: Image?
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Export Style", selection: $selectedStyle) {
                    ForEach(PaletteExportStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Spacer()
                
                ZStack {
                    Color.gray.opacity(0.1).cornerRadius(16)
                    
                    PaletteStickerView(palette: palette, style: selectedStyle)
                        .scaleEffect(0.8) // Scale down for preview only
                }
                .padding()
                
                Spacer()
                
                if let renderedImage {
                    ShareLink(item: renderedImage, preview: SharePreview("\(palette.title) Palette", image: renderedImage)) {
                        Label("Share / Export Palette", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    ProgressView("Preparing sticker...")
                }
            }
            .navigationTitle("Export Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                renderSticker()
            }
            .onChange(of: selectedStyle) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    renderSticker()
                }
            }
        }
        .presentationDetents([.fraction(0.85)])
    }
    
    @MainActor
    private func renderSticker() {
        let viewToRender = PaletteStickerView(palette: palette, style: selectedStyle)
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

// Router to pick the correct design
struct PaletteStickerView: View {
    let palette: SavedPalette
    let style: PaletteExportStyle
    
    var body: some View {
        Group {
            switch style {
            case .stripes:
                StripesStyleView(palette: palette)
            case .retro:
                RetroGridStyleView(palette: palette)
            case .pill:
                PillStyleView(palette: palette)
            }
        }
        .environment(\.colorScheme, .light)
    }
}

// STYLE 1: Vertical Stripes
struct StripesStyleView: View {
    let palette: SavedPalette
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(palette.colors.prefix(5)) { color in
                ZStack(alignment: .bottom) {
                    Color(hex: color.hex)
                    
                    Text(color.hex.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .blendMode(.difference)
                        .fixedSize()
                        .frame(width: 20)
                        .rotationEffect(.degrees(-90))
                        .padding(.bottom, 60)
                }
            }
        }
        .frame(width: 300, height: 400)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// STYLE 2: Retro Grid
struct RetroGridStyleView: View {
    let palette: SavedPalette
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        VStack(spacing: 24) {
            Text(palette.title)
                .font(.system(size: 38, weight: .heavy, design: .serif))
                .foregroundColor(Color(hex: "#1A365D"))
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(palette.colors.prefix(6)) { color in
                    VStack(spacing: 0) {
                        Color(hex: color.hex)
                            .aspectRatio(1, contentMode: .fit)
                        
                        HStack {
                            Text(color.hex.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.vertical, 10)
                                .padding(.leading, 8)
                            Spacer()
                        }
                        .background(Color.white)
                    }
                    .background(Color.white)
                }
            }
        }
        .padding(32)
        .frame(width: 350)
        .background(Color(hex: "#F4EBE1"))
    }
}

// STYLE 3: Floating Vertical Pill
struct PillStyleView: View {
    let palette: SavedPalette
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(palette.colors.prefix(5)) { color in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: color.hex))
                        .frame(width: 80, height: 80)
                    
                    Text(color.hex.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .blendMode(.difference)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}


// MARK: - Single Color Export Styles Enum

enum SingleColorExportStyle: String, CaseIterable, Identifiable {
    case classicSwatch = "Classic Swatch" // NEW Case for the request design
    case arch = "Blue Daisies (Arch)"
    case butter = "Butter Milk (Square)"
    case bordered = "Sharp Border"
    case crimson = "Crimson (Banner)"
    case popping = "Scalloped Cloud"
    
    var id: String { self.rawValue }
}

// MARK: - Updated Single-Color Export Views

struct ExportColorPreviewView: View {
    let color: SavedColor
    @Environment(\.dismiss) private var dismiss
    
    // Style State
    @State private var selectedStyle: SingleColorExportStyle = .classicSwatch // Default to Classic
    @State private var renderedImage: Image?
    
    var body: some View {
        NavigationStack {
            VStack {
                // FIXED: Custom Scrollable Button List instead of the squished Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SingleColorExportStyle.allCases) { style in
                            Button(action: {
                                selectedStyle = style
                            }) {
                                Text(style.rawValue)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    // Highlight the selected button in blue
                                    .background(selectedStyle == style ? Color.blue : Color.gray.opacity(0.15))
                                    .foregroundColor(selectedStyle == style ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
                
                Spacer()
                
                // The live preview of the selected style
                ZStack {
                    Color.gray.opacity(0.1).cornerRadius(16) // Background canvas for preview
                    
                    // Route to the specific view based on style
                    SingleColorStickerView(color: color, style: selectedStyle)
                        // Scale it down slightly just for the preview to fit
                        .scaleEffect(0.8)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                }
                .padding()
                
                Spacer()
                
                // Share Button
                if let renderedImage {
                    ShareLink(item: renderedImage, preview: SharePreview("\(color.name) Sticker", image: renderedImage)) {
                        Label("Share / Export Sticker", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    ProgressView("Preparing sticker...")
                }
            }
            .navigationTitle("Export Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                renderSticker()
            }
            // Re-render when the style changes
            .onChange(of: selectedStyle) { _ in
                // Tiny delay ensures the UI updates the view before snapshotting
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    renderSticker()
                }
            }
        }
        // Give it more vertical space to comparison controls
        .presentationDetents([.fraction(0.85)])
    }
    
    @MainActor
    private func renderSticker() {
        // We render the view at full scale for the actual export
        let viewToRender = SingleColorStickerView(color: color, style: selectedStyle)
        let renderer = ImageRenderer(content: viewToRender)
        
        // High resolution export
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            renderedImage = Image(uiImage: uiImage)
        }
    }
}

// Router to the individual design views
struct SingleColorStickerView: View {
    let color: SavedColor
    let style: SingleColorExportStyle
    
    var body: some View {
        Group {
            switch style {
            case .classicSwatch:
                ClassicSwatchSingleColorStickerView(color: color) // NEW Case routing
            case .arch:
                ArchSingleColorStickerView(color: color)
            case .butter:
                ButterMilkSingleColorStickerView(color: color)
            case .bordered:
                BorderedSingleColorStickerView(color: color)
            case .crimson:
                CrimsonBannerSingleColorStickerView(color: color)
            case .popping:
                ScallopedSingleColorStickerView(color: color)
            }
        }
        // Force light mode so white backgrounds don't turn black in Dark Mode
        .environment(\.colorScheme, .light)
    }
}
// DESIGN 1: Classic Swatch (Perfectly Minimal Pantone Style)
struct ClassicSwatchSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // The Color Square
            Rectangle()
                .fill(Color(hex: color.hex))
                .frame(width: 200, height: 200) // Classic swatch proportions
            
            // The Text Area (in the white space below)
            VStack(alignment: .leading, spacing: 4) {
                Text(color.name.uppercased())
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5) // Shrinks the text safely if the name is super long
                
                Text(color.hex.uppercased())
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 4)
        }
        .padding(16) // The thick white border around the whole card
        .background(Color.white) // Sticker card background
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Very slight, clean rounding
        .environment(\.colorScheme, .light) // Force light design so the card stays white
    }
}
// DESIGN 2: Blue Daisies (Perfect Arch)
struct ArchSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Dome (Circle cut exactly in half)
            Circle()
                .fill(Color(hex: color.hex))
                .frame(width: 200, height: 200)
                .offset(y: 100) // Push down
                .frame(height: 100) // Clip the bottom half
                .clipped()
            
            // Middle Body
            Color(hex: color.hex)
                .frame(width: 200, height: 40)
            
            // White Text Band
            HStack(alignment: .bottom) {
                // Splitting name to stack it if multiple words
                Text(color.name.replacingOccurrences(of: " ", with: "\n").uppercased())
                    .font(.custom("Marker Felt", size: 22)) // Whimsical marker font
                    .fontWeight(.heavy)
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(-4)
                
                Spacer()
                
                Text(color.hex.uppercased())
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(width: 200)
            .background(Color(hex: "#F9F9F9")) // Off-white band
            
            // Bottom Lip
            Color(hex: color.hex)
                .frame(width: 200, height: 30)
        }
        .frame(width: 200)
    }
}

// DESIGN 3: Butter Milk (Rounded Square)
struct ButterMilkSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        VStack {
            HStack {
                // Stack words vertically, lowercase
                Text(color.name.replacingOccurrences(of: " ", with: "\n").lowercased())
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.5)) // Darken the text dynamically
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Text(color.hex.lowercased())
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(Color.black.opacity(0.5))
            }
        }
        .padding(32)
        .frame(width: 240, height: 240)
        .background(Color(hex: color.hex))
        .clipShape(RoundedRectangle(cornerRadius: 48)) // Extreme corner radius
    }
}

// DESIGN 4: F6DAOE (Sharp Border Rectangle)
struct BorderedSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(hex: color.hex)
            
            Text(color.hex.uppercased())
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.black)
                .padding(16)
        }
        .frame(width: 320, height: 160)
        .border(Color.black, width: 3) // Sharp, thick black border
    }
}

// DESIGN 5: Crimson (Detailed Info Banner)
struct CrimsonBannerSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        let rgbCMYK = color.detailedData()
        
        VStack(alignment: .leading, spacing: 8) {
            Text(color.name.uppercased())
                .font(.system(size: 36, weight: .bold, design: .default))
                .foregroundColor(Color(hex: "#FFD700")) // Classic Yellow Title
                .padding(.bottom, 12)
            
            InfoRow(label: "HEX", value: color.hex.uppercased())
            InfoRow(label: "RGB", value: "\(rgbCMYK.r), \(rgbCMYK.g), \(rgbCMYK.b)")
            InfoRow(label: "CMYK", value: "\(rgbCMYK.c), \(rgbCMYK.m), \(rgbCMYK.y), \(rgbCMYK.k)")
        }
        .padding(32)
        .frame(width: 380, alignment: .leading)
        .background(Color(hex: color.hex))
    }
    
    // Sub-view for the Yellow Label + White Value layout
    struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#FFD700")) // Yellow Label
                Text(value)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white) // White Value
            }
        }
    }
}

// DESIGN 6: Popping Pink (Scalloped Cloud)
struct ScallopedSingleColorStickerView: View {
    let color: SavedColor
    
    var body: some View {
        ZStack {
            // Create the scalloped effect by perfectly overlapping a 3x3 grid of circles
            ForEach([-70, 0, 70], id: \.self) { x in
                ForEach([-70, 0, 70], id: \.self) { y in
                    Circle()
                        .fill(Color(hex: color.hex))
                        .frame(width: 100, height: 100)
                        .offset(x: CGFloat(x), y: CGFloat(y))
                }
            }
            
            // Center Text
            VStack(spacing: 0) {
                Text(color.name)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Text(color.hex.uppercased())
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 260, height: 260)
    }
}

// MARK: - Data Conversion Helper

extension SavedColor {
    // Calculates simple RGB and CMYK values for the data sticker
    func detailedData() -> (r: Int, g: Int, b: Int, c: Int, m: Int, y: Int, k: Int) {
        let cleanedHex = self.hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&value)
        
        let r = Int((value >> 16) & 0xFF)
        let g = Int((value >> 8) & 0xFF)
        let b = Int(value & 0xFF)
        
        let rf = CGFloat(r) / 255.0
        let gf = CGFloat(g) / 255.0
        let bf = CGFloat(b) / 255.0
        
        let c_ = 1.0 - rf
        let m_ = 1.0 - gf
        let y_ = 1.0 - bf
        let k_ = min(min(c_, m_), y_)
        
        if k_ == 1.0 {
            return (r, g, b, 0, 0, 0, 100)
        }
        
        let c = Int((c_ - k_) / (1.0 - k_) * 100.0)
        let m = Int((m_ - k_) / (1.0 - k_) * 100.0)
        let y = Int((y_ - k_) / (1.0 - k_) * 100.0)
        let k = Int(k_ * 100.0)
        
        return (r, g, b, c, m, y, k)
    }
}
