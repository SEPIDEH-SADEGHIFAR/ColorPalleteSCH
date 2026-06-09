import SwiftUI
import SwiftData
import FoundationModels

// ═════════════════════════════════════════════════════════════
// MARK: - GATE
// ═════════════════════════════════════════════════════════════

struct ContentView: View {
    var body: some View {
        if #available(iOS 26.0, *) { AIGeneratorView() }
        else { AIUnavailableView() }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - UNAVAILABLE (iOS < 26)
// ═════════════════════════════════════════════════════════════

struct AIUnavailableView: View {
    @Environment(\.dismiss) private var dismiss
    private let features = [
        ("paintbrush.fill",           "#FF8C42", "Manual Studio",  "Build any palette by hand"),
        ("photo.on.rectangle.angled", "#2DD4BF", "Image Studio",   "Extract colors from photos"),
        ("sparkle.magnifyingglass",   "#F59E0B", "Color Explorer", "Discover harmonies"),
        ("square.and.arrow.down",     "#6DBF8A", "Export & Share", "11 sticker designs per color"),
    ]
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(RadialGradient(colors: [Color(hex: "#6C63FF").opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: 60)).frame(width: 120, height: 120).blur(radius: 20)
                                Circle().stroke(Color(hex: "#6C63FF").opacity(0.2), lineWidth: 1).frame(width: 80, height: 80)
                                Circle().fill(Color(hex: "#6C63FF").opacity(0.15)).frame(width: 64, height: 64)
                                Image(systemName: "wand.and.stars").font(.system(size: 26)).foregroundStyle(Color(hex: "#6C63FF"))
                            }
                            Text("AI STUDIO").font(.system(size: 11, weight: .bold)).tracking(3).foregroundStyle(Color(hex: "#6C63FF"))
                            Text("Requires iOS 26").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white).multilineTextAlignment(.center)
                            Text("AI palette generation uses Apple Intelligence, available on iOS 26 and later.").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.45)).multilineTextAlignment(.center).lineSpacing(3)
                        }.padding(.top, 48)
                        VStack(spacing: 10) {
                            Text("AVAILABLE ON YOUR DEVICE").font(.system(size: 9, weight: .bold)).tracking(2.5).foregroundStyle(.white.opacity(0.28))
                            ForEach(features, id: \.2) { icon, color, title, sub in
                                HStack(spacing: 14) {
                                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: color)).frame(width: 44, height: 44).overlay(Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(.white))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                                        Text(sub).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "#34C759"))
                                }.padding(14).background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.05)))
                            }
                        }.padding(.horizontal, 22)
                        Button { dismiss() } label: {
                            Text("Got It").font(.system(size: 17, weight: .bold)).foregroundStyle(Color(hex: "#0D0D0D")).frame(maxWidth: .infinity).frame(height: 56).background(RoundedRectangle(cornerRadius: 16).fill(.white))
                        }.padding(.horizontal, 22).padding(.bottom, 40)
                    }
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").foregroundStyle(.white.opacity(0.55)).frame(width: 30, height: 30).background(.white.opacity(0.09)).clipShape(Circle())
                }
            }}
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - PALETTE STYLE PRESET
// ═════════════════════════════════════════════════════════════

enum PaletteStylePreset: String, CaseIterable, Identifiable {
    case all        = "All"
    case sensible   = "Sensible"
    case fancyLight = "Fancy Light"
    case fancyDark  = "Fancy Dark"
    case tarnish    = "Tarnish"
    case pastel     = "Pastel"
    case pimp       = "Pimp"
    case intense    = "Intense"

    var id: String { rawValue }

    var sliderValues: (sMin: Double, sMax: Double, lMin: Double, lMax: Double) {
        switch self {
        case .all:        return (0.00, 1.00, 0.00, 1.00)
        case .sensible:   return (0.35, 0.75, 0.30, 0.70)
        case .fancyLight: return (0.40, 0.85, 0.60, 0.92)
        case .fancyDark:  return (0.50, 0.95, 0.08, 0.42)
        case .tarnish:    return (0.04, 0.30, 0.20, 0.62)
        case .pastel:     return (0.20, 0.52, 0.72, 0.95)
        case .pimp:       return (0.75, 1.00, 0.35, 0.70)
        case .intense:    return (0.70, 1.00, 0.15, 0.85)
        }
    }

