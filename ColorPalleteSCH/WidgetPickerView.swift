import SwiftUI
import WidgetKit

// ═════════════════════════════════════════════════════════════
// MARK: - WIDGET PICKER VIEW
//
// Presented from SavedPaletteDetailView with the current palette.
// The user only picks a STYLE — the palette is already decided.
//
// Usage in SavedPaletteDetailView:
//   .sheet(isPresented: $showWidgetPicker) {
//       WidgetPickerView(palette: palette)
//   }
// ═════════════════════════════════════════════════════════════

struct WidgetPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let palette: SavedPalette

    @State private var selectedStyle: WidgetDisplayStyle
    @State private var didApply  = false
    @State private var animateIn = false

    // Pre-select the style already saved (if any), otherwise default to .stripes
    init(palette: SavedPalette) {
        self.palette = palette
        let saved = WidgetDataManager.load()?.style ?? .stripes
        self._selectedStyle = State(initialValue: saved)
    }

    // Colours for previews — derived from the passed palette
    private var previewColors: [WidgetPaletteData.WidgetColorData] {
        palette.colors.map { .init(name: $0.name, hex: $0.hex) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        paletteHeader
                            .padding(.top, 20)
                        livePreview
                            .padding(.top, 20)
                        stylePicker
                            .padding(.top, 20)
                        applyButton
                            .padding(.top, 28)
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .navigationTitle("Widget Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.55)) { animateIn = true }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: – Palette Header
    // Shows the palette this style will apply to — no confusion

    private var paletteHeader: some View {
        HStack(spacing: 14) {
            // Colour strip
            HStack(spacing: 0) {
                ForEach(Array(palette.colors.prefix(6).enumerated()), id: \.offset) { _, c in
                    Color(hex: c.hex)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("AppText").opacity(0.08), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("ADDING TO WIDGET")
                    .font(.system(size: 9, weight: .bold)).tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.28))
                Text(palette.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
                Text("\(palette.colors.count) colors")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.38))
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("AppText").opacity(0.07), lineWidth: 1))
                .shadow(color: Color("AppText").opacity(0.05), radius: 10, y: 4)
        )
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: – Live Preview Card
    // Full-size preview of the selected style with the actual palette

    private var livePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("PREVIEW")

            ZStack(alignment: .topTrailing) {
                miniPreview(style: selectedStyle, colors: previewColors)
                    .frame(maxWidth: .infinity).frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
                    )
                    .shadow(color: Color("AppText").opacity(0.1), radius: 16, y: 6)
                    .animation(.easeInOut(duration: 0.22), value: selectedStyle)

                // Style badge
                Text(selectedStyle.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black)).tracking(1.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                    .padding(12)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.08), value: animateIn)
    }

    // MARK: – Style Picker
    // Horizontal scroll of 8 style chips — each shows THIS palette

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("CHOOSE A STYLE")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WidgetDisplayStyle.allCases) { style in
                        styleChip(style)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.12), value: animateIn)
    }

    private func styleChip(_ style: WidgetDisplayStyle) -> some View {
        let isSelected = selectedStyle == style
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedStyle = style }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 8) {
                // 72×72 mini preview using the actual palette
                miniPreview(style: style, colors: previewColors)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.08),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color(hex: "#6C63FF").opacity(0.25) : Color("AppText").opacity(0.05),
                        radius: isSelected ? 10 : 5, y: 3
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.28), value: isSelected)

                VStack(spacing: 2) {
                    Text(style.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.45))

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

    // MARK: – Apply Button

    private var applyButton: some View {
        Button(action: apply) {
            HStack(spacing: 10) {
                Image(systemName: didApply ? "checkmark.circle.fill" : "rectangle.stack.badge.plus")
                    .font(.system(size: 18, weight: .semibold))
                Text(didApply ? "Added to Widget!" : "Add to Widget")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(didApply ? Color(hex: "#34C759") : .white)
            .frame(maxWidth: .infinity).frame(height: 60)
            .background(
                Group {
                    if didApply {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#34C759").opacity(0.12))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5))
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                startPoint: .leading, endPoint: .trailing))
                            .shadow(color: Color(hex: "#6C63FF").opacity(0.35), radius: 16, y: 6)
                    }
                }
            )
        }
        .disabled(didApply)
        .animation(.spring(response: 0.35), value: didApply)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.18), value: animateIn)
    }

    // MARK: – Actions

    private func apply() {
        let data = WidgetPaletteData(
            id:     palette.id.uuidString,
            title:  palette.title,
            colors: palette.colors.map { .init(name: $0.name, hex: $0.hex) },
            style:  selectedStyle
        )
        WidgetDataManager.save(data)
        WidgetCenter.shared.reloadAllTimelines()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { didApply = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { dismiss() }
    }

    // MARK: – Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(2.5)
            .foregroundStyle(Color("AppText").opacity(0.28))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - MINI STYLE PREVIEWS
// Each style is its own @ViewBuilder to avoid type-checker timeout
// ═════════════════════════════════════════════════════════════

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

@ViewBuilder private func miniStripes(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .bottom) {
        HStack(spacing: 0) { ForEach(c, id: \.hex) { Color(widgetHex: $0.hex) } }
        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
        Text("Palette")
            .font(.system(size: 9, weight: .bold)).foregroundStyle(.white).padding(.bottom, 8)
    }
}

