import SwiftUI
import SwiftData

// ─────────────────────────────────────────────────────────────
// MARK: — XCODE SETUP (do this first, then paste this file)
// ─────────────────────────────────────────────────────────────
// 1. In Xcode → select your app TARGET → "General" tab
// 2. Change "Minimum Deployments" from iOS 26 → iOS 17.0
// 3. Also update Models.swift (see note at bottom of this file)
// ─────────────────────────────────────────────────────────────

import FoundationModels   // Still imported — @available guards prevent it running on older OS


// ═════════════════════════════════════════════════════════════
// MARK: - AVAILABILITY GATE VIEW
// This is the ContentView HomeView already calls.
// It decides which experience to show based on the OS version.
// ═════════════════════════════════════════════════════════════

struct ContentView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            AIGeneratorView()
        } else {
            AIUnavailableView()
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - AI UNAVAILABLE VIEW
// Shown to users on iOS 17–25. Matches the dark studio aesthetic.
// Explains the requirement clearly and positively.
// ═════════════════════════════════════════════════════════════

struct AIUnavailableView: View {
    @Environment(\.dismiss) private var dismiss

    private let availableFeatures: [(icon: String, color: String, title: String, subtitle: String)] = [
        ("paintbrush.fill",          "#FF8C42", "Manual Studio",    "Build any palette by hand"),
        ("photo.on.rectangle.angled","#2DD4BF", "Image Studio",     "Extract colors from photos"),
        ("sparkle.magnifyingglass",  "#F59E0B", "Color Explorer",   "Discover any color's harmonies"),
        ("square.and.arrow.down",    "#6DBF8A", "Export & Share",   "11 sticker designs per color"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D0D").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Hero ─────────────────────────────────
                        VStack(spacing: 20) {
                            // Unavailable icon
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(hex: "#6C63FF").opacity(0.4),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 20)

                                Circle()
                                    .stroke(Color(hex: "#6C63FF").opacity(0.2), lineWidth: 1)
                                    .frame(width: 80, height: 80)

                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "#6C63FF").opacity(0.15))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundStyle(Color(hex: "#6C63FF"))
                                }
                            }

                            VStack(spacing: 10) {
                                Text("AI STUDIO")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(3)
                                    .foregroundStyle(Color(hex: "#6C63FF"))

                                Text("Requires\niOS 26")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .kerning(-0.5)

                                Text("AI palette generation uses Apple Intelligence,\nwhich is available on iOS 26 and later.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(.top, 48)

                        // ── Current iOS chip ──────────────────────
                        HStack(spacing: 8) {
                            Image(systemName: "iphone")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Your device is running iOS \(currentIOSVersion)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color.white.opacity(0.35))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.top, 24)

                        // ── How to get it ─────────────────────────
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOW TO GET IT")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2.5)
                                .foregroundStyle(Color.white.opacity(0.28))

                            VStack(spacing: 10) {
                                UpgradeStepRow(
                                    number: "1",
                                    text: "Update your iPhone to iOS 26 via Settings → General → Software Update"
                                )
                                UpgradeStepRow(
                                    number: "2",
                                    text: "Enable Apple Intelligence in Settings → Apple Intelligence & Siri"
                                )
                                UpgradeStepRow(
                                    number: "3",
                                    text: "Come back to AWBY — AI generation will unlock automatically"
                                )
                            }
                        }
                        .padding(.top, 36)
                        .padding(.horizontal, 22)

                        // ── Compatible features ───────────────────
                        VStack(alignment: .leading, spacing: 14) {
                            Text("AVAILABLE ON YOUR DEVICE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2.5)
                                .foregroundStyle(Color.white.opacity(0.28))

                            VStack(spacing: 10) {
                                ForEach(availableFeatures, id: \.title) { feature in
                                    HStack(spacing: 14) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: feature.color))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: feature.icon)
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(feature.title)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text(feature.subtitle)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(Color.white.opacity(0.4))
                                        }
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(Color(hex: "#34C759"))
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.top, 32)
                        .padding(.horizontal, 22)

                        // ── Close button ──────────────────────────
                        Button { dismiss() } label: {
                            Text("Got It")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#0D0D0D"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 36)
                        .padding(.bottom, 52)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.09))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color(hex: "#0D0D0D"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var currentIOSVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion)"
    }
}

// MARK: - Upgrade Step Row

