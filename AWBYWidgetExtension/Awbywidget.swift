//
//  Awbywidget.swift
//  Awby
//
//  Created by seyedeh sepideh sadeghi far on 15/05/26.
//

import WidgetKit
import SwiftUI
import AppIntents

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET STYLE
// ═════════════════════════════════════════════════════════════

enum AWBYWidgetStyle: String, AppEnum, CaseIterable {
    case stripes   = "Stripes"
    case mosaic    = "Mosaic"
    case spotlight = "Spotlight"
    case darkInk   = "Dark Ink"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Widget Style"
    static var caseDisplayRepresentations: [AWBYWidgetStyle: DisplayRepresentation] = [
        .stripes:   DisplayRepresentation(title: "Stripes",    image: .init(systemName: "rectangle.split.3x1")),
        .mosaic:    DisplayRepresentation(title: "Mosaic",     image: .init(systemName: "square.grid.2x2")),
        .spotlight: DisplayRepresentation(title: "Spotlight",  image: .init(systemName: "circle.hexagongrid.fill")),
        .darkInk:   DisplayRepresentation(title: "Dark Ink",   image: .init(systemName: "moon.fill")),
    ]
}


// ═════════════════════════════════════════════════════════════
// MARK: - CONFIGURATION INTENT
// Users configure the style directly from widget long-press
// ═════════════════════════════════════════════════════════════

struct AWBYWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "AWBY Palette Widget"
    static var description = IntentDescription("Display your favorite color palette.")

    @Parameter(title: "Widget Style", default: AWBYWidgetStyle.stripes)
    var style: AWBYWidgetStyle
}


// ═════════════════════════════════════════════════════════════
// MARK: - TIMELINE ENTRY
// ═════════════════════════════════════════════════════════════

struct AWBYEntry: TimelineEntry {
    let date: Date
    let palette: WidgetPalette
    let style: AWBYWidgetStyle
    let isPlaceholder: Bool
}


// ═════════════════════════════════════════════════════════════
// MARK: - TIMELINE PROVIDER
// ═════════════════════════════════════════════════════════════

struct AWBYProvider: AppIntentTimelineProvider {
    typealias Entry = AWBYEntry
    typealias Intent = AWBYWidgetIntent

    func placeholder(in context: Context) -> AWBYEntry {
        AWBYEntry(date: .now, palette: .placeholder, style: .stripes, isPlaceholder: true)
    }

    func snapshot(for configuration: AWBYWidgetIntent, in context: Context) async -> AWBYEntry {
        AWBYEntry(
            date: .now,
            palette: WidgetDataManager.load() ?? .placeholder,
            style: configuration.style,
            isPlaceholder: false
        )
    }

