//
//  SingleColorStickerView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 05/05/26.
//

import SwiftUI
import SwiftData

enum SingleColorExportStyle: String, CaseIterable, Identifiable {
    case swatch   = "Swatch"
    case pantone  = "Pantone"
    case arch     = "Arch"
    case butter   = "Square"
    case brutal   = "Brutal"
    case dataCard = "Data Card"
    case cloud    = "Cloud"
    case neon     = "Neon Sign"
    case passport = "Passport"
    case cassette = "Cassette"
    case ink      = "Ink Stamp"
    case gradient = "Gradient"
    var id: String { rawValue }
}

struct ExportColorPreviewView: View {
    let color: SavedColor
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: SingleColorExportStyle = .pantone
    @State private var renderedImage: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F2EE").ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SingleColorExportStyle.allCases) { style in
                                Button {
                                    withAnimation(.spring(response: 0.3)) { selectedStyle = style }
                                } label: {
                                    Text(style.rawValue)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(selectedStyle == style ? Color(hex: "#F5F2EE") : Color(hex: "#1A1A1A").opacity(0.5))
                                        .padding(.horizontal, 16).padding(.vertical, 9)
                                        .background(Capsule().fill(selectedStyle == style ? Color(hex: "#1A1A1A") : Color(hex: "#1A1A1A").opacity(0.07)))
                                }
                            }
                        }
                        .padding(.horizontal, 22).padding(.vertical, 16)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 24).fill(Color(hex: "#1A1A1A").opacity(0.06))
                        SingleColorStickerView(color: color, style: selectedStyle)
                            .scaleEffect(0.76)
                            .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
                    }
                    .padding(.horizontal, 22).frame(height: 340)

                    Spacer()

                    if let renderedImage {
                        ShareLink(item: renderedImage, preview: SharePreview(color.name, image: renderedImage)) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold))
                                Text("Share Sticker").font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 58)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: "#1A1A1A")))
                        }
                        .padding(.horizontal, 22).padding(.bottom, 28)
                    } else {
                        ProgressView().tint(Color(hex: "#1A1A1A")).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Export Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color(hex: "#1A1A1A"))
                }
            }
            .toolbarBackground(Color(hex: "#F5F2EE"), for: .navigationBar)
            .onAppear { renderColorSticker() }
            .onChange(of: selectedStyle) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { renderColorSticker() }
            }
        }
        .presentationDetents([.fraction(0.88)])
    }

    @MainActor
    private func renderColorSticker() {
        renderedImage = nil
        let renderer = ImageRenderer(content: SingleColorStickerView(color: color, style: selectedStyle))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage { renderedImage = Image(uiImage: uiImage) }
    }
}

struct SingleColorStickerView: View {
    let color: SavedColor
    let style: SingleColorExportStyle
    var body: some View {
        Group {
            switch style {
            case .swatch:   ClassicSwatchSingleColorStickerView(color: color)
            case .pantone:  PantoneColorSticker(color: color)
            case .arch:     ArchColorSticker(color: color)
            case .butter:   ButterColorSticker(color: color)
            case .brutal:   BrutalColorSticker(color: color)
            case .dataCard: DataCardColorSticker(color: color)
            case .cloud:    CloudColorSticker(color: color)
            case .neon:     NeonSignColorSticker(color: color)
            case .passport: PassportColorSticker(color: color)
            case .cassette: CassetteColorSticker(color: color)
            case .ink:      InkStampColorSticker(color: color)
            case .gradient: GradientColorSticker(color: color)
            }
        }
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

// ── Color Sticker 1: Pantone ─────────────────────────────────
struct PantoneColorSticker: View {
    let color: SavedColor
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color(hex: color.hex)).frame(width: 180, height: 200)
            VStack(alignment: .leading, spacing: 5) {
                Text(color.name.uppercased())
                    .font(.system(size: 18, weight: .heavy)).foregroundStyle(Color(hex: "#1A1A1A"))
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(color.hex.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.45))
                Text("PALETTE APP")
                    .font(.system(size: 8, weight: .black)).tracking(2)
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.2)).padding(.top, 2)
            }
            .padding(14)
        }
        .frame(width: 180).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }
}

