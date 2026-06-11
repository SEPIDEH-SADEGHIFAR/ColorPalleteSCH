import SwiftUI
import SwiftData
import WidgetKit

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET PICKER VIEW
// Lets the user choose which saved palette + which of the 8
// widget styles appears on their Home Screen.
// ═════════════════════════════════════════════════════════════

struct WidgetPickerView: View {
    @Environment(\.dismiss) private var dismiss

    // Pull every saved palette straight from SwiftData
    @Query(sort: \SavedPalette.title) private var savedPalettes: [SavedPalette]

    // Currently selected state
    @State private var selectedTitle: String = WidgetDataManager.load()?.title ?? ""
    @State private var selectedStyle: WidgetDisplayStyle = WidgetDataManager.load()?.style ?? .stripes

    // UI
    @State private var didApply  = false
    @State private var animateIn = false

    // The palette the user has tapped (for the live preview)
    private var selectedPalette: SavedPalette? {
        savedPalettes.first { $0.title == selectedTitle }
            ?? savedPalettes.first
    }

    // Colours for the mini style previews — use selected palette or fallback
    private var previewColors: [WidgetPaletteData.WidgetColorData] {
        let src = selectedPalette?.colors ?? []
        return src.map { .init(name: $0.name, hex: $0.hex) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                if savedPalettes.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            livePreviewCard.padding(.top, 20)
                            styleSection.padding(.top, 24)
                            paletteSection.padding(.top, 24)
                            applyButton.padding(.top, 28)
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 22)
                    }
                }
            }
            .navigationTitle("Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                // Seed selection from whatever is already saved
                if selectedTitle.isEmpty, let first = savedPalettes.first {
                    selectedTitle = first.title
                }
                withAnimation(.spring(response: 0.55)) { animateIn = true }
            }
        }
    }

    // MARK: ── Live Preview Card ──────────────────────────────────
    // Shows exactly how the widget will look before the user applies

    private var livePreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("PREVIEW")

            ZStack {
                miniPreview(style: selectedStyle, colors: previewColors)
                    .frame(maxWidth: .infinity).frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color("AppText").opacity(0.08), radius: 14, y: 5)
                    .animation(.easeInOut(duration: 0.22), value: selectedStyle)
                    .animation(.easeInOut(duration: 0.22), value: selectedTitle)

                // Style label badge
                Text(selectedStyle.rawValue)
                    .font(.system(size: 10, weight: .bold)).tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }
        }
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: ── Style Picker Section ───────────────────────────────

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("STYLE")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WidgetDisplayStyle.allCases) { style in
                        styleChip(style)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    private func styleChip(_ style: WidgetDisplayStyle) -> some View {
        let selected = selectedStyle == style
        return Button {
            withAnimation(.spring(response: 0.32)) { selectedStyle = style }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                // Mini 72×72 style preview
                miniPreview(style: style, colors: previewColors)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selected ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.09),
                                    lineWidth: selected ? 2.5 : 1)
                    )
                    .shadow(color: selected ? Color(hex: "#6C63FF").opacity(0.22) : Color("AppText").opacity(0.05),
                            radius: selected ? 8 : 4, y: 3)
                    .scaleEffect(selected ? 1.04 : 1.0)
                    .animation(.spring(response: 0.28), value: selected)

                VStack(spacing: 2) {
                    Text(style.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selected ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.5))

                    if style.isNew {
                        Text("NEW")
                            .font(.system(size: 7, weight: .black)).tracking(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#6C63FF")))
                    }
                }
            }
        }
    }

    // MARK: ── Palette Picker Section ─────────────────────────────

    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("PALETTE")

            VStack(spacing: 8) {
                ForEach(savedPalettes) { palette in
                    paletteRow(palette)
                }
            }
        }
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.15), value: animateIn)
    }

    private func paletteRow(_ palette: SavedPalette) -> some View {
        let isSelected = selectedTitle == palette.title
        return Button {
            withAnimation(.spring(response: 0.32)) { selectedTitle = palette.title }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                // Colour strip swatch
                HStack(spacing: 2) {
                    ForEach(Array(palette.colors.prefix(5).enumerated()), id: \.offset) { _, c in
                        Color(hex: c.hex)
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color(hex: "#6C63FF").opacity(0.5) : Color("AppText").opacity(0.08),
                                lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: Color("AppText").opacity(0.06), radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(palette.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .lineLimit(1)
                    Text("\(palette.colors.count) color\(palette.colors.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.38))
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#6C63FF"))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color("AppText").opacity(0.18))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected
                          ? Color(hex: "#6C63FF").opacity(0.07)
                          : Color(uiColor: .secondarySystemGroupedBackground))
                    .shadow(color: Color("AppText").opacity(isSelected ? 0.06 : 0.04),
                            radius: isSelected ? 10 : 6, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color(hex: "#6C63FF").opacity(0.2) : Color("AppText").opacity(0.06),
                                    lineWidth: 1)
                    )
            )
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: ── Apply Button ────────────────────────────────────────

    private var applyButton: some View {
        Button(action: apply) {
            HStack(spacing: 10) {
                Image(systemName: didApply ? "checkmark.circle.fill" : "square.stack.3d.up.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text(didApply ? "Widget Updated!" : "Apply to Widget")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(
                didApply ? Color(hex: "#34C759") : Color("AppBackground")
            )
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                Group {
                    if didApply {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "#34C759").opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .shadow(color: Color(hex: "#6C63FF").opacity(0.32), radius: 14, y: 6)
                    }
                }
            )
        }
        .disabled(selectedTitle.isEmpty || didApply)
        .animation(.spring(response: 0.35), value: didApply)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.2), value: animateIn)
    }

    // MARK: ── Empty State ─────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color("AppText").opacity(0.25))
            Text("No Palettes Yet")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppText"))
            Text("Save a palette from the main screen\nto pin it as a widget.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.42))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Button("Got It") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "#6C63FF"))
        }
        .padding(32)
    }

    // MARK: ── Helpers ─────────────────────────────────────────────

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(2.5)
            .foregroundStyle(Color("AppText").opacity(0.28))
    }

    private func apply() {
        guard let palette = selectedPalette else { return }
        let data = WidgetPaletteData(
            id:     palette.title,   // stable identifier
            title:  palette.title,
            colors: palette.colors.map { .init(name: $0.name, hex: $0.hex) },
            style:  selectedStyle
        )
        WidgetDataManager.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { didApply = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - MINI STYLE PREVIEWS
// Each style is its own @ViewBuilder function so Swift's
// type-checker never has to evaluate all 8 at once.
// ═════════════════════════════════════════════════════════════

/// Thin router — delegates to one of the 8 style functions below.
@ViewBuilder
private func miniPreview(
    style:  WidgetDisplayStyle,
    colors: [WidgetPaletteData.WidgetColorData]
) -> some View {
    let safe = colors.isEmpty ? WidgetPaletteData.placeholder.colors : colors
    switch style {
    case .stripes:  miniStripes(safe)
    case .cards:    miniCards(safe)
    case .mosaic:   miniMosaic(safe)
    case .spectrum: miniSpectrum(safe)
    case .ink:      miniInk(safe)
    case .arch:     miniArch(safe)
    case .minimal:  miniMinimal(safe)
    case .neon:     miniNeon(safe)
    }
}

// ── Stripes ──────────────────────────────────────────────────
@ViewBuilder
private func miniStripes(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .bottom) {
        HStack(spacing: 0) {
            ForEach(c, id: \.hex) { Color(widgetHex: $0.hex) }
        }
        LinearGradient(colors: [.clear, .black.opacity(0.5)],
                       startPoint: .center, endPoint: .bottom)
        Text("Palette")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.bottom, 8)
    }
}

