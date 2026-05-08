import SwiftUI
import SwiftData
import FoundationModels

// MARK: - Main AI Generator View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // ── Base color ─────────────────────────────────────────────
    @State private var selectedColor: Color = Color(hex: "#6C63FF")

    // ── Variations ─────────────────────────────────────────────
    @State private var variations: [ColorPalette] = []
    @State private var activeVariation: Int = 0

    // ── Lock state ─────────────────────────────────────────────
    // Value = exact GeneratedColor snapshot taken at lock time.
    // AI output for locked slots is always discarded and overwritten.
    @State private var lockedSlots: [Int: GeneratedColor] = [:]

    // ── UI state ───────────────────────────────────────────────
    @State private var isGenerating = false
    @State private var savedSuccessfully = false
    @State private var animateCards = false
    @State private var pulseRing = false
    @State private var dragOffset: CGFloat = 0

    // ── 3 sessions — each with a radically different creative identity ──
    // Session 0: maximum contrast — dark anchor + vibrant mid + bright pop
    // Session 1: unexpected combinations — hues that shouldn't work together but do
    // Session 2: tonal sophistication — one hue family with dramatic brightness range
    let sessions: [LanguageModelSession] = {
        let s0 = LanguageModelSession(instructions: """
        You are a bold typographic designer who creates HIGH-CONTRAST editorial palettes.

        STRICT SLOT RULES — you MUST follow these for every generation:
        • Slot 1 (DARK ANCHOR): Brightness 5–18%. Near-black but with a hint of color. e.g. #0D0A1A, #1A0A0A, #0A1A0D
        • Slot 2 (VIBRANT HERO): Saturation 85–100%, Brightness 55–75%. This is the loudest color.
        • Slot 3 (ACCENT POP): A COMPLETELY DIFFERENT hue from Slot 2. Saturation > 80%. Creates tension.
        • Slot 4 (LIGHT NEUTRAL): Brightness 88–97%, Saturation < 20%. Off-white or light warm/cool.
        • Slot 5 (MID BRIDGE): Bridges Slot 1 and Slot 2. Saturation 50–70%, Brightness 35–55%.

        FORBIDDEN: Any two slots sharing a hue within 40° of each other EXCEPT Slot 1 which can share the base hue.
        The palette must feel like a magazine cover — arresting, bold, impossible to ignore.
        """)

        let s1 = LanguageModelSession(instructions: """
        You are a fashion-forward colorist known for UNEXPECTED, rule-breaking combinations.

        STRICT SLOT RULES — you MUST follow these for every generation:
        • Slot 1 (WARM TONE): Pick from the warm spectrum (red/orange/yellow, hue 0°–60°). Medium-high saturation.
        • Slot 2 (COOL SHOCK): Pick from the cool spectrum (blue/teal/indigo, hue 180°–260°). Must clash beautifully with Slot 1.
        • Slot 3 (EARTH GROUNDING): A muted, desaturated earthy tone. Saturation 10–30%. Beige, clay, stone, taupe family.
        • Slot 4 (NEON SURPRISE): A single electric, high-saturation color (saturation > 90%, brightness > 80%). This is the "wow" moment.
        • Slot 5 (DARK DEPTH): Very dark version of Slot 1's hue family. Brightness < 22%.

        FORBIDDEN: Slots 1, 2, and 4 cannot share a hue family. Each must be from a completely different part of the color wheel.
        Think: a Gen-Z outfit — warm vintage piece, an unexpected cool accessory, a neutral base, one neon pop.
        """)

        let s2 = LanguageModelSession(instructions: """
        You are a luxury brand color director who creates SOPHISTICATED TONAL palettes with hidden depth.

        STRICT SLOT RULES — you MUST follow these for every generation:
        • Slot 1 (DEEP SHADOW): The darkest expression of the base hue family. Brightness 8–20%, saturation 40–70%.
        • Slot 2 (RICH MIDTONE): Same hue family, Brightness 35–50%, Saturation 60–85%. The "true" color.
        • Slot 3 (LUMINOUS HIGHLIGHT): Same hue family but dramatically lighter. Brightness 80–92%, Saturation 15–40%.
        • Slot 4 (COMPLEMENTARY TWIST): Jump 150°–210° on the hue wheel. High saturation (70–90%). Breaks the tonal monotony.
        • Slot 5 (METALLIC NEUTRAL): Near-neutral — saturation 5–15%, brightness 55–78%. Platinum, pewter, greige, or warm gray.

        CRITICAL: Slots 1, 2, and 3 must share the same dominant hue (within 30°). They should look like the same color at three different times of day.
        The palette should feel like it belongs in a Bottega Veneta campaign.
        """)

        return [s0, s1, s2]
    }()

    // ── Derived ────────────────────────────────────────────────
    var currentPalette: ColorPalette? {
        guard activeVariation < variations.count else { return nil }
        return variations[activeVariation]
    }

    // MARK: - Body

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
            // Animated orb reacts to selected color
          /*  ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [selectedColor.opacity(0.55), .clear],
                        center: .center, startRadius: 0, endRadius: 50
                    ))
                    .frame(width: 100, height: 100)
                    .blur(radius: 18)

                Circle()
                    .stroke(selectedColor.opacity(0.28), lineWidth: 1)
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseRing ? 1.35 : 1.0)
                    .opacity(pulseRing ? 0 : 0.8)
                    .animation(
                        isGenerating
                            ? .easeOut(duration: 1.1).repeatForever(autoreverses: false)
                            : .default,
                        value: pulseRing
                    )

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
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .scaleEffect(1.3)
                    .frame(width: 44, height: 44)
                Text("Tap the circle to pick any color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK PRESETS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.4))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ColorPreset.all, id: \.hex) { preset in
                            PresetChip(
                                preset: preset,
                                isSelected: (selectedColor.toHex() ?? "").lowercased() == preset.hex.lowercased()
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedColor = Color(hex: preset.hex)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generateAllVariations) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: lockedSlots.isEmpty ? "sparkles" : "lock.fill")
                        .font(.system(size: 17, weight: .semibold))
                }

                Group {
                    if isGenerating {
                        Text("Crafting 3 unique palettes…")
                    } else if lockedSlots.isEmpty {
                        Text("Generate with AI")
                    } else {
                        Text("Regenerate · \(lockedSlots.count) color\(lockedSlots.count == 1 ? "" : "s") locked")
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if isGenerating {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color("AppText").opacity(0.1))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color("AppText").opacity(isGenerating ? 0.15 : 0), lineWidth: 1)
            )
        }
        .disabled(isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .animation(.easeInOut(duration: 0.2), value: lockedSlots.isEmpty)
    }

    // MARK: - Variations Section

    private var variationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Variation labels
            let labels = ["Bold Contrast", "Unexpected Mix", "Tonal Depth"]

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VARIATION \(activeVariation + 1) OF 3")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
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
                }
                .disabled(isGenerating)
            }

            // Style label chips — shows what each variation aimed for
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
                                    .foregroundStyle(
                                        i == activeVariation
                                            ? Color("AppBackground")
                                            : Color("AppText").opacity(0.5)
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(i == activeVariation
                                                  ? Color("AppText")
                                                  : Color("AppText").opacity(0.08))
                                    )
                            }
                        }
                    }
                }
            }

            variationCarousel

            if lockedSlots.isEmpty {
                lockHintBanner.transition(.opacity)
            }

            if let palette = currentPalette {
                colorCardsList(palette: palette)
            }

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
            .frame(height: 72)
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { dragOffset = $0.translation.width }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.width < -55, activeVariation < variations.count - 1 {
                                activeVariation += 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } else if value.translation.width > 55, activeVariation > 0 {
                                activeVariation -= 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            dragOffset = 0
                        }
                        triggerCardAnimation()
                    }
            )

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
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.9), lineWidth: 2)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity).frame(height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isActive ? Color("AppText").opacity(0.22) : Color("AppText").opacity(0.06),
                    lineWidth: 1.5
                )
        )
        .scaleEffect(isActive ? 1.0 : 0.94)
        .opacity(isActive ? 1.0 : 0.45)
    }

    private func xOffset(for index: Int) -> CGFloat {
        let width = UIScreen.main.bounds.width - 44
        return CGFloat(index - activeVariation) * width + dragOffset
    }

    // MARK: - Lock Hint

    private var lockHintBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#6C63FF"))
            Text("Tap \(Image(systemName: "lock.open")) on any color to keep it when regenerating")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.5))
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#6C63FF").opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#6C63FF").opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Color Cards List

    private func colorCardsList(palette: ColorPalette) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(palette.colors.enumerated()), id: \.element.hex) { index, color in
                LockableColorCard(
                    color: color,
                    index: index,
                    isLocked: lockedSlots[index] != nil,
                    onToggleLock: { toggleLock(at: index, color: color) }
                )
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 16)
                .animation(
                    .spring(response: 0.48, dampingFraction: 0.8)
                        .delay(Double(index) * 0.055),
                    value: animateCards
                )
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                savedSuccessfully ? Color(hex: "#34C759").opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .disabled(currentPalette == nil || savedSuccessfully || isGenerating)
        .animation(.spring(response: 0.4), value: savedSuccessfully)
    }

    // MARK: - Generation Logic

    func generateAllVariations() {
        guard !isGenerating else { return }
        isGenerating = true
        animateCards = false
        pulseRing = true
        savedSuccessfully = false

        let snapshot = lockedSlots
        let baseHex = selectedColor.toHex() ?? "#6C63FF"

        Task {
            // Fire all 3 in parallel — each gets a completely different creative brief
            async let r0 = generateOne(
                session: sessions[0],
                prompt: VariationPromptBuilder.boldContrast(baseHex: baseHex, locked: snapshot),
                locked: snapshot
            )
            async let r1 = generateOne(
                session: sessions[1],
                prompt: VariationPromptBuilder.unexpectedMix(baseHex: baseHex, locked: snapshot),
                locked: snapshot
            )
            async let r2 = generateOne(
                session: sessions[2],
                prompt: VariationPromptBuilder.tonalDepth(baseHex: baseHex, locked: snapshot),
                locked: snapshot
            )

            let results = await [r0, r1, r2].compactMap { $0 }

            await MainActor.run {
                withAnimation(.spring(response: 0.5)) {
                    variations = results
                    activeVariation = 0
                }
                isGenerating = false
                pulseRing = false
                triggerCardAnimation()
            }
        }
    }

    /// Generates one palette, enforces diversity, then overwrites locked slots.
    private func generateOne(
        session: LanguageModelSession,
        prompt: String,
        locked: [Int: GeneratedColor]
    ) async -> ColorPalette? {
        do {
            let response = try await session.respond(to: prompt, generating: ColorPalette.self)
            var palette = response.content

            // ── Step 1: Enforce color diversity (replaces similar colors) ──
            let diversified = ColorDiversityEnforcer.enforce(
                palette.colors,
                lockedSlots: locked,
                minimumDistance: 72
            )

            // ── Step 2: Overwrite locked slots with exact snapshots ──────────
            var finalColors = diversified
            for (slotIndex, lockedColor) in locked {
                guard slotIndex < finalColors.count else { continue }
                finalColors[slotIndex] = lockedColor
            }

            palette = ColorPalette(title: palette.title, colors: finalColors)
            return palette
        } catch {
            print("Generation error: \(error)")
            return nil
        }
    }

    // MARK: - Lock Toggle

    private func toggleLock(at index: Int, color: GeneratedColor) {
        withAnimation(.spring(response: 0.3)) {
            if lockedSlots[index] != nil {
                lockedSlots.removeValue(forKey: index)
            } else {
                lockedSlots[index] = color
            }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Save

    func savePalette() {
        guard let p = currentPalette else { return }
        let savedColors = p.colors.map { SavedColor(name: $0.name, hex: $0.hex) }
        modelContext.insert(SavedPalette(title: p.title, colors: savedColors))
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
// MARK: - VARIATION PROMPT BUILDER
// Each variation gets a radically different, slot-specific brief
// that steers the AI toward genuinely distinct results.
// ═════════════════════════════════════════════════════════════

enum VariationPromptBuilder {

    // MARK: Variation 1 — Bold Contrast

    static func boldContrast(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        let lockedNote = lockedNote(locked)
        return """
        CREATIVE BRIEF: HIGH-CONTRAST EDITORIAL
        Base color: \(baseHex) — include this exactly as one of the five colors.

        Generate exactly 5 colors following this slot map strictly:
        • Color 1: An almost-black dark anchor (brightness 5–18%). Should have a faint color cast — not pure #000000.
        • Color 2: A LOUD, highly saturated hero (saturation 85–100%, brightness 50–75%). Pick a hue at least 60° away from \(baseHex).
        • Color 3: A sharp contrasting accent — at least 90° different hue from Color 2. High saturation. Creates visual tension.
        • Color 4: A near-white or very light neutral (brightness 88–98%, saturation < 18%). Breathing room for the palette.
        • Color 5: \(baseHex) — the base color exactly as provided.

        Names must be evocative and specific (e.g. "Neon Rust", "Void Ink", "Ghost Linen"). Not generic.
        The palette MUST look dramatically different when viewed as a horizontal strip.
        \(lockedNote)
        """
    }

    // MARK: Variation 2 — Unexpected Mix

    static func unexpectedMix(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        let lockedNote = lockedNote(locked)
        return """
        CREATIVE BRIEF: UNEXPECTED RULE-BREAKING COMBINATION
        Base color: \(baseHex) — include this exactly as one of the five colors.

        Generate exactly 5 colors that SHOULD NOT work together but DO:
        • Color 1: A warm-spectrum tone (hue 0°–55°). Medium saturation, not too bright.
        • Color 2: A cool-spectrum shock (hue 195°–255°). Must contrast hard against Color 1.
        • Color 3: A completely desaturated earthy neutral (saturation 5–22%, brightness 45–72%). Clay, stone, putty, taupe.
        • Color 4: ONE electric, neon-adjacent pop (saturation > 88%, brightness > 78%). This is the surprise.
        • Color 5: \(baseHex) — the base color exactly as provided.

        Each color must be from a DIFFERENT hue family. No two of Colors 1–4 may share a hue within 50° of each other.
        Name each color as if naming a perfume or limited-edition sneaker colorway.
        \(lockedNote)
        """
    }

    // MARK: Variation 3 — Tonal Depth

    static func tonalDepth(baseHex: String, locked: [Int: GeneratedColor]) -> String {
        let lockedNote = lockedNote(locked)
        return """
        CREATIVE BRIEF: LUXURIOUS TONAL SOPHISTICATION
        Base color: \(baseHex) — this defines the dominant hue family.

        Generate exactly 5 colors with real depth and sophistication:
        • Color 1: The DARKEST expression of \(baseHex)'s hue (brightness 8–20%, saturation 45–75%). Rich shadow.
        • Color 2: \(baseHex) — the base color exactly as provided.
        • Color 3: A LIGHTER version of the same hue (brightness 78–92%, saturation 18–40%). Luminous, airy.
        • Color 4: A complementary ACCENT — jump 150°–200° on the hue wheel. Saturation 65–90%. This breaks the tonal harmony with intention.
        • Color 5: A warm or cool mid-gray (saturation 4–12%, brightness 52–74%). The sophisticated neutral anchor.

        Colors 1, 2, and 3 must share the dominant hue of \(baseHex) (within 25°).
        The palette should look like it was art-directed for a luxury brand campaign.
        Name each color poetically — think gallery art titles, not color theory terms.
        \(lockedNote)
        """
    }

    // MARK: Helper

    private static func lockedNote(_ locked: [Int: GeneratedColor]) -> String {
        guard !locked.isEmpty else { return "" }
        let lines = locked.sorted(by: { $0.key < $1.key }).map { idx, c in
            "Color \(idx + 1) is LOCKED — use exactly \(c.hex) with the name '\(c.name)'."
        }.joined(separator: "\n")
        return "\nLOCKED COLORS (do not change these):\n\(lines)"
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR DIVERSITY ENFORCER
// Post-processes AI output to guarantee visual distinction
// between all colors. Runs after every generation.
// ═════════════════════════════════════════════════════════════

enum ColorDiversityEnforcer {

    /// Minimum perceived RGB distance between any two non-locked colors.
    static func enforce(
        _ colors: [GeneratedColor],
        lockedSlots: [Int: GeneratedColor],
        minimumDistance: Double
    ) -> [GeneratedColor] {

        var result = colors
        let maxPasses = 8

        for _ in 0..<maxPasses {
            var replaced = false

            for i in 0..<result.count {
                // Never touch locked slots
                if lockedSlots[i] != nil { continue }

                for j in (i + 1)..<result.count {
                    if lockedSlots[j] != nil { continue }

                    let dist = rgbDistance(result[i].hex, result[j].hex)
                    if dist < minimumDistance {
                        // Replace the second color with a mathematically derived contrasting one
                        let replacement = deriveContrasting(
                            against: result.map(\.hex),
                            avoidIndex: j,
                            lockedHexes: Set(lockedSlots.values.map(\.hex))
                        )
                        result[j] = GeneratedColor(
                            name: result[j].name,
                            hex: replacement
                        )
                        replaced = true
                    }
                }
            }

            if !replaced { break } // palette is already diverse
        }

        return result
    }

    /// Derives a color that is maximally distant from all existing colors.
    private static func deriveContrasting(
        against hexes: [String],
        avoidIndex: Int,
        lockedHexes: Set<String>
    ) -> String {
        // Try 24 hue steps × 3 saturation levels × 2 brightness levels = 144 candidates
        let hueSteps: [Double] = stride(from: 0, to: 360, by: 15).map { $0 }
        let satLevels: [Double] = [0.9, 0.65, 0.3]
        let briLevels: [Double] = [0.85, 0.35]

        var bestHex = "#808080"
        var bestMinDist = 0.0

        for h in hueSteps {
            for s in satLevels {
                for b in briLevels {
                    let candidate = hsbToHex(h: h, s: s, b: b)
                    if lockedHexes.contains(candidate) { continue }

                    // Find the minimum distance from this candidate to all existing colors
                    let existingHexes = hexes.enumerated()
                        .filter { $0.offset != avoidIndex }
                        .map(\.element)

                    let minDist = existingHexes.map { rgbDistance(candidate, $0) }.min() ?? 0

                    if minDist > bestMinDist {
                        bestMinDist = minDist
                        bestHex = candidate
                    }
                }
            }
        }

        return bestHex
    }

    // MARK: Colour Math Helpers

    private static func rgbDistance(_ hexA: String, _ hexB: String) -> Double {
        let a = hexToRGB(hexA)
        let b = hexToRGB(hexB)
        let dr = Double(a.r - b.r)
        let dg = Double(a.g - b.g)
        let db = Double(a.b - b.b)
        // Weighted perceptual distance (human eye is most sensitive to green)
        return sqrt(0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db)
    }

    private static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        return (Int((val >> 16) & 0xFF), Int((val >> 8) & 0xFF), Int(val & 0xFF))
    }

    private static func hsbToHex(h: Double, s: Double, b: Double) -> String {
        let c = b * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        var t: (Double, Double, Double)
        switch h {
        case 0..<60:    t = (c, x, 0)
        case 60..<120:  t = (x, c, 0)
        case 120..<180: t = (0, c, x)
        case 180..<240: t = (0, x, c)
        case 240..<300: t = (x, 0, c)
        default:        t = (c, 0, x)
        }
        let r = Int(max(0, min(255, (t.0 + m) * 255)))
        let g = Int(max(0, min(255, (t.1 + m) * 255)))
        let bv = Int(max(0, min(255, (t.2 + m) * 255)))
        return String(format: "#%02X%02X%02X", r, g, bv)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - LOCKABLE COLOR CARD
// ═════════════════════════════════════════════════════════════

struct LockableColorCard: View {
    let color: GeneratedColor
    let index: Int
    let isLocked: Bool
    let onToggleLock: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {

            // Swatch + lock badge
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: color.hex))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isLocked ? Color.white.opacity(0.85) : Color.white.opacity(0.1),
                                lineWidth: isLocked ? 2.5 : 1
                            )
                    )

                if isLocked {
                    Circle()
                        .fill(Color(hex: "#6C63FF"))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 5, y: 5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.28), value: isLocked)

            // Name + hex
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(color.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("AppText"))
                        .lineLimit(1)

                    if isLocked {
                        Text("LOCKED")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(Color(hex: "#A78BFA"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: "#6C63FF").opacity(0.22)))
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.45))
            }

            Spacer()

            // Copy
            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copied = false }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.4))
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(copied
                                  ? Color(hex: "#34C759").opacity(0.13)
                                  : Color("AppText").opacity(0.07))
                    )
            }

            // Lock toggle
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(hex: "#A78BFA") : Color("AppText").opacity(0.32))
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isLocked
                                  ? Color(hex: "#6C63FF").opacity(0.2)
                                  : Color("AppText").opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isLocked ? Color(hex: "#6C63FF").opacity(0.45) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            .scaleEffect(isLocked ? 1.08 : 1.0)
            .animation(.spring(response: 0.25), value: isLocked)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isLocked
                      ? Color(hex: "#6C63FF").opacity(0.07)
                      : Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isLocked ? Color(hex: "#6C63FF").opacity(0.28) : Color("AppText").opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.3), value: isLocked)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PRESET CHIP
// ═════════════════════════════════════════════════════════════

struct PresetChip: View {
    let preset: ColorPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Circle()
                    .fill(Color(hex: preset.hex))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color("AppText").opacity(0.15), lineWidth: 1))
                Text(preset.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color("AppText") : Color("AppText").opacity(0.55))
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color("AppText").opacity(0.15) : Color("AppText").opacity(0.06))
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color("AppText").opacity(0.3) : Color("AppText").opacity(0.08),
                            lineWidth: 1
                        )
                    )
            )
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR PRESET
// ═════════════════════════════════════════════════════════════

struct ColorPreset {
    let name: String
    let hex: String

    static let all: [ColorPreset] = [
        ColorPreset(name: "Violet",  hex: "#6C63FF"),
        ColorPreset(name: "Coral",   hex: "#FF6B6B"),
        ColorPreset(name: "Ocean",   hex: "#0EA5E9"),
        ColorPreset(name: "Sage",    hex: "#6DBF8A"),
        ColorPreset(name: "Amber",   hex: "#F59E0B"),
        ColorPreset(name: "Rose",    hex: "#F43F5E"),
        ColorPreset(name: "Slate",   hex: "#64748B"),
        ColorPreset(name: "Mint",    hex: "#2DD4BF"),
    ]
}