    var promptDescription: String {
        switch self {
        case .all:        return "No style constraint — be creative and make it genuinely beautiful"
        case .sensible:   return "Balanced, professional — ideal for UI, product design, branding"
        case .fancyLight: return "Bright, airy, luminous — like luxury editorial or high fashion"
        case .fancyDark:  return "Rich, cinematic, moody — premium dark energy"
        case .tarnish:    return "Desaturated, oxidised, weathered — aged metal or worn ceramics"
        case .pastel:     return "Soft, chalky, tender — watercolour, confectionery, hazy sunrise"
        case .pimp:       return "Maximalist, flamboyant, loud — bold and unapologetic"
        case .intense:    return "Electric, vivid, high contrast — strong saturation, dramatic impact"
        }
    }

    // Representative colors shown on each chip — computed from the preset's own ranges
    var chipColors: [Color] {
        let v = sliderValues
        let midS = (v.sMin + v.sMax) / 2
        let midL = (v.lMin + v.lMax) / 2
        let b = midL + midS * min(midL, 1 - midL)
        let sb = b == 0 ? 0.0 : 2 * (1 - midL / b)
        return [0.08, 0.45, 0.72].map { h in
            Color(hue: h, saturation: min(1, sb), brightness: min(1, b))
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - AI GENERATOR VIEW  (iOS 26+)
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct AIGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // ── Parameters ──────────────────────────────────────────────
    @State private var colorCount: Int    = 5
    @State private var hueMin:  Double    = 0.00
    @State private var hueMax:  Double    = 1.00
    @State private var satMin:  Double    = 0.00
    @State private var satMax:  Double    = 1.00
    @State private var lumMin:  Double    = 0.00
    @State private var lumMax:  Double    = 1.00
    @State private var preset:  PaletteStylePreset = .all

    // ── Result ───────────────────────────────────────────────────
    @State private var palette:     ColorPalette?           = nil
    @State private var lockedSlots: [Int: GeneratedColor]   = [:]

    // ── UI ───────────────────────────────────────────────────────
    @State private var isGenerating  = false
    @State private var savedOK       = false
    @State private var animateCards  = false
    @State private var animateIn     = false

    // ── AI session ────────────────────────────────────────────────
    let session = LanguageModelSession(instructions: """
    You are a world-class color palette designer.
    Create beautiful, emotionally resonant palettes that feel intentional and well-crafted.
    Rules:
    • Return EXACTLY the number of colors requested.
    • Each hex code must be valid 6-digit hex starting with #.
    • Names: evocative and poetic, 2–3 words (e.g. "Arctic Whisper", "Ember Glow").
    • Title: a short poetic phrase, 3–5 words, capturing the palette's mood.
    • Make colors HARMONIOUS — they should tell a visual story together.
    Note: HSL values will be mathematically enforced after your response.
    Focus purely on CREATIVITY and HARMONY.
    """)

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        parametersCard.padding(.top, 24)
                        presetsRow.padding(.top, 16)
                        generateButton.padding(.top, 20)
                        if let p = palette {
                            resultSection(p).padding(.top, 36)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 22)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("AppText").opacity(0.5))
                            .frame(width: 32, height: 32)
                            .background(Color("AppText").opacity(0.07))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { animateIn = true }
            }
        }
    }

    // MARK: ── Header ─────────────────────────────────────────────

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("AI STUDIO")
                    .font(.system(size: 11, weight: .bold)).tracking(3)
                    .foregroundStyle(Color(hex: "#6C63FF"))
                Text("Generate\nPalette")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText")).kerning(-1)
            }
            Spacer()
            // Orb — reflects mid-hue of current range
            let midH = (hueMin + hueMax) / 2
            let orbC  = Color(hue: midH, saturation: 0.78, brightness: 0.85)
            /*ZStack {
                Circle().fill(RadialGradient(colors: [orbC.opacity(0.45), .clear], center: .center, startRadius: 0, endRadius: 44)).frame(width: 88, height: 88).blur(radius: 14)
                Circle().stroke(orbC.opacity(0.22), lineWidth: 1).frame(width: 58, height: 58)
                Circle().fill(orbC).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "wand.and.stars").font(.system(size: 17, weight: .medium)).foregroundStyle(.white))
                    .shadow(color: orbC.opacity(0.4), radius: 10, y: 4)
            }*/
            .animation(.easeInOut(duration: 0.3), value: midH)
        }
        .padding(.top, 20)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.04), value: animateIn)
    }

    // MARK: ── Parameters Card ────────────────────────────────────
    // ONE unified card — not 4 separate ones.
    // Each section uses the app's standard label+value header.

    private var parametersCard: some View {
        VStack(spacing: 0) {
            // Colors
            paramSection {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        rowHeader("COLORS", value: "\(colorCount) colors")
                        Text("How many colors to generate")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("AppText").opacity(0.38))
                    }
                    Spacer(minLength: 16)
                    // +/− stepper
                    HStack(spacing: 0) {
                        countBtn(icon: "minus", enabled: colorCount > 2) { colorCount -= 1 }
                        Text("\(colorCount)")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: "#6C63FF"))
                            .frame(width: 38)
                            .animation(.spring(response: 0.22), value: colorCount)
                        countBtn(icon: "plus", enabled: colorCount < 12) { colorCount += 1 }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("AppText").opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("AppText").opacity(0.09), lineWidth: 1))
                    )
                }
            }

            paramDivider

            // Hue Range
            paramSection {
                VStack(spacing: 10) {
                    rowHeader("HUE RANGE", value: "\(Int(hueMin * 360))° – \(Int(hueMax * 360))°")
                    HueRangeSlider(low: $hueMin, high: $hueMax)
                    hintRow(left: hueName(hueMin), right: hueName(hueMax),
                            leftColor: Color(hue: hueMin, saturation: 0.65, brightness: 0.65),
                            rightColor: Color(hue: hueMax, saturation: 0.65, brightness: 0.65))
                }
            }

            paramDivider

            // Saturation
            paramSection {
                let midH = (hueMin + hueMax) / 2
                VStack(spacing: 10) {
                    rowHeader("SATURATION", value: "\(Int(satMin * 100))% – \(Int(satMax * 100))%")
                    TwoThumbSlider(
                        low: $satMin, high: $satMax,
                        track: LinearGradient(
                            colors: [Color(hue: midH, saturation: 0.06, brightness: 0.62),
                                     Color(hue: midH, saturation: 1.0,  brightness: 0.78)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    hintRow(left: "Muted", right: "Vivid")
                }
            }

            paramDivider

            // Brightness
            paramSection {
                VStack(spacing: 10) {
                    rowHeader("BRIGHTNESS", value: "\(Int(lumMin * 100))% – \(Int(lumMax * 100))%")
                    TwoThumbSlider(
                        low: $lumMin, high: $lumMax,
                        track: LinearGradient(
                            colors: [Color(hex: "#111111"), Color(hex: "#FFFFFF")],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    hintRow(left: "Dark", right: "Light")
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color("AppText").opacity(0.06), radius: 16, y: 6)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color("AppText").opacity(0.07), lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 14)
        .animation(.spring(response: 0.55).delay(0.15), value: animateIn)
    }

    private func paramSection<C: View>(@ViewBuilder content: () -> C) -> some View {
        content().padding(.horizontal, 18).padding(.vertical, 16)
    }

    private var paramDivider: some View {
        Divider().padding(.horizontal, 18).opacity(0.65)
    }

    // Section row header — same typography as everywhere else in the app
    private func rowHeader(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold)).tracking(2.5)
                .foregroundStyle(Color("AppText").opacity(0.28))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "#6C63FF"))
        }
    }

    private func hintRow(left: String, right: String,
                          leftColor: Color = Color("AppText").opacity(0.32),
                          rightColor: Color = Color("AppText").opacity(0.32)) -> some View {
        HStack {
            Text(left).font(.system(size: 11, weight: .semibold)).foregroundStyle(leftColor)
            Spacer()
            Text(right).font(.system(size: 11, weight: .semibold)).foregroundStyle(rightColor)
        }
    }

    private func countBtn(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.2))
                .frame(width: 40, height: 38)
                .background(Color(hex: "#6C63FF").opacity(enabled ? 0.09 : 0))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }.disabled(!enabled)
    }

    // MARK: ── Presets Row ────────────────────────────────────────

    private var presetsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STYLE PRESET")
                .font(.system(size: 10, weight: .bold)).tracking(2.5)
                .foregroundStyle(Color("AppText").opacity(0.28))
                .padding(.leading, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PaletteStylePreset.allCases) { p in
                        Button {
                            withAnimation(.spring(response: 0.38)) {
                                preset = p
                                satMin = p.sliderValues.sMin; satMax = p.sliderValues.sMax
                                lumMin = p.sliderValues.lMin; lumMax = p.sliderValues.lMax
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            presetChip(p)
                        }
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.55).delay(0.2), value: animateIn)
    }

    private func presetChip(_ p: PaletteStylePreset) -> some View {
        let sel = preset == p
        return HStack(spacing: 7) {
            // 3-color mini swatch
            HStack(spacing: 1.5) {
                ForEach(Array(p.chipColors.enumerated()), id: \.offset) { i, c in
                    RoundedRectangle(cornerRadius: i == 0 ? 4 : (i == 2 ? 4 : 0))
                        .fill(c).frame(width: 10, height: 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.2), lineWidth: 0.5))

            Text(p.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(sel ? Color("AppBackground") : Color("AppText").opacity(0.65))
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            Capsule()
                .fill(sel ? Color(hex: "#6C63FF") : Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color("AppText").opacity(sel ? 0 : 0.05), radius: 6, y: 2)
                .overlay(Capsule().stroke(sel ? Color.clear : Color("AppText").opacity(0.09), lineWidth: 1))
        )
        .scaleEffect(sel ? 1.04 : 1.0)
        .animation(.spring(response: 0.28), value: sel)
    }

    // MARK: ── Generate Button ────────────────────────────────────

    private var generateButton: some View {
        Button(action: generate) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.9)
                    Text("Creating \(colorCount) colors…")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                } else if palette == nil {
                    Image(systemName: "sparkles").font(.system(size: 18, weight: .semibold))
                    Text("Generate Palette")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: lockedSlots.isEmpty ? "arrow.counterclockwise" : "lock.rotation")
                        .font(.system(size: 17, weight: .semibold))
                    Text(lockedSlots.isEmpty ? "Regenerate" : "Regenerate · \(lockedSlots.count) locked")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 60)
            .background(
                Group {
                    if isGenerating {
                        RoundedRectangle(cornerRadius: 20).fill(Color("AppText").opacity(0.18))
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: Color(hex: "#6C63FF").opacity(0.35), radius: 14, y: 6)
                    }
                }
            )
        }
        .disabled(isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.55).delay(0.25), value: animateIn)
    }

    // MARK: ── Result Section ─────────────────────────────────────

    @ViewBuilder
    private func resultSection(_ p: ColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            // Header — matches app section label style exactly
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("YOUR PALETTE")
                        .font(.system(size: 10, weight: .bold)).tracking(2.5)
                        .foregroundStyle(Color("AppText").opacity(0.28))
                    Text(p.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText")).kerning(-0.5)
                        .animation(.easeInOut(duration: 0.2), value: p.title)
                }
                Spacer()
                Text("\(p.colors.count) colors")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.4))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color("AppText").opacity(0.07)))
            }

            // Hero strip — same height + style as SavedPaletteDetailView's color header
            HStack(spacing: 0) {
                ForEach(Array(p.colors.enumerated()), id: \.element.hex) { i, c in
                    ZStack(alignment: .topTrailing) {
                        Color(hex: c.hex)
                        if lockedSlots[i] != nil {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                                .padding(5).background(Circle().fill(Color(hex: "#6C63FF"))).padding(8)
                        }
                    }
                }
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color("AppText").opacity(0.08), lineWidth: 1))
            .shadow(color: Color("AppText").opacity(0.1), radius: 14, y: 6)

            // Lock hint
            if lockedSlots.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color(hex: "#6C63FF"))
                    Text("Tap the lock on any color to keep it when regenerating")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(Color("AppText").opacity(0.42))
                    Spacer()
                }
                .padding(.horizontal, 13).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#6C63FF").opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#6C63FF").opacity(0.15), lineWidth: 1))
                )
                .transition(.opacity)
            }

            // Color cards — matches SavedPaletteDetailView's DetailColorRow style exactly
            VStack(spacing: 10) {
                ForEach(Array(p.colors.enumerated()), id: \.element.hex) { i, c in
                    ResultColorRow(
                        color: c, isLocked: lockedSlots[i] != nil,
                        onToggleLock: { toggleLock(i, c) }
                    )
                    .opacity(animateCards ? 1 : 0).offset(y: animateCards ? 0 : 16)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(i) * 0.055), value: animateCards)
                }
            }

            // Save
            Button(action: savePalette) {
                HStack(spacing: 10) {
                    Image(systemName: savedOK ? "checkmark.circle.fill" : "square.and.arrow.down").font(.system(size: 17, weight: .semibold))
                    Text(savedOK ? "Saved to Collection!" : "Save Palette").font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(savedOK ? Color(hex: "#34C759") : Color("AppBackground"))
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(savedOK ? Color(hex: "#34C759").opacity(0.14) : Color("AppText"))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(savedOK ? Color(hex: "#34C759").opacity(0.4) : Color.clear, lineWidth: 1.5))
                )
            }
            .disabled(savedOK || isGenerating)
            .animation(.spring(response: 0.4), value: savedOK)
        }
    }

    // MARK: ── Logic ──────────────────────────────────────────────

    func generate() {
        guard !isGenerating else { return }
        isGenerating = true; animateCards = false; savedOK = false
        let snap   = lockedSlots
        let params = (hMin: hueMin, hMax: hueMax, sMin: satMin, sMax: satMax, lMin: lumMin, lMax: lumMax)
        let count  = colorCount; let style = preset
        Task {
            let result = await doGenerate(count: count, style: style, params: params, locked: snap)
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) { palette = result }
                isGenerating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { withAnimation { animateCards = true } }
            }
        }
    }

    private func doGenerate(count: Int, style: PaletteStylePreset,
                             params: (hMin: Double, hMax: Double, sMin: Double, sMax: Double, lMin: Double, lMax: Double),
                             locked: [Int: GeneratedColor]) async -> ColorPalette? {
        do {
            let response = try await session.respond(to: buildPrompt(count, style, params), generating: ColorPalette.self)
            var colors = response.content.colors

            // 1. Enforce HSL constraints (mathematical guarantee)
            colors = colors.map { c in
                GeneratedColor(name: c.name,
                               hex: HSLEngine.snapToRange(hex: c.hex,
                                                          hMin: params.hMin, hMax: params.hMax,
                                                          sMin: params.sMin, sMax: params.sMax,
                                                          lMin: params.lMin, lMax: params.lMax))
            }
            // 2. Ensure visual diversity
            colors = HSLEngine.enforceDiversity(colors, minDist: 55)
            // 3. Restore locked slots
            for (idx, lc) in locked { if idx < colors.count { colors[idx] = lc } }
            // 4. Exact count
            while colors.count < count { colors.append(colors.last ?? GeneratedColor(name: "Color", hex: "#808080")) }
            return ColorPalette(title: response.content.title, colors: Array(colors.prefix(count)))
        } catch { print("Gen error: \(error)"); return nil }
    }

    private func buildPrompt(_ count: Int, _ style: PaletteStylePreset,
                              _ p: (hMin: Double, hMax: Double, sMin: Double, sMax: Double, lMin: Double, lMax: Double)) -> String {
        let fullHue = abs(p.hMax - p.hMin) > 0.95
        let hueDesc = fullHue ? "any hue — full spectrum" : "\(hueName(p.hMin))–\(hueName(p.hMax)) (\(Int(p.hMin*360))°–\(Int(p.hMax*360))°)"
        return """
        Create a beautiful \(count)-color palette.
        Hue: \(hueDesc)
        Saturation: \(Int(p.sMin*100))%–\(Int(p.sMax*100))%
        Lightness: \(Int(p.lMin*100))%–\(Int(p.lMax*100))%
        Style: \(style.promptDescription)
        Give the palette a poetic 3–5 word title.
        Return EXACTLY \(count) colors with evocative 2–3 word names.
        """
    }

    private func toggleLock(_ i: Int, _ c: GeneratedColor) {
        withAnimation(.spring(response: 0.3)) {
            if lockedSlots[i] != nil { lockedSlots.removeValue(forKey: i) } else { lockedSlots[i] = c }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func savePalette() {
        guard let p = palette else { return }
        let saved = p.colors.map { SavedColor(name: $0.name, hex: $0.hex) }
        modelContext.insert(SavedPalette(title: p.title, colors: saved))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { savedOK = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { dismiss() }
    }

    private func hueName(_ n: Double) -> String {
        switch Int(n * 360) % 360 {
        case 0..<15, 345...360: return "Red"
        case 15..<38:   return "Orange"
        case 38..<55:   return "Amber"
        case 55..<75:   return "Yellow"
        case 75..<150:  return "Green"
        case 150..<185: return "Teal"
        case 185..<220: return "Blue"
        case 220..<260: return "Indigo"
        case 260..<290: return "Violet"
        case 290..<325: return "Magenta"
        case 325..<345: return "Pink"
        default:        return "Color"
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - RESULT COLOR ROW
// Matches SavedPaletteDetailView's DetailColorRow exactly
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct ResultColorRow: View {
    let color: GeneratedColor
    let isLocked: Bool
    let onToggleLock: () -> Void
    @State private var copied = false

    private var rgb: (r: Int, g: Int, b: Int) { HSLEngine.hexToRGB(color.hex) }
    private var hsl: (h: Int, s: Int, l: Int) {
        let (h, s, l) = HSLEngine.hexToHSL(color.hex)
        return (Int(h), Int(s), Int(l))
    }

    var body: some View {
        HStack(spacing: 14) {
            // Swatch — same proportions as DetailColorRow
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: color.hex))
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isLocked ? Color(hex: "#6C63FF").opacity(0.55) : Color("AppText").opacity(0.08),
                                lineWidth: isLocked ? 2.5 : 1)
                )
                .shadow(color: Color(hex: color.hex).opacity(0.22), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 5) {
                Text(color.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText")).lineLimit(1)
                // HEX / RGB / HSL pills — same style as the app's info chips
                HStack(spacing: 6) {
                    infoPill("HEX", color.hex.uppercased())
                    infoPill("RGB", "\(rgb.r) \(rgb.g) \(rgb.b)")
                    infoPill("HSL", "\(hsl.h)° \(hsl.s)% \(hsl.l)%")
                }
            }

            Spacer(minLength: 0)

            // Copy
            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { withAnimation { copied = false } }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.38))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(copied ? Color(hex: "#34C759").opacity(0.1) : Color("AppText").opacity(0.07)))
            }

            // Lock
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.35))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isLocked ? Color(hex: "#6C63FF").opacity(0.14) : Color("AppText").opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isLocked ? Color(hex: "#6C63FF").opacity(0.38) : Color.clear, lineWidth: 1))
                    )
            }
            .scaleEffect(isLocked ? 1.07 : 1.0)
            .animation(.spring(response: 0.25), value: isLocked)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color("AppText").opacity(isLocked ? 0.07 : 0.04), radius: isLocked ? 12 : 7, y: 3)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(isLocked ? Color(hex: "#6C63FF").opacity(0.2) : Color("AppText").opacity(0.06), lineWidth: 1))
        )
        .animation(.spring(response: 0.3), value: isLocked)
    }

    private func infoPill(_ label: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 8, weight: .black)).foregroundStyle(Color("AppText").opacity(0.28))
            Text(value).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(Color("AppText").opacity(0.58)).lineLimit(1)
        }
        .padding(.horizontal, 5).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(Color("AppText").opacity(0.05)))
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - HUE RANGE SLIDER
// ═════════════════════════════════════════════════════════════

