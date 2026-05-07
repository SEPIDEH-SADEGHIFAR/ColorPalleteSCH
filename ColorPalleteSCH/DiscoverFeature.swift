import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext

    // ── Search & Input ─────────────────────────────────────────
    @State private var searchText: String = ""
    @State private var pickedColor: Color = .blue
    @State private var showColorPicker: Bool = false
    @State private var searchHadNoResults: Bool = false

    // ── Explored Color State ───────────────────────────────────
    @State private var exploredColor: ExploredColor? = nil

    // ── Selection State ────────────────────────────────────────
    @State private var selectedSwatches: [String: String] = [:] // hex → name

    // ── UI State ───────────────────────────────────────────────
    @State private var animateIn = false
    @State private var showSavedConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection.padding(.top, 16)
                        searchSection
                            .padding(.top, 20)
                            .padding(.horizontal, 22)

                        if let explored = exploredColor {
                            exploredColorSection(explored: explored)
                                .padding(.top, 28)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else if searchHadNoResults {
                            noResultsState.padding(.top, 80)
                        } else {
                            emptyState.padding(.top, 80)
                        }

                        Spacer(minLength: selectedSwatches.isEmpty ? 40 : 120)
                    }
                }

                if !selectedSwatches.isEmpty {
                    createPaletteButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                    animateIn = true
                }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(selectedColor: $pickedColor) {
                    searchHadNoResults = false
                    exploreColor(pickedColor)
                }
            }
            .overlay(savedConfirmationOverlay)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISCOVER")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundStyle(Color("AppText").opacity(0.35))
            Text("Color Explorer")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppText"))
                .kerning(-1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.35))

                    // FIXED THE QUOTES ERROR HERE using escaping (\")
                    TextField("Try \"pink\", \"navy\", \"#FF6B6B\"...", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText"))
                        .tint(Color("AppText"))
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                        // Live search as the user types
                        .onChange(of: searchText) { newValue in
                            searchHadNoResults = false
                            let stripped = newValue.trimmingCharacters(in: .whitespaces)
                            if stripped.hasPrefix("#") && stripped.count == 7 {
                                performSearch()
                            } else if !stripped.hasPrefix("#") && stripped.count == 6 &&
                                      stripped.allSatisfy({ "0123456789ABCDEFabcdef".contains($0) }) {
                                performSearch()
                            }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            exploredColor = nil
                            searchHadNoResults = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color("AppText").opacity(0.25))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .shadow(color: Color("AppText").opacity(0.06), radius: 12, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                        )
                )

                // Color Picker button
                Button { showColorPicker = true } label: {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("AppBackground"))
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("AppText"))
                        )
                }
            }

            // Quick preset chips
            if exploredColor == nil && searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ColorNameDictionary.quickPresets, id: \.hex) { preset in
                            Button {
                                searchHadNoResults = false
                                exploreColor(Color(hex: preset.hex))
                            } label: {
                                HStack(spacing: 7) {
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                                        )
                                    Text(preset.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color("AppText").opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(Color("AppText").opacity(0.05))
                                )
                            }
                        }
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color("AppText").opacity(0.04))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color("AppText").opacity(0.2))
            }
            VStack(spacing: 8) {
                Text("Explore Any Color")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText").opacity(0.6))
                Text("Search by name, hex code, or use the dropper")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            // Example searches
            VStack(spacing: 8) {
                Text("Try searching for:")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color("AppText").opacity(0.25))
                HStack(spacing: 8) {
                    ForEach(["pink", "forest green", "lavender", "crimson"], id: \.self) { term in
                        Button {
                            searchText = term
                            performSearch()
                        } label: {
                            Text(term)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color("AppText").opacity(0.5))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .stroke(Color("AppText").opacity(0.15), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.2), value: animateIn)
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color("AppText").opacity(0.04))
                    .frame(width: 100, height: 100)
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color("AppText").opacity(0.2))
            }
            VStack(spacing: 8) {
                Text("No color found")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText").opacity(0.6))
                Text("\"\(searchText)\" didn't match any color.\nTry a hex code like #FF6B6B or use the dropper.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            // Offer the dropper as a fallback
            Button { showColorPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Pick a Color Instead")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color("AppBackground"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule().fill(Color("AppText"))
                )
            }
            .padding(.top, 4)
        }
        .transition(.opacity)
        .animation(.spring(response: 0.4), value: searchHadNoResults)
    }

    // MARK: - Explored Color Section

    private func exploredColorSection(explored: ExploredColor) -> some View {
        VStack(spacing: 28) {
            exactMatchCard(explored: explored).padding(.horizontal, 22)

            colorRangeSection(title: "Tints",          subtitle: "Lighter variations",  colors: explored.tints,          icon: "sun.max.fill")
            colorRangeSection(title: "Shades",         subtitle: "Darker variations",   colors: explored.shades,         icon: "moon.fill")
            colorRangeSection(title: "Analogous",      subtitle: "Neighboring hues",    colors: explored.analogous,      icon: "circle.hexagongrid.fill")
            colorRangeSection(title: "Complementary",  subtitle: "Opposite contrasts",  colors: explored.complementary,  icon: "arrow.triangle.2.circlepath")
            colorRangeSection(title: "Triadic",        subtitle: "Three-way harmony",   colors: explored.triadic,        icon: "triangle")
            colorRangeSection(title: "Split",          subtitle: "Near-complement pair",colors: explored.split,          icon: "arrow.branch")
        }
    }

    // MARK: - Exact Match Card

    private func exactMatchCard(explored: ExploredColor) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(explored.color)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                    )

                if selectedSwatches[explored.hex] != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color("AppBackground"))
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .padding(16)
                        }
                        Spacer()
                    }
                }
            }
            .onTapGesture { toggleSelection(hex: explored.hex, name: explored.name) }

            // Info footer
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXACT MATCH")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color("AppText").opacity(0.35))
                        Text(explored.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppText"))
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = explored.hex
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color("AppText").opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("AppText").opacity(0.06))
                            )
                    }
                }

                // HEX + RGB chips
                HStack(spacing: 8) {
                    InfoChip(icon: "number",               label: explored.hex.uppercased())
                    InfoChip(icon: "circle.grid.3x3.fill", label: explored.rgbString)
                    InfoChip(icon: "humidity",             label: explored.hslString)
                }
            }
            .padding(18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color("AppText").opacity(0.08), radius: 20, y: 8)
    }

    // MARK: - Color Range Section

    private func colorRangeSection(title: String, subtitle: String, colors: [ColorSwatch], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.38))
                }
                Spacer()
                Text("\(colors.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.22))
            }
            .padding(.horizontal, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors, id: \.hex) { swatch in
                        SwatchCard(
                            swatch: swatch,
                            isSelected: selectedSwatches[swatch.hex] != nil,
                            onTap: { toggleSelection(hex: swatch.hex, name: swatch.name) }
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 4) // room for shadow
            }
        }
    }

    // MARK: - Create Palette Button

    private var createPaletteButton: some View {
        Button { createPaletteFromSelection() } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("Create Palette  ·  \(selectedSwatches.count) selected")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color("AppBackground"))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("AppText"))
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
            )
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }

    // MARK: - Saved Confirmation Overlay

    private var savedConfirmationOverlay: some View {
        Group {
            if showSavedConfirmation {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showSavedConfirmation = false } }

                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color(hex: "#34C759"))
                        VStack(spacing: 6) {
                            Text("Palette Created!")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color("AppText"))
                            Text("Saved to your collection")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.5))
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
                    )
                    .padding(.horizontal, 50)
                }
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4), value: showSavedConfirmation)
    }

    // MARK: - Search Logic

    private func performSearch() {
        let raw = searchText.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }

        // 1. Exact hex with #
        if raw.hasPrefix("#") && raw.count == 7 {
            searchHadNoResults = false
            exploreColor(Color(hex: raw))
            return
        }

        // 2. Hex without #
        if raw.count == 6 && raw.allSatisfy({ "0123456789ABCDEFabcdef".contains($0) }) {
            searchHadNoResults = false
            exploreColor(Color(hex: "#\(raw)"))
            return
        }

        // 3. Named color — exact match first, then partial (contains)
        let lowered = raw.lowercased()
        let dict = ColorNameDictionary.all

        // Exact match
        if let hex = dict[lowered] {
            searchHadNoResults = false
            exploreColor(Color(hex: hex))
            return
        }

        // Partial match — find first key that contains the query
        let partialKey = dict.keys.sorted().first { $0.contains(lowered) || lowered.contains($0) }
        if let key = partialKey, let hex = dict[key] {
            searchHadNoResults = false
            searchText = key.capitalized   // update field to show the matched name
            exploreColor(Color(hex: hex))
            return
        }

        // Nothing found
        withAnimation(.spring(response: 0.4)) {
            searchHadNoResults = true
            exploredColor = nil
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func exploreColor(_ color: Color) {
        withAnimation(.spring(response: 0.5)) {
            exploredColor = ColorMath.explore(color: color)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func toggleSelection(hex: String, name: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedSwatches[hex] != nil {
                selectedSwatches.removeValue(forKey: hex)
            } else {
                selectedSwatches[hex] = name
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func createPaletteFromSelection() {
        guard !selectedSwatches.isEmpty else { return }
        let colors = selectedSwatches.prefix(8).map { SavedColor(name: $0.value, hex: $0.key) }
        let title = exploredColor?.name.capitalized ?? "Discovered Palette"
        modelContext.insert(SavedPalette(title: title, colors: Array(colors)))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation {
            showSavedConfirmation = true
            selectedSwatches.removeAll()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showSavedConfirmation = false }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - INFO CHIP
// ═════════════════════════════════════════════════════════════

struct InfoChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color("AppText").opacity(0.35))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AppText").opacity(0.55))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color("AppText").opacity(0.06))
        )
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - SWATCH CARD
// ═════════════════════════════════════════════════════════════

struct SwatchCard: View {
    let swatch: ColorSwatch
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: swatch.hex))
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color("AppBackground") : Color("AppText").opacity(0.08),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )

                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color("AppBackground"))
                                .shadow(color: .black.opacity(0.3), radius: 3)
                                .padding(7)
                        }
                        Spacer()
                    }
                }
            }

            // Name + hex
            VStack(spacing: 2) {
                if !swatch.name.isEmpty {
                    Text(swatch.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color("AppText"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Text(swatch.hex.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(swatch.name.isEmpty ? 0.8 : 0.4))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(width: 100)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 14, bottomTrailingRadius: 14))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: Color("AppText").opacity(isSelected ? 0.14 : 0.05),
            radius: isSelected ? 12 : 6,
            y: 3
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture(perform: onTap)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR PICKER SHEET
// ═════════════════════════════════════════════════════════════

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                VStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(selectedColor)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                        )
                        .overlay(
                            Text(selectedColor.toHex() ?? "")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white) // Keep white to contrast against raw color
                                .shadow(color: .black.opacity(0.3), radius: 4)
                        )
                        .padding(.horizontal, 22)

                    ColorPicker("Pick a Color", selection: $selectedColor)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 22)

                    Spacer()

                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Explore This Color")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppBackground"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color("AppText")))
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR SWATCH MODEL
// ═════════════════════════════════════════════════════════════

