//
//  PaletteStickerView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 05/05/26.
//

import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - PALETTE EXPORT
// ═════════════════════════════════════════════════════════════

enum PaletteExportStyle: String, CaseIterable, Identifiable {
    case modernStripes = "Stripes"
    case editorial     = "Editorial"
    case retroGrid     = "Retro Grid"
    case darkCard      = "Dark Card"
    case filmStrip     = "Film Strip"
    case pill          = "Pill List"
    var id: String { rawValue }
}

struct ExportPalettePreviewView: View {
    let palette: SavedPalette
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: PaletteExportStyle = .modernStripes
    @State private var renderedImage: Image?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F5F2EE").ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PaletteExportStyle.allCases) { style in
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
                        PaletteStickerView(palette: palette, style: selectedStyle)
                            .scaleEffect(previewScale)
                            .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
                    }
                    .padding(.horizontal, 22).frame(height: 360)

                    Spacer()

                    if let renderedImage {
                        ShareLink(item: renderedImage, preview: SharePreview(palette.title, image: renderedImage)) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold))
                                Text("Share Palette").font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 58)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: "#1A1A1A")))
                        }
                        .padding(.horizontal, 22).padding(.bottom, 28)
                    } else {
                        ProgressView().tint(Color(hex: "#1A1A1A")).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Export Palette")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color(hex: "#1A1A1A"))
                }
            }
            .toolbarBackground(Color(hex: "#F5F2EE"), for: .navigationBar)
            .onAppear { renderPaletteSticker() }
            .onChange(of: selectedStyle) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { renderPaletteSticker() }
            }
        }
        .presentationDetents([.fraction(0.88)])
    }

    private var previewScale: CGFloat {
        switch selectedStyle {
        case .editorial: return 0.70
        case .filmStrip: return 0.62
        default: return 0.76
        }
    }

    @MainActor
    private func renderPaletteSticker() {
        renderedImage = nil
        let renderer = ImageRenderer(content: PaletteStickerView(palette: palette, style: selectedStyle))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage { renderedImage = Image(uiImage: uiImage) }
    }
}

struct PaletteStickerView: View {
    let palette: SavedPalette
    let style: PaletteExportStyle
    var body: some View {
        Group {
            switch style {
            case .modernStripes: PaletteStripesStickerView(palette: palette)
            case .editorial:     PaletteEditorialStickerView(palette: palette)
            case .retroGrid:     PaletteRetroGridStickerView(palette: palette)
            case .darkCard:      PaletteDarkCardStickerView(palette: palette)
            case .filmStrip:     PaletteFilmStripStickerView(palette: palette)
            case .pill:          PalettePillStickerView(palette: palette)
            }
        }
        .environment(\.colorScheme, .light)
    }
}

// ── Palette Sticker 1: Modern Stripes ────────────────────────
struct PaletteStripesStickerView: View {
    let palette: SavedPalette
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(5)) { color in
                    ZStack(alignment: .bottom) {
                        Color(hex: color.hex)
                        Text(color.hex.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white).blendMode(.difference)
                            .fixedSize().rotationEffect(.degrees(-90))
                            .frame(width: 12).padding(.bottom, 50)
                    }
                }
            }
            .frame(height: 320)
            HStack {
                Text(palette.title.uppercased())
                    .font(.system(size: 15, weight: .black)).foregroundStyle(Color(hex: "#1A1A1A")).kerning(1).lineLimit(1)
                Spacer()
                Text("\(palette.colors.count) COLORS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: "#1A1A1A").opacity(0.4))
            }
            .padding(.horizontal, 20).padding(.vertical, 18).background(Color.white)
        }
        .frame(width: 300).clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 24, y: 8)
    }
}

