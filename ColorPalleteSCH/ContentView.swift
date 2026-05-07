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
    // Always 3 palettes after first generation.
    @State private var variations: [ColorPalette] = []
    @State private var activeVariation: Int = 0

    // ── Lock state ─────────────────────────────────────────────
    // Key = slot index (0-4).
    // Value = the EXACT GeneratedColor snapshot taken when the user tapped lock.
    // This is the source of truth — AI output is irrelevant for locked slots.
    @State private var lockedSlots: [Int: GeneratedColor] = [:]

    // ── UI state ───────────────────────────────────────────────
    @State private var isGenerating = false
    @State private var savedSuccessfully = false
    @State private var animateCards = false
    @State private var pulseRing = false
    @State private var dragOffset: CGFloat = 0

    // ── 3 independent AI sessions ──────────────────────────────
    let sessions: [LanguageModelSession] = (0..<3).map { index in
        let variationStyle = ["harmonious and balanced, with rich saturation contrast",
                              "bold and dramatic, with strong light-dark contrast",
                              "soft and elegant, with muted tones and subtle warmth"][index]

        return LanguageModelSession(instructions: """
        You are an expert color theorist and UI/brand designer with deep knowledge of OKLCH and perceptual color spaces.

        Your task: given a base hex color, generate a 5-color palette that is \(variationStyle).

        STRICT RULES — you must follow all of these:

        1. UNIQUENESS — every hex code in the palette must be different.
           Never repeat the same hex twice in one palette, not even with minor variation.
           All 5 colors must be visually distinct when placed side by side.

        2. DIVERSITY — spread the colors across at least 3 different hue families.
           Do NOT generate 5 shades of the same hue. Monotone palettes are forbidden.

        3. LIGHTNESS SPREAD — the 5 colors must span a wide lightness range.
           Include at least: 1 dark color (L < 35%), 1 medium color (L 40–65%), 1 light color (L > 70%).

        4. SATURATION VARIETY — mix vivid and muted tones. Avoid all colors being equally saturated.

        5. HARMONY — apply one of these schemes: complementary, triadic, split-complementary, or tetradic.
           State which scheme you used in the palette title (e.g. "Triadic Dusk").

        6. NAMES — each color name must be poetic, evocative, and 2–3 words.
           Names must reflect the actual color (don't name a green "Crimson Tide").
           No clichés like "Midnight Blue" or "Forest Green".

        7. BASE COLOR — the base color provided by the user must appear in the palette as one of the 5 colors.
           Do not ignore or radically alter it.

        Output format: return exactly 5 colors. No more, no less.
        """)
    }

    // ── Derived ────────────────────────────────────────────────
    var currentPalette: ColorPalette? {
        guard activeVariation < variations.count else { return nil }
        return variations[activeVariation]
    }

    // ── Body ───────────────────────────────────────────────────
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea() // Adaptive Background

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
                    .foregroundStyle(Color("AppText")) // Adaptive Text
            }
            Spacer()
            // Pulsing orb — reacts to selected color
            ZStack {
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
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Color Picker Hero

    private var colorPickerHero: some View {
        VStack(spacing: 16) {
            // Big color preview rect
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
                        .foregroundStyle(.white) // Always white over solid color
                        .shadow(color: .black.opacity(0.3), radius: 4)
                    Text("Base Color")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8)) // Always white over solid color
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
            }

            // Picker row
            HStack(spacing: 14) {
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .scaleEffect(1.3)
                    .frame(width: 44, height: 44)
                Text("Tap the circle to pick any color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.5)) // Adaptive Text
                Spacer()
            }
            .padding(.horizontal, 4)

            // Quick presets
            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK PRESETS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.4)) // Adaptive Text

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
                .fill(Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Background
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
                        Text("Generating 3 variations…")
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
            .foregroundStyle(.white) // Always white over purple gradient
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if isGenerating {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color("AppText").opacity(0.1)) // Adaptive
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

            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("VARIATIONS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Color("AppText").opacity(0.4))
                    Text(currentPalette?.title ?? "")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText")) // Adaptive Text
                        .animation(.easeInOut(duration: 0.2), value: activeVariation)
                }
                Spacer()
                // Regenerate all
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

            // Swipeable strip carousel
            variationCarousel

            // Lock hint (shown only before user locks anything)
            if lockedSlots.isEmpty {
                lockHintBanner
                    .transition(.opacity)
            }

            // Color cards with lock toggles
            if let palette = currentPalette {
                colorCardsList(palette: palette)
            }

            // Save button
            saveButton
        }
    }

    // MARK: - Variation Carousel

    private var variationCarousel: some View {
        VStack(spacing: 12) {
            // Swipeable strip
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

            // Dots + label
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<variations.count, id: \.self) { i in
                        Capsule()
                            .fill(i == activeVariation ? Color("AppText") : Color("AppText").opacity(0.22))
                            .frame(width: i == activeVariation ? 22 : 6, height: 6)
                            .animation(.spring(response: 0.32), value: activeVariation)
                    }
                }
                Spacer()
                if variations.count > 1 {
                    Text("Swipe for variations")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.4))
                }
            }
        }
    }

    private func stripView(palette: ColorPalette, index: Int) -> some View {
        let isActive = index == activeVariation
        return HStack(spacing: 3) {
            ForEach(Array(palette.colors.enumerated()), id: \.element.hex) { slotIdx, c in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: c.hex))

                    // Show lock icon on the strip for locked slots
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
        .frame(maxWidth: .infinity)
        .frame(height: 72)
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
            Text("Tap \(Image(systemName: "lock.open")) on any color to lock it before regenerating")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.5)) // Adaptive Text
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
                Text(savedSuccessfully ? "Saved!" : "Save Variation \(activeVariation + 1)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(savedSuccessfully ? Color(hex: "#34C759") : Color("AppBackground"))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
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
        .animation(.easeInOut(duration: 0.15), value: activeVariation)
    }

    // MARK: - Generation Logic

    func generateAllVariations() {
        guard !isGenerating else { return }
        isGenerating = true
        animateCards = false
        pulseRing = true
        savedSuccessfully = false

        let snapshot = lockedSlots

        Task {
            async let r0 = generateOne(session: sessions[0], harmonyHint: "complementary", locked: snapshot)
            async let r1 = generateOne(session: sessions[1], harmonyHint: "triadic",        locked: snapshot)
            async let r2 = generateOne(session: sessions[2], harmonyHint: "analogous with a vibrant accent", locked: snapshot)

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

    private func generateOne(
        session: LanguageModelSession,
        harmonyHint: String,
        locked: [Int: GeneratedColor]
    ) async -> ColorPalette? {
        let hex = selectedColor.toHex() ?? "#000000"
        let prompt = """
        Base color: \(hex)
        Harmony style: \(harmonyHint)
        Generate 5 colors. Return them in slot order (slot 1 through slot 5).
        Make names poetic. Make the palette genuinely beautiful together.
        """
        do {
            let response = try await session.respond(to: prompt, generating: ColorPalette.self)
            var palette = response.content

            if !locked.isEmpty {
                var colors = palette.colors
                for (slotIndex, lockedColor) in locked {
                    guard slotIndex < colors.count else { continue }
                    colors[slotIndex] = lockedColor
                }
                palette = ColorPalette(title: palette.title, colors: colors)
            }

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
        let newPalette = SavedPalette(title: p.title, colors: savedColors)
        modelContext.insert(newPalette)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { savedSuccessfully = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }

    // MARK: - Helpers

    private func triggerCardAnimation() {
        animateCards = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation { animateCards = true }
        }
    }
}

// MARK: - Lockable Color Card

struct LockableColorCard: View {
    let color: GeneratedColor
    let index: Int
    let isLocked: Bool
    let onToggleLock: () -> Void

    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {

            // Swatch with lock indicator
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

            // Name + hex + locked badge
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(color.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("AppText")) // Adaptive Text
                        .lineLimit(1)

                    if isLocked {
                        Text("LOCKED")
                            .font(.system(size: 8, weight: .black))
                            .tracking(0.8)
                            .foregroundStyle(Color(hex: "#A78BFA"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#6C63FF").opacity(0.22))
                            )
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.45))
            }

            Spacer()

            // Lock toggle
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isLocked ? Color(hex: "#A78BFA") : Color("AppText").opacity(0.4))
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isLocked
                                  ? Color(hex: "#6C63FF").opacity(0.15)
                                  : Color("AppText").opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isLocked
                                            ? Color(hex: "#6C63FF").opacity(0.45)
                                            : Color.clear,
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
                      : Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Background
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isLocked
                                ? Color(hex: "#6C63FF").opacity(0.28)
                                : Color("AppText").opacity(0.07),
                            lineWidth: 1
                        )
                )
        )
        .animation(.spring(response: 0.3), value: isLocked)
    }
}

// MARK: - Preset Chip

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
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Text(preset.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color("AppText") : Color("AppText").opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
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

// MARK: - Color Preset

struct ColorPreset {
    let name: String
    let hex: String

    static let all: [ColorPreset] = [
        ColorPreset(name: "Violet", hex: "#6C63FF"),
        ColorPreset(name: "Coral",  hex: "#FF6B6B"),
        ColorPreset(name: "Ocean",  hex: "#0EA5E9"),
        ColorPreset(name: "Sage",   hex: "#6DBF8A"),
        ColorPreset(name: "Amber",  hex: "#F59E0B"),
        ColorPreset(name: "Rose",   hex: "#F43F5E"),
        ColorPreset(name: "Slate",  hex: "#64748B"),
        ColorPreset(name: "Mint",   hex: "#2DD4BF"),
    ]
}