struct HueRangeSlider: View {
    @Binding var low: Double
    @Binding var high: Double
    @State private var drag: Which = .none
    enum Which { case low, high, none }
    private let D: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: stride(from: 0.0, through: 1.0, by: 1.0/12)
                        .map { Color(hue: $0, saturation: 1, brightness: 0.88) },
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 12).clipShape(Capsule()).frame(maxHeight: .infinity)
                .shadow(color: .black.opacity(0.07), radius: 2, y: 1)

                // Dimmed unselected overlay
                HStack(spacing: 0) {
                    Color("AppBackground").opacity(0.6).frame(width: max(0, low * W))
                    Color.clear.frame(width: max(0, (high - low) * W))
                    Color("AppBackground").opacity(0.6)
                }
                .frame(height: 12).clipShape(Capsule()).frame(maxHeight: .infinity)

                hueThumb(low).position(x: low * W, y: geo.size.height / 2)
                hueThumb(high).position(x: high * W, y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { v in
                    let x = max(0, min(1, v.location.x / W))
                    if drag == .none { drag = abs(v.location.x - low*W) <= abs(v.location.x - high*W) ? .low : .high }
                    if drag == .low  { low  = max(0,        min(high - 0.01, x)) }
                    if drag == .high { high = max(low+0.01, min(1, x)) }
                }
                .onEnded { _ in drag = .none; UIImpactFeedbackGenerator(style: .light).impactOccurred() })
        }
        .frame(height: D + 8)
    }

    private func hueThumb(_ hue: Double) -> some View {
        ZStack {
            Circle().fill(.white).frame(width: D, height: D).shadow(color: .black.opacity(0.18), radius: 5, y: 2)
            Circle().fill(Color(hue: hue, saturation: 0.88, brightness: 0.9)).frame(width: D - 10, height: D - 10)
            Circle().strokeBorder(.white, lineWidth: 2.5).frame(width: D, height: D)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - TWO-THUMB RANGE SLIDER
// ═════════════════════════════════════════════════════════════

struct TwoThumbSlider: View {
    @Binding var low: Double
    @Binding var high: Double
    let track: LinearGradient
    @State private var drag: Which = .none
    enum Which { case low, high, none }
    private let D: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            ZStack(alignment: .leading) {
                track.frame(height: 12).clipShape(Capsule()).frame(maxHeight: .infinity)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                HStack(spacing: 0) {
                    Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8).frame(width: max(0, low * W))
                    Color.clear.frame(width: max(0, (high - low) * W))
                    Color(uiColor: .secondarySystemGroupedBackground).opacity(0.8)
                }
                .frame(height: 12).clipShape(Capsule()).frame(maxHeight: .infinity)
                thumb(drag == .low).position(x: low * W, y: geo.size.height / 2)
                thumb(drag == .high).position(x: high * W, y: geo.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { v in
                    let x = max(0, min(1, v.location.x / W))
                    if drag == .none { drag = abs(v.location.x - low*W) <= abs(v.location.x - high*W) ? .low : .high }
                    if drag == .low  { low  = max(0,        min(high - 0.02, x)) }
                    if drag == .high { high = max(low+0.02, min(1, x)) }
                }
                .onEnded { _ in drag = .none; UIImpactFeedbackGenerator(style: .light).impactOccurred() })
        }
        .frame(height: D + 8)
    }

    private func thumb(_ active: Bool) -> some View {
        ZStack {
            Circle().fill(.white).frame(width: D, height: D)
                .shadow(color: .black.opacity(active ? 0.2 : 0.1), radius: active ? 7 : 4, y: 2)
            Circle().strokeBorder(Color(hex: "#6C63FF"), lineWidth: active ? 3 : 2).frame(width: D, height: D)
        }
        .scaleEffect(active ? 1.12 : 1.0).animation(.spring(response: 0.2), value: active)
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - HSL ENGINE
// ═════════════════════════════════════════════════════════════

enum HSLEngine {
    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0; Scanner(string: h).scanHexInt64(&v)
        return (Int((v>>16)&0xFF), Int((v>>8)&0xFF), Int(v&0xFF))
    }

    static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double) {
        let c = hexToRGB(hex)
        let r = Double(c.r)/255, g = Double(c.g)/255, b = Double(c.b)/255
        let mx = max(r,g,b), mn = min(r,g,b), l = (mx+mn)/2
        var h = 0.0, s = 0.0
        if mx != mn {
            let d = mx-mn; s = l > 0.5 ? d/(2-mx-mn) : d/(mx+mn)
            if      mx==r { h = (g-b)/d + (g<b ? 6:0) }
            else if mx==g { h = (b-r)/d + 2 }
            else           { h = (r-g)/d + 4 }
            h /= 6
        }
        return (h*360, s*100, l*100)
    }

    static func hslToHex(h: Double, s: Double, l: Double) -> String {
        let H = (h/360).truncatingRemainder(dividingBy: 1)
        let S = max(0, min(1, s/100)), L = max(0, min(1, l/100))
        if S == 0 { let v = Int(L*255); return String(format:"#%02X%02X%02X",v,v,v) }
        func hue2rgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t; if t<0{t+=1}; if t>1{t-=1}
            if t<1/6{return p+(q-p)*6*t}; if t<0.5{return q}
            if t<2/3{return p+(q-p)*(2/3-t)*6}; return p
        }
        let q = L<0.5 ? L*(1+S) : L+S-L*S, p = 2*L-q
        return String(format:"#%02X%02X%02X",
                      Int(hue2rgb(p,q,H+1/3)*255), Int(hue2rgb(p,q,H)*255), Int(hue2rgb(p,q,H-1/3)*255))
    }

    static func snapToRange(hex: String, hMin: Double, hMax: Double,
                             sMin: Double, sMax: Double, lMin: Double, lMax: Double) -> String {
        var (h, s, l) = hexToHSL(hex)
        s = max(sMin*100, min(sMax*100, s)); l = max(lMin*100, min(lMax*100, l))
        if abs(hMax - hMin) <= 0.98 {
            let lo = hMin*360, hi = hMax*360
            if hi >= lo { if h < lo || h > hi { h = circ(h, lo) < circ(h, hi) ? lo : hi } }
            else { if h > hi && h < lo { h = circ(h, lo) < circ(h, hi) ? lo : hi } }
        }
        return hslToHex(h: h, s: s, l: l)
    }

    @available(iOS 26.0, *)
    static func enforceDiversity(_ colors: [GeneratedColor], minDist: Double) -> [GeneratedColor] {
        var r = colors
        for _ in 0..<6 {
            var changed = false
            for i in 0..<r.count {
                for j in (i+1)..<r.count {
                    if dist(r[i].hex, r[j].hex) < minDist {
                        var (h, s, l) = hexToHSL(r[j].hex)
                        l = l > 50 ? max(5, l-18) : min(95, l+18)
                        if #available(iOS 26.0, *) {
                            r[j] = GeneratedColor(name: r[j].name, hex: hslToHex(h: h, s: s, l: l))
                        } else {
                            // Fallback on earlier versions
                        }
                        changed = true
                    }
                }
            }
            if !changed { break }
        }
        return r
    }

    private static func circ(_ a: Double, _ b: Double) -> Double { let d = abs(a-b); return min(d, 360-d) }
    static func dist(_ a: String, _ b: String) -> Double {
        let ra = hexToRGB(a), rb = hexToRGB(b)
        let dr = Double(ra.r-rb.r), dg = Double(ra.g-rb.g), db = Double(ra.b-rb.b)
        return sqrt(0.299*dr*dr + 0.587*dg*dg + 0.114*db*db)
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - PRESET CHIP  (kept for other views)
// ═════════════════════════════════════════════════════════════

struct PresetChip: View {
    let preset: ColorPreset; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Circle().fill(Color(hex: preset.hex)).frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color("AppText").opacity(0.15), lineWidth: 1))
                Text(preset.name).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color("AppText") : Color("AppText").opacity(0.55))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule()
                .fill(isSelected ? Color("AppText").opacity(0.15) : Color("AppText").opacity(0.06))
                .overlay(Capsule().stroke(isSelected ? Color("AppText").opacity(0.3) : Color("AppText").opacity(0.08), lineWidth: 1)))
        }
    }
}

struct ColorPreset {
    let name: String; let hex: String
    static let all: [ColorPreset] = [
        .init(name:"Violet",hex:"#6C63FF"), .init(name:"Coral",hex:"#FF6B6B"),
        .init(name:"Ocean",hex:"#0EA5E9"),  .init(name:"Sage",hex:"#6DBF8A"),
        .init(name:"Amber",hex:"#F59E0B"),  .init(name:"Rose",hex:"#F43F5E"),
        .init(name:"Slate",hex:"#64748B"),  .init(name:"Mint",hex:"#2DD4BF"),
    ]
}