    func timeline(for configuration: AWBYWidgetIntent, in context: Context) async -> Timeline<AWBYEntry> {
        let entry = AWBYEntry(
            date: .now,
            palette: WidgetDataManager.load() ?? .placeholder,
            style: configuration.style,
            isPlaceholder: false
        )
        // Refresh once a day — palette only changes when user sets a new one
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET BUNDLE + DEFINITION
// ═════════════════════════════════════════════════════════════

//@main
struct AWBYWidgetBundle: WidgetBundle {
    var body: some Widget { AWBYWidget() }
}

struct AWBYWidget: Widget {
    let kind = "AWBYPaletteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AWBYWidgetIntent.self,
            provider: AWBYProvider()
        ) { entry in
            AWBYWidgetRootView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("AWBY Palette")
        .description("Show your favorite color palette on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()   // full bleed — we control all margins
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - ROOT VIEW ROUTER
// ═════════════════════════════════════════════════════════════

struct AWBYWidgetRootView: View {
    let entry: AWBYEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch entry.style {
        case .stripes:   StripesWidget(palette: entry.palette, family: family)
        case .mosaic:    MosaicWidget(palette: entry.palette, family: family)
        case .spotlight: SpotlightWidget(palette: entry.palette, family: family)
        case .darkInk:   DarkInkWidget(palette: entry.palette, family: family)
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 1: STRIPES
// Full-bleed vertical colour stripes.
// Name in a glassmorphic footer bar.
// ═════════════════════════════════════════════════════════════

struct StripesWidget: View {
    let palette: WidgetPalette
    let family: WidgetFamily

    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(5)) }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Full-bleed stripes ─────────────────────────────
            HStack(spacing: 0) {
                ForEach(colors, id: \.hex) { c in
                    Color(widgetHex: c.hex)
                }
            }

            // ── Frosted footer ─────────────────────────────────
            switch family {
            case .systemSmall:
                SmallStripesFooter(palette: palette)

            case .systemMedium:
                MediumStripesFooter(palette: palette, colors: colors)

            case .systemLarge:
                LargeStripesFooter(palette: palette, colors: colors)

            default:
                SmallStripesFooter(palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SmallStripesFooter: View {
    let palette: WidgetPalette
    var body: some View {
        HStack {
            Text(palette.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            Spacer()
            Text("\(palette.colors.count)")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial.opacity(0.85))
    }
}

private struct MediumStripesFooter: View {
    let palette: WidgetPalette
    let colors: [WidgetPalette.WidgetColor]
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(colors, id: \.hex) { c in
                Text(c.hex.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.85))
    }
}

private struct LargeStripesFooter: View {
    let palette: WidgetPalette
    let colors: [WidgetPalette.WidgetColor]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(colors, id: \.hex) { c in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(widgetHex: c.hex))
                        .frame(width: 20, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    Text(c.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(c.hex.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            Divider().overlay(.white.opacity(0.15))
            HStack {
                Text(palette.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("AWBY")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial.opacity(0.9))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 2: MOSAIC
// Grid of rounded swatches on a neutral background.
// ═════════════════════════════════════════════════════════════

struct MosaicWidget: View {
    let palette: WidgetPalette
    let family: WidgetFamily

    var body: some View {
        ZStack {
            // Subtle gradient bg from first and last colour
            LinearGradient(
                colors: [
                    Color(widgetHex: palette.colors.first?.hex ?? "#F5F2EE").opacity(0.25),
                    Color(widgetHex: palette.colors.last?.hex  ?? "#F5F2EE").opacity(0.15),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color.white.opacity(0.88)

            switch family {
            case .systemSmall:  SmallMosaic(palette: palette)
            case .systemMedium: MediumMosaic(palette: palette)
            case .systemLarge:  LargeMosaic(palette: palette)
            default:            SmallMosaic(palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SmallMosaic: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(4)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(colors, id: \.hex) { c in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(widgetHex: c.hex))
                        .aspectRatio(1, contentMode: .fit)
                        .shadow(color: Color(widgetHex: c.hex).opacity(0.3), radius: 4, y: 2)
                }
            }
            Text(palette.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1A1A1A"))
                .lineLimit(1)
        }
        .padding(14)
    }
}

private struct MediumMosaic: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(5)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(colors, id: \.hex) { c in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(widgetHex: c.hex))
                            .frame(height: 64)
                            .shadow(color: Color(widgetHex: c.hex).opacity(0.35), radius: 6, y: 3)
                        Text(c.hex.dropFirst())
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.5))
                    }
                }
            }
            HStack {
                Text(palette.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                Spacer()
                Text("AWBY")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.25))
            }
        }
        .padding(14)
    }
}

private struct LargeMosaic: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(6)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(colors, id: \.hex) { c in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(widgetHex: c.hex))
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: Color(widgetHex: c.hex).opacity(0.35), radius: 8, y: 3)
                        VStack(spacing: 2) {
                            Text(c.name)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#1A1A1A"))
                                .lineLimit(1)
                            Text(c.hex.uppercased())
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.4))
                        }
                    }
                }
            }
            HStack {
                Text(palette.title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                Spacer()
                Text("AWBY")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.2))
            }
        }
        .padding(16)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 3: SPOTLIGHT
// One dominant hero colour with smaller supporting swatches.
// ═════════════════════════════════════════════════════════════

struct SpotlightWidget: View {
    let palette: WidgetPalette
    let family: WidgetFamily

    var hero: WidgetPalette.WidgetColor? { palette.colors.first }
    var supporting: [WidgetPalette.WidgetColor] { Array(palette.colors.dropFirst().prefix(4)) }

