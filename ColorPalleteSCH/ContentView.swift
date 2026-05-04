import SwiftUI
import SwiftData
import FoundationModels

// MARK: - Main AI Generator View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedColor: Color = Color(hex: "#6C63FF")
    @State private var palette: ColorPalette? = nil
    @State private var isGenerating = false
    @State private var savedSuccessfully = false
    @State private var animateCards = false
    @State private var pulseRing = false

    let session = LanguageModelSession(
        instructions: """
        You are an expert color theorist and designer. When given a base hex color,
        generate a beautiful, harmonious 5-color palette.
        Each color must have:
        - A creative, evocative name (2-3 words, poetic but not cliché)
        - A valid 6-digit hex code starting with #
        The palette title should be a short evocative phrase (2-4 words).
        Ensure the colors work together: use complementary, analogous, triadic,
        or split-complementary harmony. Vary lightness and saturation meaningfully.
        """
    )

    var body: some View {
        NavigationStack {
            ZStack {
                // Background — dark canvas
                Color(hex: "#0D0D0D")
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // ── Header ──────────────────────────────────
                        headerSection

                        // ── Color Picker Hero ────────────────────────
                        colorPickerHero
                            .padding(.top, 32)

                        // ── Generate Button ──────────────────────────
                        generateButton
                            .padding(.top, 32)

                        // ── Result Section ───────────────────────────
                        if let palette {
                            resultSection(palette: palette)
                                .padding(.top, 40)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color(hex: "#0D0D0D"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI STUDIO")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Color(hex: "#6C63FF"))

                    Text("Generate\nPalette")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineSpacing(-2)
                }
                Spacer()

                // Decorative orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [selectedColor.opacity(0.6), selectedColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    Circle()
                        .stroke(selectedColor.opacity(0.3), lineWidth: 1)
                        .frame(width: 60, height: 60)
                        .scaleEffect(pulseRing ? 1.3 : 1.0)
                        .opacity(pulseRing ? 0 : 0.8)
                        .animation(
                            isGenerating ? .easeOut(duration: 1.2).repeatForever(autoreverses: false) : .default,
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
        }
        .padding(.top, 20)
    }

    // MARK: - Color Picker Hero

    private var colorPickerHero: some View {
        VStack(spacing: 16) {
            // Large color preview
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(selectedColor)
                    .frame(height: 160)
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
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            // Color picker row
            HStack(spacing: 14) {
                // Native picker
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .scaleEffect(1.3)
                    .frame(width: 44, height: 44)

                Text("Tap the circle to pick any color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))

                Spacer()
            }
            .padding(.horizontal, 4)

            // Quick presets
            VStack(alignment: .leading, spacing: 10) {
                Text("QUICK PRESETS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color.white.opacity(0.35))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(ColorPreset.all, id: \.hex) { preset in
                            PresetChip(preset: preset, isSelected: (selectedColor.toHex() ?? "").lowercased() == preset.hex.lowercased()) {
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
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: generatePalette) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                }

                Text(isGenerating ? "Creating your palette…" : "Generate with AI")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if isGenerating {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.12))
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(isGenerating ? 0.15 : 0), lineWidth: 1)
            )
        }
        .disabled(isGenerating)
        .animation(.easeInOut(duration: 0.25), value: isGenerating)
    }

    // MARK: - Result Section

    @ViewBuilder
    private func resultSection(palette: ColorPalette) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RESULT")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(Color.white.opacity(0.35))
                    Text(palette.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()

                // Regenerate
                Button(action: generatePalette) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .disabled(isGenerating)
            }

            // Color strip — full width preview
            HStack(spacing: 3) {
                ForEach(palette.colors, id: \.hex) { c in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: c.hex))
                }
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Color cards list
            VStack(spacing: 10) {
                ForEach(Array(palette.colors.enumerated()), id: \.element.hex) { index, c in
                    ColorResultCard(color: c, index: index)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.07),
                            value: animateCards
                        )
                }
            }
            .onAppear { animateCards = true }

            // Save button
            saveButton
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: savePalette) {
            HStack(spacing: 10) {
                Image(systemName: savedSuccessfully ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))
                Text(savedSuccessfully ? "Saved to My Palettes!" : "Save Palette")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(savedSuccessfully ? Color(hex: "#34C759") : .black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(savedSuccessfully ? Color(hex: "#34C759").opacity(0.15) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                savedSuccessfully ? Color(hex: "#34C759").opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .animation(.spring(response: 0.4), value: savedSuccessfully)
        .disabled(palette == nil || savedSuccessfully)
    }

    // MARK: - Logic

    func generatePalette() {
        isGenerating = true
        animateCards = false
        pulseRing = true
        let hex = selectedColor.toHex() ?? "#000000"

        Task {
            do {
                let prompt = """
                Base color: \(hex)
                Generate a palette of 5 harmonious colors inspired by this base.
                Make the names poetic and the colors genuinely beautiful together.
                """
                let response = try await session.respond(to: prompt, generating: ColorPalette.self)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.4)) {
                        palette = response.content
                    }
                    animateCards = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        animateCards = true
                    }
                }
            } catch {
                print("Generation error: \(error)")
            }
            await MainActor.run {
                isGenerating = false
                pulseRing = false
                savedSuccessfully = false
            }
        }
    }

    func savePalette() {
        guard let p = palette else { return }
        let savedColors = p.colors.map { SavedColor(name: $0.name, hex: $0.hex) }
        let newPalette = SavedPalette(title: p.title, colors: savedColors)
        modelContext.insert(newPalette)
        withAnimation(.spring(response: 0.4)) {
            savedSuccessfully = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }
}

// MARK: - Color Result Card

struct ColorResultCard: View {
    let color: GeneratedColor
    let index: Int
    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {
            // Swatch
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: color.hex))
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(color.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }

            Spacer()

            // Copy button
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
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color.white.opacity(0.5))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(copied ? Color(hex: "#34C759").opacity(0.15) : Color.white.opacity(0.08))
                    )
            }
        }
        .padding(12)
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
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                Text(preset.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.white.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.06))
                    .overlay(
                        Capsule().stroke(
                            isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                    )
            )
        }
    }
}

// MARK: - Color Preset Model

struct ColorPreset {
    let name: String
    let hex: String

    static let all: [ColorPreset] = [
        ColorPreset(name: "Violet", hex: "#6C63FF"),
        ColorPreset(name: "Coral", hex: "#FF6B6B"),
        ColorPreset(name: "Ocean", hex: "#0EA5E9"),
        ColorPreset(name: "Sage", hex: "#6DBF8A"),
        ColorPreset(name: "Amber", hex: "#F59E0B"),
        ColorPreset(name: "Rose", hex: "#F43F5E"),
        ColorPreset(name: "Slate", hex: "#64748B"),
        ColorPreset(name: "Mint", hex: "#2DD4BF"),
    ]
}