struct ColorSwatch: Identifiable {
    let id = UUID()
    let hex: String
    var name: String = ""   // auto-named by ColorMath
}


// ═════════════════════════════════════════════════════════════
// MARK: - EXPLORED COLOR MODEL
// ═════════════════════════════════════════════════════════════

struct ExploredColor {
    let color: Color
    let hex: String
    let name: String
    let rgbString: String
    let hslString: String
    let tints: [ColorSwatch]
    let shades: [ColorSwatch]
    let analogous: [ColorSwatch]
    let complementary: [ColorSwatch]
    let triadic: [ColorSwatch]
    let split: [ColorSwatch]
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR MATH ENGINE
// ═════════════════════════════════════════════════════════════

enum ColorMath {

    static func explore(color: Color) -> ExploredColor {
        let hex = color.toHex() ?? "#000000"
        let rgb = hexToRGB(hex)
        let hsb = rgbToHSB(rgb)
        let hsl = rgbToHSL(rgb)

        return ExploredColor(
            color:         color,
            hex:           hex,
            name:          ColorNameDictionary.closestName(for: hex),
            rgbString:     "RGB \(rgb.r) \(rgb.g) \(rgb.b)",
            hslString:     "HSL \(Int(hsl.h))° \(Int(hsl.s * 100))% \(Int(hsl.l * 100))%",
            tints:         generateTints(from: rgb),
            shades:        generateShades(from: rgb),
            analogous:     generateAnalogous(from: hsb),
            complementary: generateComplementary(from: hsb),
            triadic:       generateTriadic(from: hsb),
            split:         generateSplit(from: hsb)
        )
    }