private struct UpgradeStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: "#6C63FF"))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(hex: "#6C63FF").opacity(0.15))
                        .overlay(Circle().stroke(Color(hex: "#6C63FF").opacity(0.3), lineWidth: 1))
                )
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - AI GENERATOR VIEW  (iOS 26+ ONLY)
// This is the full AI experience — renamed from ContentView.
// The @available annotation prevents it compiling on older OS.
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct AIGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: Color = Color(hex: "#6C63FF")
    @State private var variations: [ColorPalette] = []
    @State private var activeVariation: Int = 0
    @State private var lockedSlots: [Int: GeneratedColor] = [:]
    @State private var isGenerating = false
    @State private var savedSuccessfully = false
    @State private var animateCards = false
    @State private var pulseRing = false
    @State private var dragOffset: CGFloat = 0

    let sessions: [LanguageModelSession] = {
        let s0 = LanguageModelSession(instructions: """
        You are a bold typographic designer who creates HIGH-CONTRAST editorial palettes.
        STRICT SLOT RULES:
        • Slot 1 (DARK ANCHOR): Brightness 5–18%. Near-black with a hint of color.
        • Slot 2 (VIBRANT HERO): Saturation 85–100%, Brightness 55–75%. The loudest color.
        • Slot 3 (ACCENT POP): COMPLETELY DIFFERENT hue from Slot 2. Saturation > 80%.
        • Slot 4 (LIGHT NEUTRAL): Brightness 88–97%, Saturation < 20%.
        • Slot 5 (MID BRIDGE): Saturation 50–70%, Brightness 35–55%.
        FORBIDDEN: Any two slots sharing a hue within 40° of each other.
        """)
        let s1 = LanguageModelSession(instructions: """
        You are a fashion-forward colorist known for UNEXPECTED, rule-breaking combinations.
        STRICT SLOT RULES:
        • Slot 1 (WARM TONE): Hue 0°–60°. Medium-high saturation.
        • Slot 2 (COOL SHOCK): Hue 180°–260°. Must clash beautifully with Slot 1.
        • Slot 3 (EARTH GROUNDING): Saturation 10–30%. Beige, clay, stone family.
        • Slot 4 (NEON SURPRISE): Saturation > 90%, Brightness > 80%.
        • Slot 5 (DARK DEPTH): Brightness < 22%.
        FORBIDDEN: Slots 1, 2, and 4 cannot share a hue family.
        """)
        let s2 = LanguageModelSession(instructions: """
        You are a luxury brand color director creating SOPHISTICATED TONAL palettes.
        STRICT SLOT RULES:
        • Slot 1 (DEEP SHADOW): Brightness 8–20%, Saturation 40–70%.
        • Slot 2 (RICH MIDTONE): Brightness 35–50%, Saturation 60–85%.
        • Slot 3 (LUMINOUS HIGHLIGHT): Brightness 80–92%, Saturation 15–40%.
        • Slot 4 (COMPLEMENTARY TWIST): Jump 150°–210° on hue wheel. Saturation 70–90%.
        • Slot 5 (METALLIC NEUTRAL): Saturation 5–15%, Brightness 55–78%.
        CRITICAL: Slots 1, 2, and 3 must share the same dominant hue (within 30°).
        """)
        return [s0, s1, s2]
    }()

    var currentPalette: ColorPalette? {
        guard activeVariation < variations.count else { return nil }
        return variations[activeVariation]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        colorPickerHero.padding(.top, 32)
                        generateButton.padding(.top, 28)
                        if !variations.isEmpty {
                            variationsSection
                                .padding(.top, 36)
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
                            .foregroundStyle(Color("AppText").opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color("AppText").opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI STUDIO")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "#6C63FF"))
                Text("Generate\nPalette")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
            }
            Spacer()
           /* ZStack {
                Circle()
                    .fill(RadialGradient(colors: [selectedColor.opacity(0.55), .clear],
                                        center: .center, startRadius: 0, endRadius: 50))
                    .frame(width: 100, height: 100).blur(radius: 18)
                Circle()
                    .stroke(selectedColor.opacity(0.28), lineWidth: 1)
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseRing ? 1.35 : 1.0)
                    .opacity(pulseRing ? 0 : 0.8)
                    .animation(isGenerating
                               ? .easeOut(duration: 1.1).repeatForever(autoreverses: false)
                               : .default, value: pulseRing)
                Circle()
                    .fill(selectedColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }*/
        }
        .padding(.top, 20)
    }

    // MARK: - Color Picker Hero

    private var colorPickerHero: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(selectedColor)
                    .frame(height: 150)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.1), lineWidth: 1))
                VStack(spacing: 6) {
                    Text(selectedColor.toHex() ?? "#000000")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                    Text("Base Color")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }
            HStack(spacing: 14) {
                ColorPicker("", selection: $selectedColor).labelsHidden()
                    .scaleEffect(1.3).frame(width: 44, height: 44)
                Text("Tap the circle to pick any color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.5))
                Spacer()
            }.padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK PRESETS")
                    .font(.system(size: 10, weight: .semibold)).tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.4))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ColorPreset.all, id: \.hex) { preset in
                            PresetChip(
                                preset: preset,
                                isSelected: (selectedColor.toHex() ?? "").lowercased() == preset.hex.lowercased()
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedColor = Color(hex: preset.hex) }
                            }
                        }
                    }
                }
            }.padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color("AppText").opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generateAllVariations) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.85)
                } else {
                    Image(systemName: lockedSlots.isEmpty ? "sparkles" : "lock.fill")
                        .font(.system(size: 17, weight: .semibold))
                }
                Group {
                    if isGenerating { Text("Crafting 3 unique palettes…") }
                    else if lockedSlots.isEmpty { Text("Generate with AI") }
                    else { Text("Regenerate · \(lockedSlots.count) color\(lockedSlots.count == 1 ? "" : "s") locked") }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                Group {
                    if isGenerating {
                        RoundedRectangle(cornerRadius: 18).fill(Color("AppText").opacity(0.1))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                                 startPoint: .leading, endPoint: .trailing))
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AppText").opacity(isGenerating ? 0.15 : 0), lineWidth: 1))
        }
        .disabled(isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
    }

    // MARK: - Variations Section

    private var variationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            let labels = ["Bold Contrast", "Unexpected Mix", "Tonal Depth"]
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VARIATION \(activeVariation + 1) OF 3")
                        .font(.system(size: 10, weight: .semibold)).tracking(2.5)
                        .foregroundStyle(Color("AppText").opacity(0.4))
                    Text(currentPalette?.title ?? (activeVariation < labels.count ? labels[activeVariation] : ""))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .animation(.easeInOut(duration: 0.2), value: activeVariation)
                }
                Spacer()
                Button(action: generateAllVariations) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("AppText").opacity(0.5))
                        .frame(width: 36, height: 36)
                        .background(Color("AppText").opacity(0.08))
                        .clipShape(Circle())
                }.disabled(isGenerating)
            }
            if variations.count == 3 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(zip(0..., labels)), id: \.0) { i, label in
                            Button {
                                withAnimation(.spring(response: 0.4)) { activeVariation = i }
                                triggerCardAnimation()
                            } label: {
                                Text(label)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(i == activeVariation ? Color("AppBackground") : Color("AppText").opacity(0.5))
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(Capsule().fill(i == activeVariation ? Color("AppText") : Color("AppText").opacity(0.08)))
                            }
                        }
                    }
                }
            }
            variationCarousel
            if lockedSlots.isEmpty { lockHintBanner.transition(.opacity) }
            if let palette = currentPalette { colorCardsList(palette: palette) }
            saveButton
        }
    }

    // MARK: - Variation Carousel

    private var variationCarousel: some View {
        VStack(spacing: 12) {
            ZStack {
                ForEach(Array(variations.enumerated()), id: \.offset) { index, palette in
                    stripView(palette: palette, index: index)
                        .offset(x: xOffset(for: index))
                        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: activeVariation)
                        .animation(.interactiveSpring(response: 0.28), value: dragOffset)
                }
            }
            .frame(height: 72).clipped()
            .gesture(DragGesture(minimumDistance: 10)
                .onChanged { dragOffset = $0.translation.width }
                .onEnded { value in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if value.translation.width < -55, activeVariation < variations.count - 1 {
                            activeVariation += 1; UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } else if value.translation.width > 55, activeVariation > 0 {
                            activeVariation -= 1; UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        dragOffset = 0
                    }
                    triggerCardAnimation()
                })
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<max(1, variations.count), id: \.self) { i in
                        Capsule()
                            .fill(i == activeVariation ? Color("AppText") : Color("AppText").opacity(0.22))
                            .frame(width: i == activeVariation ? 22 : 6, height: 6)
                            .animation(.spring(response: 0.32), value: activeVariation)
                    }
                }
                Spacer()
                if variations.count > 1 {
                    Text("Swipe to compare")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.35))
                }
            }
        }
    }

    private func stripView(palette: ColorPalette, index: Int) -> some View {
        let isActive = index == activeVariation
        return HStack(spacing: 3) {
            ForEach(Array(palette.colors.enumerated()), id: \.element.hex) { slotIdx, c in
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color(hex: c.hex))
                    if lockedSlots[slotIdx] != nil {
                        RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                        Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white).shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity).frame(height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(isActive ? Color("AppText").opacity(0.22) : Color("AppText").opacity(0.06), lineWidth: 1.5))
        .scaleEffect(isActive ? 1.0 : 0.94)
        .opacity(isActive ? 1.0 : 0.45)
    }

    private func xOffset(for index: Int) -> CGFloat {
        CGFloat(index - activeVariation) * (UIScreen.main.bounds.width - 44) + dragOffset
    }

    // MARK: - Lock Hint

    private var lockHintBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#6C63FF"))
            Text("Tap \(Image(systemName: "lock.open")) on any color to keep it when regenerating")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(Color("AppText").opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#6C63FF").opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#6C63FF").opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Color Cards List

    private func colorCardsList(palette: ColorPalette) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(palette.colors.enumerated()), id: \.element.hex) { index, color in
                LockableColorCard(
                    color: color, index: index,
                    isLocked: lockedSlots[index] != nil,
                    onToggleLock: { toggleLock(at: index, color: color) }
                )
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 16)
                .animation(.spring(response: 0.48, dampingFraction: 0.8).delay(Double(index) * 0.055), value: animateCards)
            }
        }
        .onChange(of: activeVariation) { _ in triggerCardAnimation() }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: savePalette) {
            HStack(spacing: 10) {
                Image(systemName: savedSuccessfully ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))
                Text(savedSuccessfully ? "Saved!" : "Save This Palette")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(savedSuccessfully ? Color(hex: "#34C759") : Color("AppBackground"))
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(savedSuccessfully ? Color(hex: "#34C759").opacity(0.15) : Color("AppText"))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(savedSuccessfully ? Color(hex: "#34C759").opacity(0.4) : Color.clear, lineWidth: 1.5))
            )
        }
        .disabled(currentPalette == nil || savedSuccessfully || isGenerating)
        .animation(.spring(response: 0.4), value: savedSuccessfully)
    }

    // MARK: - Generation Logic

    func generateAllVariations() {
        guard !isGenerating else { return }
        isGenerating = true; animateCards = false; pulseRing = true; savedSuccessfully = false
        let snapshot = lockedSlots
        let baseHex = selectedColor.toHex() ?? "#6C63FF"
        Task {
            async let r0 = generateOne(session: sessions[0], prompt: VariationPromptBuilder.boldContrast(baseHex: baseHex, locked: snapshot), locked: snapshot)
            async let r1 = generateOne(session: sessions[1], prompt: VariationPromptBuilder.unexpectedMix(baseHex: baseHex, locked: snapshot), locked: snapshot)
            async let r2 = generateOne(session: sessions[2], prompt: VariationPromptBuilder.tonalDepth(baseHex: baseHex, locked: snapshot), locked: snapshot)
            let results = await [r0, r1, r2].compactMap { $0 }
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) { variations = results; activeVariation = 0 }
                isGenerating = false; pulseRing = false; triggerCardAnimation()
            }
        }
    }

    private func generateOne(session: LanguageModelSession, prompt: String, locked: [Int: GeneratedColor]) async -> ColorPalette? {
        do {
            let response = try await session.respond(to: prompt, generating: ColorPalette.self)
            var palette = response.content
            let diversified = ColorDiversityEnforcer.enforce(palette.colors, lockedSlots: locked, minimumDistance: 72)
            var final = diversified
            for (idx, lockedColor) in locked { if idx < final.count { final[idx] = lockedColor } }
            palette = ColorPalette(title: palette.title, colors: final)
            return palette
        } catch { print("Generation error: \(error)"); return nil }
    }

    private func toggleLock(at index: Int, color: GeneratedColor) {
        withAnimation(.spring(response: 0.3)) {
            if lockedSlots[index] != nil { lockedSlots.removeValue(forKey: index) }
            else { lockedSlots[index] = color }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func savePalette() {
        guard let p = currentPalette else { return }
        let saved = p.colors.map { SavedColor(name: $0.name, hex: $0.hex) }
        modelContext.insert(SavedPalette(title: p.title, colors: saved))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { savedSuccessfully = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }

    private func triggerCardAnimation() {
        animateCards = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation { animateCards = true }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - LOCKABLE COLOR CARD  (iOS 26+)
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
struct LockableColorCard: View {
    let color: GeneratedColor
    let index: Int
    let isLocked: Bool
    let onToggleLock: () -> Void
    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14).fill(Color(hex: color.hex))
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isLocked ? Color.white.opacity(0.85) : Color.white.opacity(0.1),
                                lineWidth: isLocked ? 2.5 : 1))
                if isLocked {
                    Circle().fill(Color(hex: "#6C63FF")).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "lock.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.white))
                        .offset(x: 5, y: 5).transition(.scale.combined(with: .opacity))
                }
            }.animation(.spring(response: 0.28), value: isLocked)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(color.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color("AppText")).lineLimit(1)
                    if isLocked {
                        Text("LOCKED").font(.system(size: 8, weight: .black)).tracking(0.8)
                            .foregroundStyle(Color(hex: "#A78BFA"))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#6C63FF").opacity(0.22)))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(color.hex.uppercased()).font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.45))
            }
            Spacer()
            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.4))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(copied ? Color(hex: "#34C759").opacity(0.13) : Color("AppText").opacity(0.07)))
            }
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(hex: "#A78BFA") : Color("AppText").opacity(0.32))
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10)
                        .fill(isLocked ? Color(hex: "#6C63FF").opacity(0.2) : Color("AppText").opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(isLocked ? Color(hex: "#6C63FF").opacity(0.45) : Color.clear, lineWidth: 1)))
            }
            .scaleEffect(isLocked ? 1.08 : 1.0)
            .animation(.spring(response: 0.25), value: isLocked)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isLocked ? Color(hex: "#6C63FF").opacity(0.07) : Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(isLocked ? Color(hex: "#6C63FF").opacity(0.28) : Color("AppText").opacity(0.07), lineWidth: 1))
        )
        .animation(.spring(response: 0.3), value: isLocked)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - VARIATION PROMPT BUILDER  (iOS 26+)
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
enum VariationPromptBuilder {
    static func boldContrast(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        """
        CREATIVE BRIEF: HIGH-CONTRAST EDITORIAL. Base color: \(baseHex).
        Slot 1: Near-black anchor (brightness 5–18%). Slot 2: Loud saturated hero (sat 85–100%, bri 55–75%).
        Slot 3: Sharp contrast accent, hue >90° different from Slot 2. Slot 4: Near-white neutral (bri 88–98%, sat <18%).
        Slot 5: \(baseHex) — include exactly. Names: evocative, specific (e.g. "Void Ink", "Ghost Linen").
        \(lockedNote(locked))
        """
    }
    static func unexpectedMix(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        """
        CREATIVE BRIEF: RULE-BREAKING COMBINATION. Base color: \(baseHex).
        Slot 1: Warm (hue 0°–55°). Slot 2: Cool shock (hue 195°–255°). Slot 3: Desaturated earthy (sat 5–22%).
        Slot 4: One electric neon pop (sat>88%, bri>78%). Slot 5: \(baseHex) — include exactly.
        No two of Slots 1–4 within 50° hue of each other. Name like perfume or sneaker colorway.
        \(lockedNote(locked))
        """
    }
    static func tonalDepth(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        """
        CREATIVE BRIEF: LUXURIOUS TONAL. Base color: \(baseHex).
        Slot 1: Darkest expression of \(baseHex) hue (bri 8–20%). Slot 2: \(baseHex) exactly.
        Slot 3: Lighter same hue (bri 78–92%, sat 18–40%). Slot 4: Complementary accent (150°–200° hue jump, sat 65–90%).
        Slot 5: Warm or cool mid-gray (sat 4–12%, bri 52–74%). Slots 1–3 share dominant hue within 25°.
        \(lockedNote(locked))
        """
    }
    private static func lockedNote(_ locked: [Int: GeneratedColor]) -> String {
        guard !locked.isEmpty else { return "" }
        let lines = locked.sorted { $0.key < $1.key }.map {
            "Color \($0.key + 1) is LOCKED — use exactly \($0.value.hex) named '\($0.value.name)'."
        }.joined(separator: "\n")
        return "LOCKED COLORS (do not change):\n\(lines)"
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR DIVERSITY ENFORCER  (iOS 26+)
// ═════════════════════════════════════════════════════════════

@available(iOS 26.0, *)
enum ColorDiversityEnforcer {
    static func enforce(_ colors: [GeneratedColor], lockedSlots: [Int: GeneratedColor], minimumDistance: Double) -> [GeneratedColor] {
        var result = colors
        for _ in 0..<8 {
            var replaced = false
            for i in 0..<result.count {
                if lockedSlots[i] != nil { continue }
                for j in (i + 1)..<result.count {
                    if lockedSlots[j] != nil { continue }
                    if rgbDist(result[i].hex, result[j].hex) < minimumDistance {
                        let replacement = deriveContrasting(against: result.map(\.hex), avoidIndex: j,
                                                            locked: Set(lockedSlots.values.map(\.hex)))
                        result[j] = GeneratedColor(name: result[j].name, hex: replacement)
                        replaced = true
                    }
                }
            }
            if !replaced { break }
        }
        return result
    }
    private static func deriveContrasting(against hexes: [String], avoidIndex: Int, locked: Set<String>) -> String {
        let steps: [Double] = stride(from: 0, to: 360, by: 15).map { $0 }
        var best = "#808080"; var bestDist = 0.0
        for h in steps {
            for s in [0.9, 0.65, 0.3] as [Double] {
                for b in [0.85, 0.35] as [Double] {
                    let c = hsbHex(h, s, b)
                    if locked.contains(c) { continue }
                    let existing = hexes.enumerated().filter { $0.offset != avoidIndex }.map(\.element)
                    let d = existing.map { rgbDist(c, $0) }.min() ?? 0
                    if d > bestDist { bestDist = d; best = c }
                }
            }
        }
        return best
    }
    private static func rgbDist(_ a: String, _ b: String) -> Double {
        let ra = hex2rgb(a), rb = hex2rgb(b)
        let dr = Double(ra.r - rb.r), dg = Double(ra.g - rb.g), db = Double(ra.b - rb.b)
        return sqrt(0.299*dr*dr + 0.587*dg*dg + 0.114*db*db)
    }
    private static func hex2rgb(_ h: String) -> (r: Int, g: Int, b: Int) {
        let s = h.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        return (Int((v>>16)&0xFF), Int((v>>8)&0xFF), Int(v&0xFF))
    }
    private static func hsbHex(_ h: Double, _ s: Double, _ b: Double) -> String {
        let c=b*s, x=c*(1-abs((h/60).truncatingRemainder(dividingBy:2)-1)), m=b-c
        var t:(Double,Double,Double)
        switch h { case 0..<60:t=(c,x,0); case 60..<120:t=(x,c,0); case 120..<180:t=(0,c,x)
            case 180..<240:t=(0,x,c); case 240..<300:t=(x,0,c); default:t=(c,0,x) }
        return String(format:"#%02X%02X%02X",Int((t.0+m)*255),Int((t.1+m)*255),Int((t.2+m)*255))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PRESET CHIP & COLOR PRESET  (all iOS versions)
// ═════════════════════════════════════════════════════════════

struct PresetChip: View {
    let preset: ColorPreset
    let isSelected: Bool
    let action: () -> Void
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
                .overlay(Capsule().stroke(
                    isSelected ? Color("AppText").opacity(0.3) : Color("AppText").opacity(0.08), lineWidth: 1)))
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


// ─────────────────────────────────────────────────────────────
// MARK: - MODELS.SWIFT — CHANGES NEEDED
// ─────────────────────────────────────────────────────────────
// In your Models.swift file, add @available(iOS 26.0, *) to
// the two @Generable structs:
//
//   @available(iOS 26.0, *)
//   @Generable(description: "A single color in a palette...")
//   struct GeneratedColor: Codable { ... }
//
//   @available(iOS 26.0, *)
//   @Generable(description: "A color palette inspired by...")
//   struct ColorPalette: Codable { ... }
//
// The SwiftData models (SavedPalette, SavedColor) do NOT need
// @available — they work on all iOS versions.
// ─────────────────────────────────────────────────────────────