// ── Color Sticker 2: Arch ────────────────────────────────────
struct ArchColorSticker: View {
    let color: SavedColor
    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(Color(hex: color.hex)).frame(width: 200, height: 200)
                .offset(y: 100).frame(height: 100).clipped()
            Color(hex: color.hex).frame(width: 200, height: 36)
            HStack(alignment: .bottom) {
                Text(color.name.replacingOccurrences(of: " ", with: "\n").uppercased())
                    .font(.system(size: 18, weight: .heavy)).foregroundStyle(Color(hex: "#1A1A1A")).multilineTextAlignment(.leading)
                Spacer()
                Text(color.hex.uppercased())
                    .font(.system(size: 11, weight: .black, design: .monospaced)).foregroundStyle(Color(hex: "#1A1A1A")).padding(.bottom, 4)
            }
            .padding(.horizontal, 16).padding(.vertical, 12).frame(width: 200).background(Color(hex: "#F9F9F9"))
            Color(hex: color.hex).frame(width: 200, height: 24)
        }
        .frame(width: 200).clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// ── Color Sticker 3: Butter Square ───────────────────────────
struct ButterColorSticker: View {
    let color: SavedColor
    var body: some View {
        VStack {
            HStack {
                Text(color.name.replacingOccurrences(of: " ", with: "\n").lowercased())
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45)).multilineTextAlignment(.leading)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Text(color.hex.lowercased())
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
        }
        .padding(28).frame(width: 220, height: 220)
        .background(Color(hex: color.hex)).clipShape(RoundedRectangle(cornerRadius: 44))
    }
}

// ── Color Sticker 4: Brutal ──────────────────────────────────
struct BrutalColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color(hex: color.hex)
            VStack(alignment: .leading, spacing: 4) {
                Text(color.name.uppercased()).font(.system(size: 22, weight: .black)).foregroundStyle(Color.black)
                Text(color.hex.uppercased())
                    .font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(Color.black.opacity(0.55))
            }
            .padding(16)
        }
        .frame(width: 300, height: 150)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
    }
}

// ── Color Sticker 5: Data Card ────────────────────────────────
struct DataCardColorSticker: View {
    let color: SavedColor
    struct DataRow: View {
        let label: String; let value: String
        var body: some View {
            HStack {
                Text(label).font(.system(size: 9, weight: .black)).tracking(1.5)
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35)).frame(width: 48, alignment: .leading)
                Text(value).font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#1A1A1A")).lineLimit(1).minimumScaleFactor(0.7)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }
    var body: some View {
        let d = color.detailedData()
        VStack(alignment: .leading, spacing: 0) {
            Color(hex: color.hex).frame(height: 100)
            VStack(alignment: .leading, spacing: 0) {
                DataRow(label: "NAME", value: color.name.uppercased())
                Divider()
                DataRow(label: "HEX",  value: color.hex.uppercased())
                Divider()
                DataRow(label: "RGB",  value: "\(d.r) · \(d.g) · \(d.b)")
                Divider()
                DataRow(label: "CMYK", value: "\(d.c) · \(d.m) · \(d.y) · \(d.k)")
            }
            .padding(.vertical, 4)
        }
        .frame(width: 280).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#1A1A1A").opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
    }
}

// ── Color Sticker 6: Cloud ───────────────────────────────────
struct CloudColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack {
            ForEach([-62, 0, 62], id: \.self) { x in
                ForEach([-62, 0, 62], id: \.self) { y in
                    Circle().fill(Color(hex: color.hex)).frame(width: 92, height: 92)
                        .offset(x: CGFloat(x), y: CGFloat(y))
                }
            }
            VStack(spacing: 3) {
                Text(color.name).font(.system(size: 26, weight: .bold, design: .serif)).foregroundStyle(.white)
                Text(color.hex.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 250, height: 250)
    }
}

// ── Color Sticker 7: Neon Sign ───────────────────────────────
struct NeonSignColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F")
            VStack(spacing: 10) {
                Text(color.name.uppercased())
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: color.hex))
                    .shadow(color: Color(hex: color.hex).opacity(0.9), radius: 12)
                    .shadow(color: Color(hex: color.hex).opacity(0.5), radius: 24)
                Rectangle().fill(Color(hex: color.hex).opacity(0.55)).frame(height: 1.5)
                    .shadow(color: Color(hex: color.hex), radius: 6).padding(.horizontal, 20)
                Text(color.hex.uppercased())
                    .font(.system(size: 17, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: color.hex).opacity(0.8))
                    .shadow(color: Color(hex: color.hex).opacity(0.7), radius: 8)
            }
            .padding(.horizontal, 28).padding(.vertical, 30)
        }
        .frame(width: 280, height: 155).clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: color.hex).opacity(0.22), lineWidth: 1.5))
    }
}