@ViewBuilder private func miniCards(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        Color(red: 0.07, green: 0.07, blue: 0.09)
        VStack(alignment: .leading, spacing: 4) {
            Text("Palette")
                .font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 2)
            ForEach(c.prefix(4), id: \.hex) { item in
                HStack(spacing: 5) {
                    Circle().fill(Color(widgetHex: item.hex)).frame(width: 9, height: 9)
                    Text(item.name).font(.system(size: 7)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

@ViewBuilder private func miniMosaic(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    let pairs = stride(from: 0, to: c.count, by: 2)
        .map { Array(c[$0 ..< min($0 + 2, c.count)]) }
    ZStack {
        Color(red: 0.96, green: 0.95, blue: 0.93)
        VStack(spacing: 2) {
            ForEach(Array(pairs.prefix(3).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.hex) { Color(widgetHex: $0.hex).frame(maxWidth: .infinity, maxHeight: .infinity) }
                }
            }
        }
        .padding(2).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

@ViewBuilder private func miniSpectrum(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        LinearGradient(colors: c.map { Color(widgetHex: $0.hex) }, startPoint: .topLeading, endPoint: .bottomTrailing)
        Text("Palette")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 3)
    }
}

@ViewBuilder private func miniInk(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .bottomLeading) {
        Color(red: 0.05, green: 0.05, blue: 0.06)
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, n = c.count, d = min(w, h) * 1.0
            ZStack {
                ForEach(Array(c.enumerated()), id: \.element.hex) { i, item in
                    let t: Double = n > 1 ? Double(i) / Double(n - 1) : 0.5
                    Circle()
                        .fill(Color(widgetHex: item.hex).opacity(0.82))
                        .frame(width: d, height: d)
                        .position(x: CGFloat(t) * (w - d * 0.35) - d * 0.1 + d / 2,
                                  y: h / 2 - sin(t * .pi) * h * 0.28)
                }
            }
        }
        .clipped()
        Text("Palette")
            .font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.7)).padding(7)
    }
}

@ViewBuilder private func miniArch(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack(alignment: .topLeading) {
        Color(red: 0.97, green: 0.96, blue: 0.94)
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, n = min(c.count, 5), maxR = max(w, h) * 1.0
            ZStack {
                ForEach(0..<n, id: \.self) { i in
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

@ViewBuilder private func miniMinimal(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    ZStack {
        Color.white
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) { ForEach(c, id: \.hex) { Color(widgetHex: $0.hex) } }.frame(height: 4)
            Spacer()
            VStack(alignment: .leading, spacing: 5) {
                Text("Palette").font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.1, green: 0.1, blue: 0.12))
                HStack(spacing: 4) {
                    ForEach(c.prefix(5), id: \.hex) {
                        Circle().fill(Color(widgetHex: $0.hex)).frame(width: 9, height: 9)
                    }
                }
            }
            .padding(.horizontal, 8).padding(.bottom, 8)
        }
    }
}

@ViewBuilder private func miniNeon(_ c: [WidgetPaletteData.WidgetColorData]) -> some View {
    let row1 = Array(c.prefix(3))
    let row2 = Array(c.dropFirst(3).prefix(3))
    ZStack {
        Color(red: 0.03, green: 0.03, blue: 0.08)
        VStack(spacing: 0) {
            Text("Palette")
                .font(.system(size: 7, weight: .bold)).foregroundStyle(.white.opacity(0.28))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 9).padding(.top, 8).padding(.bottom, 6)
            VStack(spacing: 8) {
                HStack(spacing: 8) { ForEach(row1, id: \.hex) { miniNeonDot($0.hex) } }
                if !row2.isEmpty {
                    HStack(spacing: 8) { ForEach(row2, id: \.hex) { miniNeonDot($0.hex) } }
                }
            }
        }
    }
}

private func miniNeonDot(_ hex: String) -> some View {
    let col = Color(widgetHex: hex)
    return Circle().fill(col).frame(width: 16, height: 16)
        .shadow(color: col.opacity(0.85), radius: 5)
        .shadow(color: col.opacity(0.35), radius: 10)
}

// ─────────────────────────────────────────────────────────────
// Local arch shape — avoids depending on the widget target
// ─────────────────────────────────────────────────────────────
private struct WPVArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                     radius: rect.width / 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