// ── Cards ─────────────────────────────────────────────────────
@ViewBuilder
private func miniCards(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        Color(red: 0.07, green: 0.07, blue: 0.09)
        VStack(alignment: .leading, spacing: 4) {
            Text("Palette")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 2)
            ForEach(c.prefix(4), id: \.hex) { item in
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(widgetHex: item.hex))
                        .frame(width: 9, height: 9)
                    Text(item.name)
                        .font(.system(size: 7))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// ── Mosaic ────────────────────────────────────────────────────
@ViewBuilder
private func miniMosaic(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    let pairs = stride(from: 0, to: c.count, by: 2)
        .map { Array(c[$0 ..< min($0 + 2, c.count)]) }
    ZStack {
        Color(red: 0.96, green: 0.95, blue: 0.93)
        VStack(spacing: 2) {
            ForEach(Array(pairs.prefix(3).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.hex) { item in
                        Color(widgetHex: item.hex)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ── Spectrum ──────────────────────────────────────────────────
@ViewBuilder
private func miniSpectrum(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        LinearGradient(
            colors: c.map { Color(widgetHex: $0.hex) },
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        Text("Palette")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 3)
    }
}

// ── Ink ───────────────────────────────────────────────────────
@ViewBuilder
private func miniInk(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .bottomLeading) {
        Color(red: 0.05, green: 0.05, blue: 0.06)
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let n = c.count
            let d = min(w, h) * 1.0
            ZStack {
                ForEach(Array(c.enumerated()), id: \.element.hex) { i, item in
                    let t: Double = n > 1 ? Double(i) / Double(n - 1) : 0.5
                    let x: CGFloat = t * (w - d * 0.35) - d * 0.1
                    let y: CGFloat = h / 2 - sin(t * .pi) * h * 0.28
                    Circle()
                        .fill(Color(widgetHex: item.hex).opacity(0.82))
                        .frame(width: d, height: d)
                        .position(x: x + d / 2, y: y)
                }
            }
        }
        .clipped()
        Text("Palette")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.white.opacity(0.7))
            .padding(7)
    }
}

// ── Arch ──────────────────────────────────────────────────────
@ViewBuilder
private func miniArch(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .topLeading) {
        Color(red: 0.97, green: 0.96, blue: 0.94)
        GeometryReader { geo in
            let w    = geo.size.width
            let h    = geo.size.height
            let n    = min(c.count, 5)
            let maxR = max(w, h) * 1.0
            ZStack {
                ForEach(0 ..< n, id: \.self) { i in
                    let r: CGFloat = maxR * CGFloat(n - i) / CGFloat(n)
                    WPVArchShape()
                        .fill(Color(widgetHex: c[i].hex))
                        .frame(width: r * 2, height: r)
                        .position(x: w / 2, y: h - r / 2)
                }
            }
        }
        Text("Palette")
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(Color(widgetHex: c.first?.hex ?? "#333333"))
            .padding(8)
    }
    .clipped()
}

// ── Minimal ───────────────────────────────────────────────────
@ViewBuilder
private func miniMinimal(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        Color.white
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(c, id: \.hex) { Color(widgetHex: $0.hex) }
            }
            .frame(height: 4)
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                Text("Palette")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.12))
                HStack(spacing: 4) {
                    ForEach(c.prefix(5), id: \.hex) { item in
                        Circle()
                            .fill(Color(widgetHex: item.hex))
                            .frame(width: 9, height: 9)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

// ── Neon ──────────────────────────────────────────────────────
@ViewBuilder
private func miniNeon(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    let row1 = Array(c.prefix(3))
    let row2 = Array(c.dropFirst(3).prefix(3))
    ZStack {
        Color(red: 0.03, green: 0.03, blue: 0.08)
        VStack(spacing: 0) {
            Text("Palette")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 9).padding(.top, 8).padding(.bottom, 6)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(row1, id: \.hex) { neonDot($0.hex, size: 16) }
                }
                if !row2.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(row2, id: \.hex) { neonDot($0.hex, size: 16) }
                    }
                }
            }
        }
    }
}

private func neonDot(_ hex: String, size: CGFloat) -> some View {
    let col = Color(widgetHex: hex)
    return Circle()
        .fill(col)
        .frame(width: size, height: size)
        .shadow(color: col.opacity(0.85), radius: 5)
        .shadow(color: col.opacity(0.35), radius: 10)
}

// ─────────────────────────────────────────────────────────────
// Local arch shape — avoids depending on the widget target's
// ArchShape which is not visible from the main app target.
// ─────────────────────────────────────────────────────────────
private struct WPVArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
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