// ── Color Sticker 8: Passport ────────────────────────────────
struct PassportColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: color.hex), lineWidth: 8).frame(width: 220, height: 220)
            Circle().stroke(Color(hex: color.hex).opacity(0.28), lineWidth: 2).frame(width: 196, height: 196)
            Circle().fill(Color(hex: color.hex).opacity(0.07)).frame(width: 196, height: 196)
            VStack(spacing: 6) {
                Text("COLOR").font(.system(size: 9, weight: .black)).tracking(4).foregroundStyle(Color(hex: color.hex))
                Text(color.hex.uppercased())
                    .font(.system(size: 20, weight: .black, design: .monospaced)).foregroundStyle(Color(hex: color.hex))
                Rectangle().fill(Color(hex: color.hex).opacity(0.35)).frame(width: 60, height: 1.5)
                Text(color.name.uppercased())
                    .font(.system(size: 10, weight: .bold)).tracking(1.5)
                    .foregroundStyle(Color(hex: color.hex).opacity(0.65)).multilineTextAlignment(.center)
            }
            Text("✦ PALETTE STUDIO ✦")
                .font(.system(size: 8, weight: .black)).tracking(2)
                .foregroundStyle(Color(hex: color.hex).opacity(0.5)).offset(y: -78)
        }
        .frame(width: 240, height: 240)
    }
}

// ── Color Sticker 9: Cassette ────────────────────────────────
struct CassetteColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Color(hex: color.hex)).frame(width: 300, height: 180)
            RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.92)).frame(width: 200, height: 100)
            HStack(spacing: 68) {
                Circle().fill(Color(hex: color.hex)).frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                Circle().fill(Color(hex: color.hex)).frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
            }
            .offset(y: 30)
            VStack(spacing: 3) {
                Text(color.name.uppercased())
                    .font(.system(size: 13, weight: .black)).foregroundStyle(Color(hex: color.hex))
                    .lineLimit(1).minimumScaleFactor(0.7).frame(width: 158)
                Rectangle().fill(Color(hex: color.hex).opacity(0.28)).frame(height: 1).frame(width: 130)
                Text(color.hex.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: color.hex).opacity(0.65))
            }
            .offset(y: -12)
            HStack {
                RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.18)).frame(width: 18, height: 10)
                Spacer()
                RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.18)).frame(width: 18, height: 10)
            }
            .frame(width: 278).offset(y: -82)
        }
        .frame(width: 300, height: 180)
    }
}

// ── Color Sticker 10: Ink Stamp ──────────────────────────────
struct InkStampColorSticker: View {
    let color: SavedColor
    var body: some View {
        ZStack {
            Color.white
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8, 5]))
                .foregroundStyle(Color(hex: color.hex)).frame(width: 240, height: 240)
            RoundedRectangle(cornerRadius: 10).stroke(Color(hex: color.hex), lineWidth: 2).frame(width: 200, height: 200)
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: color.hex).opacity(0.1)).frame(width: 196, height: 196)
            VStack(spacing: 8) {
                Text(color.name.uppercased())
                    .font(.system(size: 20, weight: .black)).tracking(1)
                    .foregroundStyle(Color(hex: color.hex)).multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.6).frame(width: 155)
                Circle().fill(Color(hex: color.hex)).frame(width: 38, height: 38)
                    .overlay(
                        Text(String(color.name.prefix(1))).font(.system(size: 17, weight: .black)).foregroundStyle(.white)
                    )
                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: color.hex).opacity(0.65))
            }
        }
        .frame(width: 260, height: 260).clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// ── Color Sticker 11: Gradient ───────────────────────────────
struct GradientColorSticker: View {
    let color: SavedColor
    private var lighter: Color {
        let d = color.detailedData()
        return Color(red: Double(min(255, d.r+60))/255, green: Double(min(255, d.g+60))/255, blue: Double(min(255, d.b+60))/255)
    }
    private var darker: Color {
        let d = color.detailedData()
        return Color(red: Double(max(0, d.r-60))/255, green: Double(max(0, d.g-60))/255, blue: Double(max(0, d.b-60))/255)
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [lighter, Color(hex: color.hex), darker], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 8) {
                Text(color.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 8).multilineTextAlignment(.center)
                Text(color.hex.uppercased())
                    .font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.75))
                    .shadow(color: .black.opacity(0.2), radius: 4)
            }
            .padding(28)
        }
        .frame(width: 250, height: 250).clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.2), lineWidth: 1.5))
    }
}
