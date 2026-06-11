import WidgetKit
import SwiftUI

// ─────────────────────────────────────────────────────────────
// Widget Extension Target ONLY
// Requires PaletteWidgetShared.swift also added to this target.
// ─────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════
// MARK: - ENTRY + PROVIDER
// ═════════════════════════════════════════════════════════════

struct PaletteEntry: TimelineEntry {
    let date:    Date
    let palette: WidgetPaletteData
}

struct PaletteTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PaletteEntry {
        PaletteEntry(date: .now, palette: .placeholder)
    }
    func getSnapshot(in context: Context, completion: @escaping (PaletteEntry) -> Void) {
        completion(PaletteEntry(date: .now, palette: WidgetDataManager.load() ?? .placeholder))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PaletteEntry>) -> Void) {
        let e = PaletteEntry(date: .now, palette: WidgetDataManager.load() ?? .placeholder)
        completion(Timeline(entries: [e], policy: .never))
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - MAIN ROUTER
// ═════════════════════════════════════════════════════════════

struct PaletteWidgetView: View {
    let entry: PaletteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let p = entry.palette
        Group {
            switch p.style {
            case .stripes:  StripesWidget(p: p, family: family)
            case .cards:    CardsWidget(p: p, family: family)
            case .mosaic:   MosaicWidget(p: p, family: family)
            case .spectrum: SpectrumWidget(p: p, family: family)
            case .ink:      InkWidget(p: p, family: family)
            case .arch:     ArchWidget(p: p, family: family)
            case .minimal:  MinimalWidget(p: p, family: family)
            case .neon:     NeonWidget(p: p, family: family)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 1 · STRIPES  (improved)
// Full-bleed vertical colour stripes + frosted name pill
// ═════════════════════════════════════════════════════════════

struct StripesWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var body: some View {
        ZStack(alignment: .bottom) {
            // Stripes
            HStack(spacing: 0) {
                ForEach(p.colors, id: \.hex) { c in
                    Color(widgetHex: c.hex)
                }
            }

            // Gradient shadow at bottom
            LinearGradient(
                colors: [.clear, .black.opacity(0.52)],
                startPoint: .center, endPoint: .bottom
            )

            // Name pill
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.title)
                        .font(.system(size: family == .systemSmall ? 12 : 15,
                                      weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if family != .systemSmall {
                        Text("\(p.colors.count) colors")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                Spacer()
                // Dot strip
                if family == .systemSmall {
                    HStack(spacing: 3) {
                        ForEach(p.colors.prefix(6), id: \.hex) { c in
                            Circle()
                                .fill(.white.opacity(0.55))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 2 · CARDS  (improved)
// Dark background + colour circles + name + truncated hex
// ═════════════════════════════════════════════════════════════

struct CardsWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var maxRows: Int {
        switch family {
        case .systemSmall:  return 4
        case .systemLarge:  return 8
        default:            return 5
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.09)

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(p.title)
                        .font(.system(size: family == .systemSmall ? 11 : 13,
                                      weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    Spacer()
                    Text("\(p.colors.count)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.horizontal, 13)
                .padding(.top, 11)
                .padding(.bottom, 8)

                // Thin accent stripe
                HStack(spacing: 0) {
                    ForEach(p.colors, id: \.hex) { c in
                        Color(widgetHex: c.hex)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 13)
                .padding(.bottom, 8)

                // Colour rows
                VStack(spacing: family == .systemSmall ? 5 : 7) {
                    ForEach(p.colors.prefix(maxRows), id: \.hex) { c in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(widgetHex: c.hex))
                                .frame(width: 16, height: 16)
                                .shadow(color: Color(widgetHex: c.hex).opacity(0.5), radius: 3)
                            Text(c.name)
                                .font(.system(size: family == .systemSmall ? 9 : 11,
                                              weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .lineLimit(1)
                            Spacer()
                            Text(c.hex.uppercased())
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal, 13)

                Spacer()
            }
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 3 · MOSAIC  (improved)
// Rounded-corner squares in a grid, frosted title chip
// ═════════════════════════════════════════════════════════════

struct MosaicWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var columns: Int {
        switch family {
        case .systemSmall: return 2
        case .systemLarge: return 4
        default:           return 3
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.93)

            let cols = columns
            let chunks = stride(from: 0, to: p.colors.count, by: cols).map {
                Array(p.colors[$0 ..< min($0 + cols, p.colors.count)])
            }

            VStack(spacing: 3) {
                ForEach(Array(chunks.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 3) {
                        ForEach(row, id: \.hex) { c in
                            ZStack(alignment: .bottomLeading) {
                                Color(widgetHex: c.hex)
                                if family != .systemSmall {
                                    Text(c.hex.uppercased())
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.75))
                                        .padding(4)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        // Fill any empty slots in last row
                        if row.count < cols {
                            ForEach(0 ..< (cols - row.count), id: \.self) { _ in
                                Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
            }
            .padding(3)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Name chip bottom-right
            Text(p.title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(.regularMaterial, in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 4 · SPECTRUM  ✦ new
// Diagonal gradient through all palette colours + bold title
// ═════════════════════════════════════════════════════════════

struct SpectrumWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var body: some View {
        ZStack {
            // Diagonal gradient using every palette colour
            LinearGradient(
                colors: p.colors.map { Color(widgetHex: $0.hex) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Dark vignette to make text readable
            RadialGradient(
                colors: [.clear, .black.opacity(0.28)],
                center: .center,
                startRadius: 20,
                endRadius: 140
            )

            VStack(spacing: family == .systemSmall ? 6 : 10) {
                Text(p.title)
                    .font(.system(size: family == .systemSmall ? 15 : 22,
                                  weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Colour dot row
                HStack(spacing: family == .systemSmall ? 4 : 6) {
                    ForEach(p.colors.prefix(family == .systemSmall ? 5 : 8), id: \.hex) { c in
                        Circle()
                            .fill(.white.opacity(0.35))
                            .frame(width: family == .systemSmall ? 8 : 10,
                                   height: family == .systemSmall ? 8 : 10)
                            .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                    }
                }
            }
            .padding(14)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 5 · INK  ✦ new
// Dark canvas, large overlapping translucent colour circles
// ═════════════════════════════════════════════════════════════

struct InkWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color(red: 0.05, green: 0.05, blue: 0.06)

            GeometryReader { geo in
                let w   = geo.size.width
                let h   = geo.size.height
                let n   = p.colors.count
                let dia = min(w, h) * (family == .systemSmall ? 1.05 : 0.85)

                ZStack {
                    ForEach(Array(p.colors.enumerated()), id: \.element.hex) { i, c in
                        let t      = n > 1 ? Double(i) / Double(n - 1) : 0.5
                        // Wave path: x spreads left→right, y follows a sine arc
                        let xPos   = t * (w - dia * 0.35) - dia * 0.1
                        let yPos   = h / 2 - sin(t * .pi) * h * 0.28
                        Circle()
                            .fill(Color(widgetHex: c.hex).opacity(0.82))
                            .frame(width: dia, height: dia)
                            .position(x: xPos + dia / 2, y: yPos)
                    }
                }
            }

            // Palette title
            Text(p.title)
                .font(.system(size: family == .systemSmall ? 10 : 13,
                              weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
                .padding(10)
        }
        .clipped()
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 6 · ARCH  ✦ new
// Stacked concentric semicircles anchored at the bottom centre
// ═════════════════════════════════════════════════════════════

struct ArchWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.97, green: 0.96, blue: 0.94)

            GeometryReader { geo in
                let w     = geo.size.width
                let h     = geo.size.height
                let col   = Array(p.colors.prefix(6))
                let n     = col.count
                let maxR  = max(w, h) * 1.0

                ZStack {
                    // Draw outermost (largest) first so inner ones cover them
                    ForEach(0 ..< n, id: \.self) { i in
                        let r = maxR * (Double(n - i) / Double(n))
                        ArchShape()
                            .fill(Color(widgetHex: col[i].hex))
                            .frame(width: r * 2, height: r)
                            .position(x: w / 2, y: h - r / 2)
                    }
                }
            }

            // Title at top
            Text(p.title)
                .font(.system(size: family == .systemSmall ? 11 : 14,
                              weight: .bold, design: .rounded))
                .foregroundStyle(Color(widgetHex: p.colors.first?.hex ?? "#333333"))
                .padding(11)
        }
        .clipped()
    }
}

struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            // Semicircle anchored at the bottom centre of the frame
            p.addArc(
                center:     CGPoint(x: rect.midX, y: rect.maxY),
                radius:     rect.width / 2,
                startAngle: .degrees(180),
                endAngle:   .degrees(0),
                clockwise:  false
            )
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 7 · MINIMAL  ✦ new
// White background, thin colour stripe at top, big bold title
// ═════════════════════════════════════════════════════════════

struct MinimalWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    var body: some View {
        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 0) {
                // Thin multi-colour stripe
                HStack(spacing: 0) {
                    ForEach(p.colors, id: \.hex) { c in
                        Color(widgetHex: c.hex)
                    }
                }
                .frame(height: family == .systemSmall ? 5 : 6)

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    // Palette title
                    Text(p.title)
                        .font(.system(size: family == .systemSmall ? 18 : 24,
                                      weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.12))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    // Colour circles
                    HStack(spacing: family == .systemSmall ? 5 : 7) {
                        ForEach(p.colors.prefix(family == .systemSmall ? 6 : 8), id: \.hex) { c in
                            Circle()
                                .fill(Color(widgetHex: c.hex))
                                .frame(width: family == .systemSmall ? 13 : 16,
                                       height: family == .systemSmall ? 13 : 16)
                        }
                    }

                    // Hex strip on medium/large
                    if family != .systemSmall {
                        HStack(spacing: 8) {
                            ForEach(p.colors.prefix(5), id: \.hex) { c in
                                Text(c.hex.uppercased())
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.58))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - STYLE 8 · NEON  ✦ new
// Near-black background, glowing colour orbs with drop shadow
// ═════════════════════════════════════════════════════════════

struct NeonWidget: View {
    let p: WidgetPaletteData
    let family: WidgetFamily

    // Layout: how many columns for the dot grid
    private var columns: Int { family == .systemSmall ? 3 : 5 }

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.08)

            VStack(spacing: 0) {
                // Header
                Text(p.title)
                    .font(.system(size: family == .systemSmall ? 9 : 11,
                                  weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 13)
                    .padding(.top, 12)
                    .padding(.bottom, family == .systemSmall ? 10 : 14)

                // Glow dots grid
                let cols = columns
                let chunks = stride(from: 0, to: p.colors.count, by: cols).map {
                    Array(p.colors[$0 ..< min($0 + cols, p.colors.count)])
                }

                VStack(spacing: family == .systemSmall ? 10 : 14) {
                    ForEach(Array(chunks.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: family == .systemSmall ? 10 : 16) {
                            ForEach(row, id: \.hex) { c in
                                neonOrb(c)
                            }
                            // Spacer dots for incomplete rows
                            if row.count < cols {
                                ForEach(0 ..< (cols - row.count), id: \.self) { _ in
                                    Spacer().frame(
                                        width: family == .systemSmall ? 26 : 32,
                                        height: family == .systemSmall ? 26 : 32
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 13)

                Spacer()
            }
        }
    }

    private func neonOrb(_ c: WidgetPaletteData.WidgetColorData) -> some View {
        let size: CGFloat = family == .systemSmall ? 26 : 32
        let col = Color(widgetHex: c.hex)
        return Circle()
            .fill(col)
            .frame(width: size, height: size)
            // Inner glow
            .shadow(color: col.opacity(0.85), radius: 6)
            // Outer soft halo
            .shadow(color: col.opacity(0.35), radius: 14)
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET DECLARATION
// ═════════════════════════════════════════════════════════════

struct PaletteWidget: Widget {
    let kind = "AWBYPaletteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PaletteTimelineProvider()) { entry in
            PaletteWidgetView(entry: entry)
        }
        .configurationDisplayName("AWBY Palette")
        .description("Show your favourite colour palette on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}