// ── Palette Sticker 2: Editorial ─────────────────────────────
struct PaletteEditorialStickerView: View {
    let palette: SavedPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(palette.title.uppercased())
                .font(.system(size: 48, weight: .black)).foregroundStyle(Color(hex: "#1A1A1A"))
                .kerning(-1).lineLimit(2).minimumScaleFactor(0.6)
                .padding(.horizontal, 24).padding(.top, 28).padding(.bottom, 20)
            HStack(spacing: 0) { ForEach(palette.colors.prefix(6)) { Color(hex: $0.hex) } }.frame(height: 80)
            VStack(spacing: 0) {
                ForEach(palette.colors.prefix(4)) { color in
                    HStack(spacing: 14) {
                        Circle().fill(Color(hex: color.hex)).frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color(hex: "#1A1A1A").opacity(0.08), lineWidth: 1))
                        Text(color.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "#1A1A1A"))
                        Spacer()
                        Text(color.hex.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: "#1A1A1A").opacity(0.4))
                    }
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    if color.id != palette.colors.prefix(4).last?.id { Divider().padding(.leading, 58) }
                }
            }
            .padding(.vertical, 8)
            HStack {
                Text("PALETTE").font(.system(size: 9, weight: .black)).tracking(3).foregroundStyle(Color(hex: "#1A1A1A").opacity(0.22))
                Spacer()
                Text(Date().formatted(.dateTime.month().year()))
                    .font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color(hex: "#1A1A1A").opacity(0.22))
            }
            .padding(.horizontal, 24).padding(.bottom, 20).padding(.top, 4)
        }
        .frame(width: 360).background(Color(hex: "#F5F2EE")).clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "#1A1A1A").opacity(0.08), lineWidth: 1))
    }
}

// ── Palette Sticker 3: Retro Grid ────────────────────────────
struct PaletteRetroGridStickerView: View {
    let palette: SavedPalette
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(spacing: 20) {
            Text(palette.title)
                .font(.system(size: 30, weight: .heavy, design: .serif))
                .foregroundStyle(Color(hex: "#1A365D")).multilineTextAlignment(.center)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(palette.colors.prefix(6)) { color in
                    VStack(spacing: 0) {
                        Color(hex: color.hex).aspectRatio(1, contentMode: .fit)
                        HStack {
                            Text(color.hex.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.vertical, 8).padding(.leading, 7)
                            Spacer()
                        }.background(Color.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                }
            }
        }
        .padding(28).frame(width: 340).background(Color(hex: "#F4EBE1")).clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// ── Palette Sticker 4: Dark Card ─────────────────────────────
struct PaletteDarkCardStickerView: View {
    let palette: SavedPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                ForEach(palette.colors.prefix(5)) { color in
                    RoundedRectangle(cornerRadius: 6).fill(Color(hex: color.hex))
                }
            }
            .frame(height: 44).padding(.horizontal, 22).padding(.top, 22)
            Text(palette.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white).kerning(-0.5)
                .padding(.horizontal, 22).padding(.top, 18)
            Text("\(palette.colors.count) harmonious colors")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.4))
                .padding(.horizontal, 22).padding(.top, 4)
            HStack(spacing: 6) {
                ForEach(palette.colors.prefix(5)) { color in
                    Text(color.hex.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal, 22).padding(.top, 14).padding(.bottom, 22)
        }
        .frame(width: 320).background(Color(hex: "#0D0D0D")).clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// ── Palette Sticker 5: Film Strip ────────────────────────────
struct PaletteFilmStripStickerView: View {
    let palette: SavedPalette
    var body: some View {
        HStack(spacing: 0) {
            filmSprocket
            VStack(spacing: 0) {
                ForEach(palette.colors.prefix(5)) { color in
                    ZStack(alignment: .bottomLeading) {
                        Color(hex: color.hex).frame(height: 88)
                        Text(color.hex.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white).blendMode(.difference)
                            .padding(.horizontal, 8).padding(.bottom, 6)
                    }
                }
            }
            .frame(width: 200)
            filmSprocket
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottom) {
            Text(palette.title.uppercased())
                .font(.system(size: 10, weight: .black)).tracking(2).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 7)
                .background(Color(hex: "#111111").opacity(0.9))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    private var filmSprocket: some View {
        ZStack {
            Color(hex: "#111111")
            VStack(spacing: 8) {
                ForEach(0..<10, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: "#333333")).frame(width: 14, height: 10)
                }
            }
        }
        .frame(width: 28)
    }
}

// ── Palette Sticker 6: Pill List ─────────────────────────────
struct PalettePillStickerView: View {
    let palette: SavedPalette
    var body: some View {
        VStack(spacing: 0) {
            Text(palette.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1A1A1A"))
                .padding(.top, 20).padding(.bottom, 14)
            VStack(spacing: 9) {
                ForEach(palette.colors.prefix(5)) { color in
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: color.hex)).frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color(hex: "#1A1A1A").opacity(0.08), lineWidth: 1))
                        Text(color.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color(hex: "#1A1A1A"))
                        Spacer()
                        Text(color.hex.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.4))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(Capsule().fill(Color(hex: color.hex).opacity(0.12)))
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 300).background(Color.white).clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 6)
    }
}