    // MARK: Tints — mix with white

    static func generateTints(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        let ratios: [Double] = [0.15, 0.3, 0.45, 0.6, 0.75, 0.88]
        return ratios.map { ratio in
            let r = Int(Double(rgb.r) + (255 - Double(rgb.r)) * ratio)
            let g = Int(Double(rgb.g) + (255 - Double(rgb.g)) * ratio)
            let b = Int(Double(rgb.b) + (255 - Double(rgb.b)) * ratio)
            let hex = rgbToHex(r: r, g: g, b: b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Shades — mix with black

    static func generateShades(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        let ratios: [Double] = [0.12, 0.25, 0.38, 0.52, 0.66, 0.80]
        return ratios.map { ratio in
            let r = Int(Double(rgb.r) * (1 - ratio))
            let g = Int(Double(rgb.g) * (1 - ratio))
            let b = Int(Double(rgb.b) * (1 - ratio))
            let hex = rgbToHex(r: r, g: g, b: b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Analogous — ±15°, ±30°, ±45°, ±60°

    static func generateAnalogous(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        let offsets: [Double] = [-60, -45, -30, -15, 15, 30, 45, 60]
        return offsets.map { offset in
            let newH = wrap(hsb.h + offset)
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Complementary — 180° + slight variations

    static func generateComplementary(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        let offsets: [Double] = [165, 172.5, 180, 187.5, 195]
        return offsets.map { offset in
            let newH = wrap(hsb.h + offset)
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Triadic — 120° apart

    static func generateTriadic(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        let offsets: [Double] = [100, 110, 120, 240, 250, 260]
        return offsets.map { offset in
            let newH = wrap(hsb.h + offset)
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Split-complementary — 150° and 210°

    static func generateSplit(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        let offsets: [Double] = [140, 150, 160, 200, 210, 220]
        return offsets.map { offset in
            let newH = wrap(hsb.h + offset)
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: Color Space Conversions

    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (r: Int((value >> 16) & 0xFF),
                g: Int((value >> 8) & 0xFF),
                b: Int(value & 0xFF))
    }

    static func rgbToHex(r: Int, g: Int, b: Int) -> String {
        String(format: "#%02X%02X%02X",
               max(0, min(255, r)),
               max(0, min(255, g)),
               max(0, min(255, b)))
    }

    static func rgbToHSB(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, b: Double) {
        let r = Double(rgb.r) / 255, g = Double(rgb.g) / 255, b = Double(rgb.b) / 255
        let mx = Swift.max(r, g, b), mn = Swift.min(r, g, b), d = mx - mn
        var h: Double = 0
        let s = mx == 0 ? 0.0 : d / mx
        if d != 0 {
            if mx == r      { h = 60 * (((g - b) / d).truncatingRemainder(dividingBy: 6)) }
            else if mx == g { h = 60 * (((b - r) / d) + 2) }
            else            { h = 60 * (((r - g) / d) + 4) }
        }
        if h < 0 { h += 360 }
        return (h: h, s: s, b: mx)
    }

    static func rgbToHSL(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, l: Double) {
        let r = Double(rgb.r) / 255, g = Double(rgb.g) / 255, b = Double(rgb.b) / 255
        let mx = Swift.max(r, g, b), mn = Swift.min(r, g, b)
        let l = (mx + mn) / 2
        let d = mx - mn
        let s = d == 0 ? 0.0 : d / (1 - abs(2 * l - 1))
        var h: Double = 0
        if d != 0 {
            if mx == r      { h = 60 * (((g - b) / d).truncatingRemainder(dividingBy: 6)) }
            else if mx == g { h = 60 * (((b - r) / d) + 2) }
            else            { h = 60 * (((r - g) / d) + 4) }
        }
        if h < 0 { h += 360 }
        return (h: h, s: s, l: l)
    }

    static func hsbToRGB(h: Double, s: Double, b: Double) -> (r: Int, g: Int, b: Int) {
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
        return (r: Int((t.0 + m) * 255),
                g: Int((t.1 + m) * 255),
                b: Int((t.2 + m) * 255))
    }

    private static func wrap(_ h: Double) -> Double {
        var v = h.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR NAME DICTIONARY  (150+ entries)
// ═════════════════════════════════════════════════════════════

enum ColorNameDictionary {

    // MARK: Quick presets shown on the empty state

    struct Preset { let name: String; let hex: String }

    static let quickPresets: [Preset] = [
        Preset(name: "Coral",     hex: "#FF6B6B"),
        Preset(name: "Violet",    hex: "#6C63FF"),
        Preset(name: "Mint",      hex: "#2DD4BF"),
        Preset(name: "Amber",     hex: "#F59E0B"),
        Preset(name: "Rose",      hex: "#EC4899"),
        Preset(name: "Slate",     hex: "#64748B"),
        Preset(name: "Emerald",   hex: "#10B981"),
        Preset(name: "Sky",       hex: "#0EA5E9"),
    ]

    // MARK: All named colors — searched on input

    static let all: [String: String] = [
        // ── Reds ─────────────────────────────────────────────
        "red":             "#FF0000",
        "dark red":        "#8B0000",
        "light red":       "#FF6666",
        "crimson":         "#DC143C",
        "scarlet":         "#FF2400",
        "ruby":            "#9B111E",
        "firebrick":       "#B22222",
        "tomato":          "#FF6347",
        "indian red":      "#CD5C5C",
        "maroon":          "#800000",
        "burgundy":        "#800020",
        "wine":            "#722F37",
        "blood red":       "#8A0303",
        "rose red":        "#C21E56",
        "brick red":       "#CB4154",
        "candy apple":     "#FF0800",

        // ── Pinks ────────────────────────────────────────────
        "pink":            "#FF69B4",
        "hot pink":        "#FF1493",
        "deep pink":       "#FF1493",
        "light pink":      "#FFB6C1",
        "baby pink":       "#F4C2C2",
        "blush":           "#DE5D83",
        "rose":            "#FF007F",
        "flamingo":        "#FC8EAC",
        "carnation":       "#FFA6C9",
        "fuchsia":         "#FF00FF",
        "magenta":         "#FF00FF",
        "orchid":          "#DA70D6",
        "mauve":           "#E0B0FF",
        "bubblegum":       "#FFC1CC",
        "salmon pink":     "#FF91A4",
        "dusty rose":      "#DCAE96",
        "pastel pink":     "#FFD1DC",
        "punch":           "#FF4D79",

        // ── Oranges ──────────────────────────────────────────
        "orange":          "#FF8C00",
        "dark orange":     "#FF6D00",
        "light orange":    "#FFB347",
        "amber":           "#FFBF00",
        "tangerine":       "#F28500",
        "apricot":         "#FBCEB1",
        "peach":           "#FFCBA4",
        "pumpkin":         "#FF7518",
        "burnt orange":    "#CC5500",
        "coral":           "#FF6B6B",
        "melon":           "#FEBAAD",
        "tiger orange":    "#FD6A02",
        "mango":           "#FDBE02",

        // ── Yellows ──────────────────────────────────────────
        "yellow":          "#FFFF00",
        "light yellow":    "#FFFFE0",
        "dark yellow":     "#9B870C",
        "gold":            "#FFD700",
        "golden":          "#FFD700",
        "lemon":           "#FFF44F",
        "canary":          "#FFEF00",
        "cream":           "#FFFDD0",
        "butter":          "#FFFD74",
        "banana":          "#FAE7B5",
        "mustard":         "#FFDB58",
        "khaki":           "#C3B091",
        "dark khaki":      "#BDB76B",
        "straw":           "#E4D96F",
        "flax":            "#EEDC82",
        "champagne":       "#F7E7CE",

        // ── Greens ───────────────────────────────────────────
        "green":           "#008000",
        "light green":     "#90EE90",
        "dark green":      "#006400",
        "lime":            "#00FF00",
        "lime green":      "#32CD32",
        "forest green":    "#228B22",
        "sage":            "#8FBC8F",
        "olive":           "#808000",
        "dark olive":      "#556B2F",
        "emerald":         "#50C878",
        "mint":            "#98FF98",
        "mint green":      "#98FF98",
        "seafoam":         "#93E9BE",
        "jade":            "#00A86B",
        "hunter green":    "#355E3B",
        "moss":            "#8A9A5B",
        "fern":            "#4F7942",
        "pistachio":       "#93C572",
        "avocado":         "#568203",
        "chartreuse":      "#7FFF00",
        "spring green":    "#00FF7F",
        "grass green":     "#7CFC00",
        "bottle green":    "#006A4E",
        "pine green":      "#01796F",
        "viridian":        "#40826D",
        "army green":      "#4B5320",

        // ── Teals & Cyans ────────────────────────────────────
        "teal":            "#008080",
        "dark teal":       "#003333",
        "light teal":      "#00CED1",
        "cyan":            "#00FFFF",
        "aqua":            "#00FFFF",
        "turquoise":       "#40E0D0",
        "dark turquoise":  "#00CED1",
        "medium turquoise":"#48D1CC",
        "cadet blue":      "#5F9EA0",
        "steel teal":      "#5F8A8B",
        "cerulean":        "#007BA7",
        "aquamarine":      "#7FFFD4",
        "tiffany blue":    "#0ABAB5",

        // ── Blues ────────────────────────────────────────────
        "blue":            "#0000FF",
        "light blue":      "#ADD8E6",
        "dark blue":       "#00008B",
        "sky blue":        "#87CEEB",
        "baby blue":       "#89CFF0",
        "royal blue":      "#4169E1",
        "navy":            "#000080",
        "navy blue":       "#000080",
        "midnight blue":   "#191970",
        "cobalt":          "#0047AB",
        "cobalt blue":     "#0047AB",
        "cornflower":      "#6495ED",
        "cornflower blue": "#6495ED",
        "periwinkle":      "#CCCCFF",
        "steel blue":      "#4682B4",
        "powder blue":     "#B0E0E6",
        "slate blue":      "#6A5ACD",
        "dodger blue":     "#1E90FF",
        "ocean blue":      "#4F42B5",
        "electric blue":   "#7DF9FF",
        "denim":           "#1560BD",
        "sapphire":        "#0F52BA",
        "azure":           "#007FFF",
        "peacock blue":    "#005F6A",

        // ── Purples & Violets ─────────────────────────────────
        "purple":          "#800080",
        "light purple":    "#B39DDB",
        "dark purple":     "#4A0072",
        "violet":          "#EE82EE",
        "lavender":        "#E6E6FA",
        "dark lavender":   "#9683EC",
        "indigo":          "#4B0082",
        "plum":            "#DDA0DD",
        "thistle":         "#D8BFD8",
        "grape":           "#6F2DA8",
        "eggplant":        "#614051",
        "amethyst":        "#9966CC",
        "lilac":           "#C8A2C8",
        "wisteria":        "#C9A0DC",
        "heliotrope":      "#DF73FF",
        "mulberry":        "#C54B8C",
        "byzantium":       "#702963",
        "royal purple":    "#7851A9",
        "iris":            "#5A4FCF",
        "periwinkle blue": "#8C90C8",

        // ── Browns & Neutrals ─────────────────────────────────
        "brown":           "#A52A2A",
        "light brown":     "#C4A882",
        "dark brown":      "#5C4033",
        "tan":             "#D2B48C",
        "beige":           "#F5F5DC",
        "sand":            "#C2B280",
        "caramel":         "#C68642",
        "coffee":          "#6F4E37",
        "chocolate":       "#7B3F00",
        "mahogany":        "#C04000",
        "sienna":          "#A0522D",
        "umber":           "#635147",
        "chestnut":        "#954535",
        "tawny":           "#CD5700",
        "russet":          "#80461B",
        "sepia":           "#704214",
        "terracotta":      "#E2725B",
        "clay":            "#B66A50",
        "copper":          "#B87333",
        "bronze":          "#CD7F32",
        "ochre":           "#CC7722",
        "rust":            "#B7410E",

        // ── Grays & Blacks ────────────────────────────────────
        "gray":            "#808080",
        "grey":            "#808080",
        "light gray":      "#D3D3D3",
        "light grey":      "#D3D3D3",
        "dark gray":       "#404040",
        "dark grey":       "#404040",
        "silver":          "#C0C0C0",
        "charcoal":        "#36454F",
        "slate":           "#708090",
        "slate gray":      "#708090",
        "dim gray":        "#696969",
        "gainsboro":       "#DCDCDC",
        "ash":             "#B2BEB5",
        "smoke":           "#738276",
        "gunmetal":        "#2A3439",
        "onyx":            "#353839",
        "jet":             "#343434",
        "black":           "#000000",
        "off black":       "#0F0F0F",

        // ── Whites & Off-Whites ───────────────────────────────
        "white":           "#FFFFFF",
        "off white":       "#FAF9F6",
        "ivory":           "#FFFFF0",
        "snow":            "#FFFAFA",
        "linen":           "#FAF0E6",
        "ghost white":     "#F8F8FF",
        "seashell":        "#FFF5EE",
        "floralwhite":     "#FFFAF0",
        "pearl":           "#F0EAD6",
        "alabaster":       "#F2F0EB",
        "eggshell":        "#F0EAD6",
        "vanilla":         "#F3E5AB",

        // ── Special / Trendy ──────────────────────────────────
        "millennial pink": "#F4A7B9",
        "gen z yellow":    "#F5E642",
        "viva magenta":    "#BB2649",
        "peach fuzz":      "#FFBE98",
        "classic blue":    "#0F4C81",
        "living coral":    "#FF6B6B",
        "ultra violet":    "#5F4B8B",
        "rose gold":       "#B76E79",
        "blush gold":      "#C9956C",
        "neon green":      "#39FF14",
        "neon pink":       "#FF6EC7",
        "neon blue":       "#1F51FF",
        "neon orange":     "#FF5733",
        "pastel blue":     "#AEC6CF",
        "pastel green":    "#77DD77",
        "pastel purple":   "#B39EB5",
        "pastel yellow":   "#FDFD96",
        // "pastel pink" was here, creating the duplicate!
        "pastel orange":   "#FFB347",
    ]

    // MARK: Find closest named color by hue distance (for generated swatches)

    static func closestName(for hex: String) -> String {
        let target = ColorMath.hexToRGB(hex)
        let th = ColorMath.rgbToHSB(target)

        var bestKey = ""
        var bestDist = Double.infinity

        for (name, namedHex) in all {
            let rgb = ColorMath.hexToRGB(namedHex)
            let h = ColorMath.rgbToHSB(rgb)
            // Weight hue most, then saturation and brightness
            let dh = min(abs(th.h - h.h), 360 - abs(th.h - h.h))
            let ds = abs(th.s - h.s) * 100
            let db = abs(th.b - h.b) * 50
            let dist = dh + ds + db
            if dist < bestDist {
                bestDist = dist
                bestKey = name
            }
        }
        return bestKey.isEmpty ? "" : bestKey.capitalized
    }
}