    var body: some View {
        ZStack {
            if let h = hero {
                Color(widgetHex: h.hex)
            }

            switch family {
            case .systemSmall:  SmallSpotlight(hero: hero, supporting: supporting, palette: palette)
            case .systemMedium: MediumSpotlight(hero: hero, supporting: supporting, palette: palette)
            case .systemLarge:  LargeSpotlight(hero: hero, supporting: supporting, palette: palette)
            default:            SmallSpotlight(hero: hero, supporting: supporting, palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SmallSpotlight: View {
    let hero: WidgetPalette.WidgetColor?
    let supporting: [WidgetPalette.WidgetColor]
    let palette: WidgetPalette
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            // Supporting swatches row
            HStack(spacing: 6) {
                ForEach(supporting, id: \.hex) { c in
                    Circle()
                        .fill(Color(widgetHex: c.hex))
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            // Name
            Text(palette.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
        }
    }
}

private struct MediumSpotlight: View {
    let hero: WidgetPalette.WidgetColor?
    let supporting: [WidgetPalette.WidgetColor]
    let palette: WidgetPalette
    var body: some View {
        HStack(spacing: 0) {
            // Left: hero block with name + hex
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                if let h = hero {
                    Text(h.name)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(h.hex.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Text(palette.title)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: supporting swatches
            VStack(spacing: 6) {
                ForEach(supporting, id: \.hex) { c in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(widgetHex: c.hex))
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        Text(c.hex.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial.opacity(0.25))
        }
    }
}

private struct LargeSpotlight: View {
    let hero: WidgetPalette.WidgetColor?
    let supporting: [WidgetPalette.WidgetColor]
    let palette: WidgetPalette
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero area
            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                if let h = hero {
                    Text(h.name.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(h.hex.uppercased())
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Supporting list
            VStack(spacing: 0) {
                ForEach(supporting, id: \.hex) { c in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(widgetHex: c.hex))
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        Text(c.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(c.hex.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(.ultraThinMaterial.opacity(0.35))
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 4: DARK INK
// Near-black canvas, colour swatches with hex in mono font.
// Feels like a code editor colour theme.
// ═════════════════════════════════════════════════════════════

struct DarkInkWidget: View {
    let palette: WidgetPalette
    let family: WidgetFamily

    var body: some View {
        ZStack {
            Color(hex: "#0D0D0D")
            switch family {
            case .systemSmall:  SmallDarkInk(palette: palette)
            case .systemMedium: MediumDarkInk(palette: palette)
            case .systemLarge:  LargeDarkInk(palette: palette)
            default:            SmallDarkInk(palette: palette)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SmallDarkInk: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(5)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(palette.title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            VStack(spacing: 5) {
                ForEach(colors, id: \.hex) { c in
                    HStack(spacing: 7) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(widgetHex: c.hex))
                            .frame(width: 16, height: 16)
                        Text(c.hex.uppercased())
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                    }
                }
            }
        }
        .padding(14)
    }
}

private struct MediumDarkInk: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(5)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(palette.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("AWBY")
                    .font(.system(size: 8, weight: .black))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#6C63FF").opacity(0.7))
            }
            HStack(spacing: 8) {
                ForEach(colors, id: \.hex) { c in
                    VStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(widgetHex: c.hex))
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        Text(String(c.hex.dropFirst()))
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .padding(14)
    }
}

private struct LargeDarkInk: View {
    let palette: WidgetPalette
    var colors: [WidgetPalette.WidgetColor] { Array(palette.colors.prefix(5)) }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top colour strip
            HStack(spacing: 2) {
                ForEach(colors, id: \.hex) { c in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(widgetHex: c.hex))
                }
            }
            .frame(height: 44)
            .padding(14)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
                .padding(.horizontal, 14)

            // Colour rows
            VStack(spacing: 0) {
                ForEach(colors, id: \.hex) { c in
                    HStack(spacing: 12) {
                        // Index colour block
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(widgetHex: c.hex))
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                        // Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(c.hex.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(widgetHex: c.hex).opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)

                    if c.hex != colors.last?.hex {
                        Rectangle()
                            .fill(.white.opacity(0.05))
                            .frame(height: 1)
                            .padding(.horizontal, 14)
                    }
                }
            }

            Spacer()

            // Footer
            HStack {
                Text(palette.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("AWBY")
                    .font(.system(size: 9, weight: .black))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#6C63FF").opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR INIT FROM HEX (widget-local, no UIKit needed)
// ═════════════════════════════════════════════════════════════

extension Color {
    init(widgetHex hex: String) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8)  & 0xFF) / 255
        let b = Double( v        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
    // Also needed for the dark style footer
    fileprivate init(hex: String) { self.init(widgetHex: hex) }
}
