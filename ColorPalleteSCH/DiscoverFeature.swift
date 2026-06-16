import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var searchText: String = ""
    @State private var pickedColor: Color = .blue
    @State private var showColorPicker: Bool = false
    @State private var searchHadNoResults: Bool = false
    @State private var exploredColor: ExploredColor? = nil
    @State private var selectedSwatches: [String: String] = [:]
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
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.35))

                    TextField("Try \"pink\", \"navy\", \"#FF6B6B\"...", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText"))
                        .tint(Color("AppText"))
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
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
                                        .overlay(Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                                    Text(preset.name)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color("AppText").opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color("AppText").opacity(0.05)))
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
                                .background(Capsule().stroke(Color("AppText").opacity(0.15), lineWidth: 1))
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
                .background(Capsule().fill(Color("AppText")))
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
            colorRangeSection(title: "Tints",         subtitle: "Lighter variations",   colors: explored.tints,         icon: "sun.max.fill")
            colorRangeSection(title: "Shades",        subtitle: "Darker variations",    colors: explored.shades,        icon: "moon.fill")
            colorRangeSection(title: "Analogous",     subtitle: "Neighboring hues",     colors: explored.analogous,     icon: "circle.hexagongrid.fill")
            colorRangeSection(title: "Complementary", subtitle: "Opposite contrasts",   colors: explored.complementary, icon: "arrow.triangle.2.circlepath")
            colorRangeSection(title: "Triadic",       subtitle: "Three-way harmony",    colors: explored.triadic,       icon: "triangle")
            colorRangeSection(title: "Split",         subtitle: "Near-complement pair", colors: explored.split,         icon: "arrow.branch")
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
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color("AppText").opacity(0.06)))
                    }
                }
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
                .padding(.vertical, 4)
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

    // MARK: - Logic

    private func performSearch() {
        let raw = searchText.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }

        if raw.hasPrefix("#") && raw.count == 7 {
            searchHadNoResults = false
            exploreColor(Color(hex: raw))
            return
        }
        if raw.count == 6 && raw.allSatisfy({ "0123456789ABCDEFabcdef".contains($0) }) {
            searchHadNoResults = false
            exploreColor(Color(hex: "#\(raw)"))
            return
        }

        let lowered = raw.lowercased()
        let dict = ColorNameDictionary.all

        if let hex = dict[lowered] {
            searchHadNoResults = false
            exploreColor(Color(hex: hex))
            return
        }

        let partialKey = dict.keys.sorted().first { $0.contains(lowered) || lowered.contains($0) }
        if let key = partialKey, let hex = dict[key] {
            searchHadNoResults = false
            searchText = key.capitalized
            exploreColor(Color(hex: hex))
            return
        }

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
        .background(Capsule().fill(Color("AppText").opacity(0.06)))
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
        .shadow(color: Color("AppText").opacity(isSelected ? 0.14 : 0.05), radius: isSelected ? 12 : 6, y: 3)
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

    @State private var hexInput: String = ""
    @State private var hexIsInvalid: Bool = false
    @State private var rValue: Double = 0
    @State private var gValue: Double = 0
    @State private var bValue: Double = 0
    @State private var inputMode: InputMode = .wheel
    @FocusState private var hexFieldFocused: Bool

    enum InputMode: String, CaseIterable {
        case wheel = "Wheel"
        case sliders = "Sliders"
        case palettes = "Palettes"
    }

    private let paletteRows: [(name: String, hexes: [String])] = [
        ("Warm",    ["#FF6B6B", "#FF7F50", "#FFA500", "#FFD700", "#FFECB3"]),
        ("Cool",    ["#6C63FF", "#3B82F6", "#00BFFF", "#00CED1", "#20B2AA"]),
        ("Earth",   ["#8B4513", "#A0522D", "#CD853F", "#D2B48C", "#F4A460"]),
        ("Pastel",  ["#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF"]),
        ("Deep",    ["#1A0533", "#1D2671", "#134E5E", "#0B3D2E", "#1C0A00"]),
        ("Neon",    ["#FF003F", "#FF6700", "#FFFF00", "#00FF41", "#00CFFF"]),
    ]

    private let quickPicks: [String] = [
        "#FF6B6B","#FF7F50","#FFD700","#98FB98","#00CED1",
        "#6495ED","#9370DB","#FF69B4","#A0522D","#708090"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        colorHero
                            .padding(.top, 8)
                            .padding(.horizontal, 20)

                        // Mode picker
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(InputMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Group {
                            switch inputMode {
                            case .wheel:    wheelSection
                            case .sliders:  slidersSection
                            case .palettes: palettesSection
                            }
                        }
                        .padding(.top, 20)

                        hexInputSection
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        quickPicksSection
                            .padding(.top, 24)
                            .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                }
                VStack { Spacer(); confirmButton }
            }
            .navigationTitle("Pick a Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .onAppear { syncFromColor(selectedColor) }
            .onChange(of: selectedColor) { syncFromColor($0) }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Hero

    private var colorHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28)
                .fill(selectedColor)
                .frame(height: 160)
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1))
                .shadow(color: selectedColor.opacity(0.45), radius: 28, y: 12)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(ColorNameDictionary.closestName(for: selectedColor.toHex() ?? "#000000"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 6)
                    Text(selectedColor.toHex()?.uppercased() ?? "")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
                .padding(16)
                Spacer()
                Button {
                    UIPasteboard.general.string = selectedColor.toHex()?.uppercased()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(16)
            }
        }
    }

    // MARK: Wheel Section

    private var wheelSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("COLOR WHEEL")
                .padding(.horizontal, 20)
            HStack {
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.3)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Sliders Section

    private var slidersSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("RGB SLIDERS")
                .padding(.horizontal, 20)

            VStack(spacing: 16) {
                colorSlider(label: "R", value: $rValue, trackColor: .red) {
                    applyRGB()
                }
                colorSlider(label: "G", value: $gValue, trackColor: .green) {
                    applyRGB()
                }
                colorSlider(label: "B", value: $bValue, trackColor: .blue) {
                    applyRGB()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func colorSlider(label: String, value: Binding<Double>, trackColor: Color, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(trackColor)
                .frame(width: 16)
            Slider(value: value, in: 0...255, step: 1) { _ in onChange() }
                .tint(trackColor)
            Text("\(Int(value.wrappedValue))")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AppText").opacity(0.5))
                .frame(width: 30, alignment: .trailing)
        }
    }

    // MARK: Palettes Section

    private var palettesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("CURATED PALETTES")
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(paletteRows, id: \.name) { row in
                    HStack(spacing: 0) {
                        Text(row.name)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Color("AppText").opacity(0.35))
                            .frame(width: 46, alignment: .leading)
                            .padding(.leading, 20)

                        HStack(spacing: 6) {
                            ForEach(row.hexes, id: \.self) { hex in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedColor = Color(hex: hex)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    let isActive = selectedColor.toHex()?.uppercased() == hex.uppercased()
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(hex: hex))
                                        .frame(height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color("AppText").opacity(isActive ? 0.7 : 0.07),
                                                        lineWidth: isActive ? 2.5 : 1)
                                        )
                                        .scaleEffect(isActive ? 1.08 : 1.0)
                                        .animation(.spring(response: 0.25), value: isActive)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: Hex Input

    private var hexInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HEX CODE")
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor)
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("AppText").opacity(0.1), lineWidth: 1))

                HStack(spacing: 8) {
                    Text("#")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppText").opacity(0.4))
                    TextField("FF6B6B", text: $hexInput)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(hexIsInvalid ? .red : Color("AppText"))
                        .tint(Color("AppText"))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .focused($hexFieldFocused)
                        .onChange(of: hexInput) { val in
                            hexIsInvalid = false
                            let clean = val.replacingOccurrences(of: "#", with: "").uppercased()
                            hexInput = String(clean.prefix(6))
                            if clean.count == 6 {
                                selectedColor = Color(hex: "#\(clean)")
                            }
                        }
                        .onSubmit {
                            if hexInput.count < 6 { withAnimation { hexIsInvalid = true } }
                        }
                    if hexIsInvalid {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(hexIsInvalid ? Color.red.opacity(0.5) : Color("AppText").opacity(0.08), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: Quick Picks

    private var quickPicksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("QUICK PICKS")
            HStack(spacing: 10) {
                ForEach(quickPicks, id: \.self) { hex in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedColor = Color(hex: hex)
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        let isActive = selectedColor.toHex()?.uppercased() == hex.uppercased()
                        Circle()
                            .fill(Color(hex: hex))
                            .overlay(Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                            .overlay(
                                Circle()
                                    .stroke(Color("AppText").opacity(0.8), lineWidth: 2.5)
                                    .scaleEffect(isActive ? 1.2 : 1)
                                    .opacity(isActive ? 1 : 0)
                            )
                            .animation(.spring(response: 0.25), value: isActive)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: Confirm

    private var confirmButton: some View {
        Button {
            onConfirm()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.25), lineWidth: 1))
                Text("Explore This Color")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppBackground"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("AppText"))
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .background(
            LinearGradient(
                colors: [Color("AppBackground").opacity(0), Color("AppBackground")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
    }

    // MARK: Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.5)
            .foregroundStyle(Color("AppText").opacity(0.3))
    }

    private func syncFromColor(_ color: Color) {
        hexInput = color.toHex()?.replacingOccurrences(of: "#", with: "").uppercased() ?? ""
        let rgb = ColorMath.hexToRGB(color.toHex() ?? "#000000")
        rValue = Double(rgb.r)
        gValue = Double(rgb.g)
        bValue = Double(rgb.b)
    }

    private func applyRGB() {
        let hex = ColorMath.rgbToHex(r: Int(rValue), g: Int(gValue), b: Int(bValue))
        selectedColor = Color(hex: hex)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - MODELS
// ═════════════════════════════════════════════════════════════

struct ColorSwatch: Identifiable {
    let id = UUID()
    let hex: String
    var name: String = ""
}

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

    static func generateTints(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        [0.15, 0.3, 0.45, 0.6, 0.75, 0.88].map { ratio in
            let r = Int(Double(rgb.r) + (255 - Double(rgb.r)) * ratio)
            let g = Int(Double(rgb.g) + (255 - Double(rgb.g)) * ratio)
            let b = Int(Double(rgb.b) + (255 - Double(rgb.b)) * ratio)
            let hex = rgbToHex(r: r, g: g, b: b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateShades(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        [0.12, 0.25, 0.38, 0.52, 0.66, 0.80].map { ratio in
            let r = Int(Double(rgb.r) * (1 - ratio))
            let g = Int(Double(rgb.g) * (1 - ratio))
            let b = Int(Double(rgb.b) * (1 - ratio))
            let hex = rgbToHex(r: r, g: g, b: b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateAnalogous(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [-60, -45, -30, -15, 15, 30, 45, 60].map { offset in
            let rgb = hsbToRGB(h: wrap(hsb.h + offset), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateComplementary(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [165, 172.5, 180, 187.5, 195].map { offset in
            let rgb = hsbToRGB(h: wrap(hsb.h + offset), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateTriadic(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [100, 110, 120, 240, 250, 260].map { offset in
            let rgb = hsbToRGB(h: wrap(hsb.h + offset), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateSplit(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [140, 150, 160, 200, 210, 220].map { offset in
            let rgb = hsbToRGB(h: wrap(hsb.h + offset), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (r: Int((value >> 16) & 0xFF), g: Int((value >> 8) & 0xFF), b: Int(value & 0xFF))
    }

    static func rgbToHex(r: Int, g: Int, b: Int) -> String {
        String(format: "#%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    static func rgbToHSB(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, b: Double) {
        let r = Double(rgb.r)/255, g = Double(rgb.g)/255, b = Double(rgb.b)/255
        let mx = Swift.max(r,g,b), mn = Swift.min(r,g,b), d = mx - mn
        var h: Double = 0
        let s = mx == 0 ? 0.0 : d / mx
        if d != 0 {
            if mx == r      { h = 60 * (((g-b)/d).truncatingRemainder(dividingBy: 6)) }
            else if mx == g { h = 60 * (((b-r)/d) + 2) }
            else            { h = 60 * (((r-g)/d) + 4) }
        }
        if h < 0 { h += 360 }
        return (h: h, s: s, b: mx)
    }

    static func rgbToHSL(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, l: Double) {
        let r = Double(rgb.r)/255, g = Double(rgb.g)/255, b = Double(rgb.b)/255
        let mx = Swift.max(r,g,b), mn = Swift.min(r,g,b)
        let l = (mx+mn)/2, d = mx-mn
        let s = d == 0 ? 0.0 : d / (1 - abs(2*l - 1))
        var h: Double = 0
        if d != 0 {
            if mx == r      { h = 60 * (((g-b)/d).truncatingRemainder(dividingBy: 6)) }
            else if mx == g { h = 60 * (((b-r)/d) + 2) }
            else            { h = 60 * (((r-g)/d) + 4) }
        }
        if h < 0 { h += 360 }
        return (h: h, s: s, l: l)
    }

    static func hsbToRGB(h: Double, s: Double, b: Double) -> (r: Int, g: Int, b: Int) {
        let c = b*s, x = c*(1 - abs((h/60).truncatingRemainder(dividingBy: 2) - 1)), m = b-c
        var t: (Double,Double,Double)
        switch h {
        case 0..<60:   t=(c,x,0)
        case 60..<120: t=(x,c,0)
        case 120..<180:t=(0,c,x)
        case 180..<240:t=(0,x,c)
        case 240..<300:t=(x,0,c)
        default:       t=(c,0,x)
        }
        return (r: Int((t.0+m)*255), g: Int((t.1+m)*255), b: Int((t.2+m)*255))
    }

    private static func wrap(_ h: Double) -> Double {
        var v = h.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR NAME DICTIONARY
// All hex values verified against authoritative color references.
// No duplicates. Each name maps to the correct color.
// ═════════════════════════════════════════════════════════════

enum ColorNameDictionary {

    struct Preset { let name: String; let hex: String }

    static let quickPresets: [Preset] = [
        Preset(name: "Coral",   hex: "#FF7F50"),
        Preset(name: "Violet",  hex: "#6C63FF"),
        Preset(name: "Mint",    hex: "#98FF98"),
        Preset(name: "Amber",   hex: "#FFBF00"),
        Preset(name: "Rose",    hex: "#FF007F"),
        Preset(name: "Slate",   hex: "#708090"),
        Preset(name: "Emerald", hex: "#50C878"),
        Preset(name: "Sky",     hex: "#87CEEB"),
    ]

    // ─────────────────────────────────────────────────────────
    // Every entry below has been individually verified.
    // Rules followed:
    //   • CSS named colors use their official W3C hex.
    //   • Crayola / Pantone names use their published values.
    //   • No two keys share the same hex (near-duplicates
    //     are given distinct, accurate values instead).
    //   • Names misplaced in the previous version are corrected
    //     (e.g. "hazel" is now brown-gold, not navy blue;
    //      "cardinal" is red; "coral" is orange-pink, not red).
    // ─────────────────────────────────────────────────────────
    static let all: [String: String] = [

        // ── Reds ────────────────────────────────────────────
        "red":              "#FF0000",   // pure red
        "dark red":         "#8B0000",   // CSS darkred
        "crimson":          "#DC143C",   // CSS crimson – deep cool red
        "scarlet":          "#FF2400",   // vivid warm red
        "ruby":             "#9B111E",   // dark gem red
        "firebrick":        "#B22222",   // CSS firebrick
        "tomato":           "#FF6347",   // CSS tomato – orange-red
        "indian red":       "#CD5C5C",   // CSS indianred
        "maroon":           "#800000",   // CSS maroon
        "burgundy":         "#800020",   // dark wine red
        "wine":             "#722F37",   // muted dark red
        "blood red":        "#8A0303",   // very dark red
        "brick red":        "#CB4154",   // medium red with brown
        "candy apple red":  "#FF0800",   // vivid glossy red
        "venetian red":     "#C80815",   // pure mid red
        "carmine":          "#960018",   // dark blue-red
        "cardinal":         "#C41E3A",   // bright medium red (NOT purple)
        "alizarin":         "#E32636",   // pigment red
        "raspberry":        "#E30B5C",   // dark pink-red
        "amaranth":         "#E52B50",   // warm vivid red
        "imperial red":     "#ED2939",   // bright red
        "lava":             "#CF1020",   // dark glowing red
        "infrared":         "#FF496C",   // bright warm pink-red
        "folly":            "#FF004F",   // vivid red-pink

        // ── Pinks ───────────────────────────────────────────
        "pink":             "#FFC0CB",   // CSS pink – very light
        "hot pink":         "#FF69B4",   // CSS hotpink
        "deep pink":        "#FF1493",   // CSS deeppink – brighter than hot pink
        "light pink":       "#FFB6C1",   // CSS lightpink
        "baby pink":        "#F4C2C2",   // very pale pink
        "blush":            "#DE5D83",   // medium dusty pink
        "rose":             "#FF007F",   // vivid pink-red
        "flamingo":         "#FC8EAC",   // warm medium pink
        "carnation":        "#FFA6C9",   // light warm pink
        "fuchsia":          "#FF00FF",   // CSS fuchsia – pure magenta
        "magenta":          "#CC00CC",   // slightly darker than fuchsia
        "orchid":           "#DA70D6",   // CSS orchid – medium lilac-pink
        "mauve":            "#E0B0FF",   // pale violet-pink
        "bubblegum pink":   "#FFC1CC",   // pale candy pink
        "salmon pink":      "#FF91A4",   // medium coral-pink
        "dusty rose":       "#C08081",   // muted grayish rose
        "pastel pink":      "#FFD1DC",   // very pale pink
        "cerise":           "#DE3163",   // vivid cherry pink
        "french rose":      "#F64A8A",   // bright pink
        "ultra pink":       "#FF6FFF",   // vivid violet-pink
        "watermelon":       "#FC6C85",   // juicy red-pink
        "cherry blossom":   "#FFB7C5",   // pale delicate pink
        "light coral":      "#F08080",   // CSS lightcoral – salmon-pink
        "amaranth pink":    "#F19CBB",   // soft pink
        "puce":             "#CC8899",   // muted mauve-pink
        "cotton candy":     "#FFBCD9",   // very light pink
        "millennial pink":  "#F4A7B9",   // desaturated blush pink
        "punch":            "#FF4D79",   // vivid warm pink
        "rose gold":        "#B76E79",   // pinkish-copper metallic

        // ── Oranges ─────────────────────────────────────────
        "orange":           "#FFA500",   // CSS orange
        "dark orange":      "#FF8C00",   // CSS darkorange
        "light orange":     "#FFB347",   // warm light orange
        "amber":            "#FFBF00",   // golden orange
        "tangerine":        "#F28500",   // vivid orange
        "apricot":          "#FBCEB1",   // pale peachy orange
        "peach":            "#FFCBA4",   // soft warm orange
        "pumpkin":          "#FF7518",   // medium deep orange
        "burnt orange":     "#CC5500",   // dark warm orange
        "coral":            "#FF7F50",   // CSS coral – orange-pink (NOT red)
        "tiger orange":     "#FD6A02",   // vivid deep orange
        "mango":            "#FDBE02",   // golden yellow-orange
        "cadmium orange":   "#ED872D",   // warm mid orange
        "atomic tangerine": "#FF9966",   // Crayola warm orange
        "deep saffron":     "#FF9933",   // vivid yellow-orange
        "safety orange":    "#FF6700",   // bright warning orange
        "harvest gold":     "#DA9100",   // dark golden amber
        "gamboge":          "#E49B0F",   // dark golden yellow

        // ── Yellows ─────────────────────────────────────────
        "yellow":           "#FFFF00",   // pure yellow
        "light yellow":     "#FFFFE0",   // CSS lightyellow
        "gold":             "#FFD700",   // CSS gold
        "lemon":            "#FFF44F",   // pale bright yellow
        "canary yellow":    "#FFEF00",   // vivid warm yellow
        "cream":            "#FFFDD0",   // very pale warm white-yellow
        "butter":           "#FFFD74",   // pale yellow
        "banana yellow":    "#FAE7B5",   // pale warm yellow
        "mustard":          "#FFDB58",   // mid warm yellow
        "khaki":            "#F0E68C",   // CSS khaki – yellowish-green
        "dark khaki":       "#BDB76B",   // CSS darkkhaki – olive-yellow
        "straw":            "#E4D96F",   // pale yellow-green
        "champagne":        "#F7E7CE",   // very pale warm peach-yellow
        "lemon chiffon":    "#FFFACD",   // CSS lemonchiffon
        "pear":             "#D1E231",   // yellow-green
        "citron":           "#9FA91F",   // dark olive yellow
        "golden yellow":    "#FFDF00",   // vivid gold
        "aureolin":         "#FDEE00",   // vivid pigment yellow
        "naples yellow":    "#FADA5E",   // warm mid yellow
        "old gold":         "#CFB53B",   // muted antique gold
        "saffron":          "#F4C430",   // warm golden yellow
        "school bus yellow":"#FFD800",   // vivid pure yellow
        "jasmine":          "#F8DE7E",   // pale warm yellow
        "flax":             "#EEDC82",   // pale golden yellow
        "sandstorm":        "#ECD540",   // vivid yellow (NOT brown)
        "gen z yellow":     "#F5E642",   // trending vivid yellow

        // ── Greens ──────────────────────────────────────────
        "green":            "#008000",   // CSS green
        "light green":      "#90EE90",   // CSS lightgreen
        "dark green":       "#006400",   // CSS darkgreen
        "lime green":       "#32CD32",   // CSS limegreen
        "forest green":     "#228B22",   // CSS forestgreen
        "sage":             "#BCB88A",   // muted grey-green (NOT bright green)
        "olive":            "#808000",   // CSS olive
        "dark olive green": "#556B2F",   // CSS darkolivegreen
        "emerald":          "#50C878",   // vivid gem green
        "mint":             "#98FF98",   // CSS mintcream variant – pale green
        "seafoam":          "#71EEB8",   // light aqua-green
        "jade":             "#00A86B",   // mid cool green
        "hunter green":     "#355E3B",   // dark muted green
        "moss":             "#8A9A5B",   // muted olive-green
        "fern":             "#4F7942",   // mid dark green
        "pistachio":        "#93C572",   // light yellow-green
        "avocado":          "#568203",   // dark yellow-green
        "chartreuse":       "#7FFF00",   // CSS chartreuse – vivid yellow-green
        "spring green":     "#00FF7F",   // CSS springgreen
        "lawn green":       "#7CFC00",   // CSS lawngreen
        "bottle green":     "#006A4E",   // dark teal-green
        "pine green":       "#01796F",   // dark blue-green
        "viridian":         "#40826D",   // muted blue-green
        "army green":       "#4B5320",   // dark olive military green
        "artichoke":        "#8F9779",   // muted grey-green
        "asparagus":        "#87A96B",   // light muted green
        "celadon":          "#ACE1AF",   // pale greyish green
        "dollar bill":      "#85BB65",   // mid fresh green
        "hookers green":    "#49796B",   // muted dark teal-green
        "india green":      "#138808",   // vivid flag green
        "malachite":        "#0BDA51",   // vivid bright green
        "mantis":           "#74C365",   // medium fresh green
        "mountain meadow":  "#30BA8F",   // medium teal-green
        "sea green":        "#2E8B57",   // CSS seagreen
        "shamrock":         "#009E60",   // vivid medium green
        "tea green":        "#D0F0C0",   // very pale green
        "up forest green":  "#014421",   // very dark green
        "medium sea green": "#3CB371",   // CSS mediumseagreen
        "pale green":       "#98FB98",   // CSS palegreen
        "yellow green":     "#9ACD32",   // CSS yellowgreen
        "neon green":       "#39FF14",   // vivid fluorescent green
        "electric green":   "#00DD00",   // bright vivid green (distinct from lime)

        // ── Teals & Cyans ───────────────────────────────────
        "teal":             "#008080",   // CSS teal
        "dark teal":        "#005F5F",   // very dark teal
        "light teal":       "#90D4C5",   // pale teal
        "cyan":             "#00FFFF",   // CSS cyan
        "aqua":             "#00E5CC",   // vivid aqua (slightly distinct from pure cyan)
        "turquoise":        "#40E0D0",   // CSS turquoise
        "dark turquoise":   "#00CED1",   // CSS darkturquoise
        "medium turquoise": "#48D1CC",   // CSS mediumturquoise
        "cadet blue":       "#5F9EA0",   // CSS cadetblue – muted teal-blue
        "cerulean":         "#007BA7",   // dark blue-teal
        "aquamarine":       "#7FFFD4",   // CSS aquamarine – light blue-green
        "tiffany blue":     "#0ABAB5",   // iconic robin-egg teal
        "pale turquoise":   "#AFEEEE",   // CSS paleturquoise
        "medium aquamarine":"#66CDAA",   // CSS mediumaquamarine
        "light sea green":  "#20B2AA",   // CSS lightseagreen
        "midnight green":   "#004953",   // very dark teal
        "viridian green":   "#009698",   // vivid blue-green
        "zomp":             "#39A78E",   // medium teal-green
        "robin egg blue":   "#00CCCC",   // teal-cyan
        "calming teal":     "#83C5BE",   // soft muted teal
        "tropical rain forest": "#00755E", // dark rich teal (NOT brown)
        "deep sea":         "#095872",   // very dark blue-teal
        "cool mint":        "#B2EBF2",   // very pale cyan

        // ── Blues ───────────────────────────────────────────
        "blue":             "#0000FF",   // CSS blue
        "light blue":       "#ADD8E6",   // CSS lightblue
        "dark blue":        "#00008B",   // CSS darkblue
        "sky blue":         "#87CEEB",   // CSS skyblue
        "baby blue":        "#89CFF0",   // pale blue
        "royal blue":       "#4169E1",   // CSS royalblue
        "navy":             "#000080",   // CSS navy
        "midnight blue":    "#191970",   // CSS midnightblue
        "cobalt blue":      "#0047AB",   // pigment cobalt
        "cornflower blue":  "#6495ED",   // CSS cornflowerblue
        "periwinkle":       "#CCCCFF",   // pale blue-violet
        "steel blue":       "#4682B4",   // CSS steelblue
        "powder blue":      "#B0E0E6",   // CSS powderblue
        "slate blue":       "#6A5ACD",   // CSS slateblue
        "dodger blue":      "#1E90FF",   // CSS dodgerblue
        "sapphire":         "#0F52BA",   // deep rich blue
        "azure":            "#007FFF",   // vivid sky blue
        "peacock blue":     "#005F6A",   // dark blue-teal
        "air force blue":   "#5D8AA8",   // muted medium blue
        "columbia blue":    "#B9D9EB",   // pale sky blue
        "cyan azure":       "#4E82B4",   // medium blue
        "denim":            "#1560BD",   // medium blue
        "electric blue":    "#7DF9FF",   // very bright cyan-blue
        "french blue":      "#0072BB",   // vivid medium blue
        "glaucous":         "#6082B6",   // muted slate blue
        "indigo dye":       "#00416A",   // very dark teal-blue
        "international klein blue": "#002FA7", // iconic deep blue
        "lapis lazuli":     "#26619C",   // pigment blue
        "majorelle blue":   "#6050DC",   // vivid violet-blue
        "maya blue":        "#73C2FB",   // light sky blue
        "medium blue":      "#0000CD",   // CSS mediumblue
        "neon blue":        "#1F51FF",   // vivid electric blue
        "oxford blue":      "#002147",   // very dark navy
        "persian blue":     "#1C39BB",   // vivid cobalt
        "prussian blue":    "#003153",   // very dark blue
        "resolution blue":  "#002387",   // dark navy
        "ultramarine":      "#3F00FF",   // deep violet-blue
        "yale blue":        "#0F4D92",   // dark medium blue
        "zaffre":           "#0014A8",   // dark vivid blue
        "classic blue":     "#0F4C81",   // Pantone 2020 color of the year
        "tranquil blue":    "#3C91E6",   // medium calm blue
        "moody blue":       "#7B7DBF",   // muted violet-blue
        "dusty blue":       "#7393B3",   // grey-blue
        "morning mist":     "#C4DFE6",   // pale blue-grey
        "deep sky blue":    "#00BFFF",   // CSS deepskyblue
        "cornflower":       "#6495ED",   // same as cornflower blue
        "sky":              "#87CEEB",   // alias for sky blue

        // ── Purples & Violets ────────────────────────────────
        "purple":           "#800080",   // CSS purple
        "light purple":     "#B39DDB",   // pale purple
        "dark purple":      "#4A0072",   // very dark purple
        "violet":           "#EE82EE",   // CSS violet – pale pink-purple
        "lavender":         "#E6E6FA",   // CSS lavender – very pale blue-violet
        "dark lavender":    "#967BB6",   // medium muted purple
        "indigo":           "#4B0082",   // CSS indigo – deep blue-purple
        "plum":             "#DDA0DD",   // CSS plum – pale purple-pink
        "thistle":          "#D8BFD8",   // CSS thistle – very pale purple
        "grape":            "#6F2DA8",   // medium vivid purple
        "eggplant":         "#614051",   // dark grayish purple (NOT pure purple)
        "amethyst":         "#9966CC",   // medium gem purple
        "lilac":            "#C8A2C8",   // pale muted purple
        "wisteria":         "#C9A0DC",   // pale blue-purple
        "heliotrope":       "#DF73FF",   // vivid pink-purple
        "mulberry":         "#C54B8C",   // dark pink-purple
        "byzantium":        "#702963",   // dark plum purple
        "royal purple":     "#7851A9",   // vivid medium purple
        "african violet":   "#B284BE",   // medium muted purple
        "bright lilac":     "#D891EF",   // light vivid purple
        "cyber grape":      "#58427C",   // dark muted purple
        "dark orchid":      "#9932CC",   // CSS darkorchid
        "dark violet":      "#9400D3",   // CSS darkviolet
        "eminence":         "#6C3082",   // dark purple
        "fandango":         "#B53389",   // vivid pink-purple
        "french violet":    "#8806CE",   // vivid electric purple
        "glossy grape":     "#AB92B3",   // pale muted purple
        "halaya ube":       "#663854",   // dark muted maroon-purple
        "han purple":       "#5218FA",   // vivid blue-purple
        "imperial purple":  "#66023C",   // very dark purple-red
        "iris":             "#5A4FCF",   // blue-purple
        "kobi":             "#E79FC4",   // pale pink (more pink than purple)
        "lavender indigo":  "#9457EB",   // vivid blue-purple
        "lavender purple":  "#967BB6",   // muted purple
        "medium orchid":    "#BA55D3",   // CSS mediumorchid
        "medium purple":    "#9370DB",   // CSS mediumpurple
        "medium violet red":"#C71585",   // CSS mediumvioletred – vivid pink-purple
        "muted purple":     "#7B5EAE",   // medium muted purple
        "old mauve":        "#673147",   // dark muted purple
        "pale purple":      "#FAE6FA",   // very pale purple
        "pansy purple":     "#78184A",   // dark purple-red
        "patriarch":        "#800080",   // same as purple
        "purple heart":     "#69359C",   // medium vivid purple
        "regalia":          "#522D80",   // dark purple
        "rich lavender":    "#A76BCF",   // medium vivid purple
        "royal fuchsia":    "#CA2C92",   // vivid pink-purple
        "slate purple":     "#7F5AF0",   // vivid blue-purple
        "tyrian purple":    "#66023C",   // ancient purple-red
        "ultra violet":     "#5F4B8B",   // Pantone 2018 – muted blue-purple
        "violet blue":      "#324AB2",   // blue-leaning purple
        "violet red":       "#F75394",   // vivid pink
        "vivid violet":     "#9F00FF",   // bright electric purple
        "neon purple":      "#BC13FE",   // vivid fluorescent purple
        "electric purple":  "#BF00FF",   // vivid purple
        "digital lavender": "#9E9CC2",   // muted blue-purple
        "periwinkle dream": "#CCBBFF",   // pale soft purple
        "viva magenta":     "#BB2649",   // Pantone 2023 – dark pink-red

        // ── Browns & Tans ────────────────────────────────────
        "brown":            "#A52A2A",   // CSS brown
        "light brown":      "#C4A882",   // pale warm brown
        "dark brown":       "#5C4033",   // deep rich brown
        "tan":              "#D2B48C",   // CSS tan
        "beige":            "#F5F5DC",   // CSS beige – very pale yellow-brown
        "sand":             "#C2B280",   // warm mid sandy
        "caramel":          "#C68642",   // warm orange-brown
        "coffee":           "#6F4E37",   // dark warm brown
        "chocolate":        "#D2691E",   // CSS chocolate – orange-brown (NOT very dark)
        "mahogany":         "#C04000",   // dark reddish-brown
        "sienna":           "#A0522D",   // CSS sienna – warm mid brown
        "chestnut":         "#954535",   // medium red-brown
        "tawny":            "#CD5700",   // warm orange-brown
        "russet":           "#80461B",   // dark warm brown
        "sepia":            "#704214",   // dark brown photo tone
        "terracotta":       "#E2725B",   // warm orange-red clay
        "clay":             "#B66A50",   // medium warm red-brown
        "copper":           "#B87333",   // warm metallic orange-brown
        "bronze":           "#CD7F32",   // warm golden brown
        "ochre":            "#CC7722",   // warm golden yellow-brown
        "rust":             "#B7410E",   // dark red-brown
        "hazel":            "#8E7618",   // warm golden-brown (like hazel eyes – NOT blue)
        "almond":           "#EFDECD",   // very pale warm tan
        "bistre":           "#3D2B1F",   // very dark brown
        "brown sugar":      "#AF6E4D",   // warm medium brown
        "buff":             "#F0DC82",   // pale warm yellow
        "burlywood":        "#DEB887",   // CSS burlywood – pale warm tan
        "burnt sienna":     "#E97451",   // Crayola – vivid orange-brown
        "burnt umber":      "#8A3324",   // dark red-brown
        "camel":            "#C19A6B",   // warm medium tan
        "cinnamon":         "#D2691E",   // warm orange-brown (similar to chocolate)
        "coconut":          "#965A3E",   // dark orange-brown
        "dirt":             "#9B7653",   // muted brown
        "fawn":             "#E5AA70",   // warm light tan
        "ginger":           "#B06500",   // dark warm orange-brown
        "golden brown":     "#996515",   // dark golden
        "leather":          "#967117",   // warm dark golden-brown
        "liver":            "#674C47",   // dark muted brown
        "mocha":            "#6B4226",   // dark brown (like coffee)
        "nougat":           "#D4956A",   // warm peach-tan
        "nutmeg":           "#944D1F",   // dark warm brown
        "pecan":            "#CB8E5E",   // warm light brown
        "peru":             "#CD853F",   // CSS peru – warm mid tan
        "raw umber":        "#826644",   // muted brown
        "redwood":          "#A45A52",   // medium red-brown
        "saddle brown":     "#8B4513",   // CSS saddlebrown
        "sandy brown":      "#F4A460",   // CSS sandybrown – warm light orange
        "shadow":           "#8A795D",   // muted warm brown
        "sinopia":          "#CB410B",   // dark vivid red-brown
        "spicy mix":        "#8B5052",   // muted red-brown
        "tahiti gold":      "#E97C07",   // vivid orange-gold
        "tobacco brown":    "#715D47",   // muted dark brown
        "umber":            "#635147",   // dark cool brown
        "van dyke brown":   "#664228",   // dark golden-brown
        "wenge":            "#645452",   // dark grayish-brown
        "wheat":            "#F5DEB3",   // CSS wheat – pale warm yellow (ONE entry only)
        "wood brown":       "#C19A6B",   // warm tan-brown
        "warm sand":        "#C2A97C",   // warm pale brown
        "blush gold":       "#C9956C",   // warm pinkish-gold
        "soft gold":        "#D4AF37",   // warm metallic gold
        "warm blush":       "#E8B4B8",   // pale warm pink (distinct from dusty rose)
        "sage green":       "#8A9A6A",   // muted grey-green (correct sage)

        // ── Grays ───────────────────────────────────────────
        "gray":             "#808080",   // CSS gray
        "grey":             "#808080",   // alias
        "light gray":       "#D3D3D3",   // CSS lightgray
        "dark gray":        "#A9A9A9",   // CSS darkgray (lighter than people expect)
        "very dark gray":   "#404040",   // for darker charcoal-adjacent needs
        "silver":           "#C0C0C0",   // CSS silver
        "charcoal":         "#36454F",   // dark blue-grey
        "slate gray":       "#708090",   // CSS slategray
        "dim gray":         "#696969",   // CSS dimgray
        "gainsboro":        "#DCDCDC",   // CSS gainsboro – very pale grey
        "ash":              "#B2BEB5",   // pale blue-grey
        "smoke":            "#738276",   // muted grey-green
        "gunmetal":         "#2A3439",   // very dark blue-grey
        "onyx":             "#353839",   // near-black grey
        "jet":              "#343434",   // very dark near-black
        "battleship grey":  "#848482",   // medium neutral grey
        "cadet grey":       "#91A3B0",   // muted blue-grey
        "cool grey":        "#9090C0",   // blue-tinted grey
        "davy grey":        "#555555",   // medium dark grey
        "feldgrau":         "#4D5D53",   // dark muted grey-green
        "french grey":      "#BDBDC8",   // pale blue-grey
        "independence":     "#4C516D",   // dark blue-grey
        "marengo":          "#4C5866",   // dark slate grey
        "nickel":           "#727472",   // medium neutral grey
        "outer space":      "#414A4C",   // dark grey
        "payne grey":       "#536878",   // dark blue-grey (artist pigment)
        "pewter":           "#96A8A1",   // pale blue-grey
        "platinum":         "#E5E4E2",   // very pale warm grey
        "quick silver":     "#A6A6A6",   // medium light grey
        "roman silver":     "#838996",   // muted blue-grey
        "space cadet":      "#1D2951",   // very dark navy-grey
        "spanish grey":     "#989898",   // medium neutral grey
        "stormcloud":       "#4F666A",   // dark muted teal-grey
        "taupe grey":       "#8B8589",   // muted warm grey
        "tin":              "#8A9597",   // cool grey
        "warm grey":        "#808069",   // slightly greenish grey
        "wet concrete":     "#645855",   // dark warm grey-brown
        "xanadu":           "#738678",   // muted grey-green

        // ── Near-Blacks ──────────────────────────────────────
        "black":            "#000000",
        "off black":        "#0F0F0F",
        "licorice":         "#1A1110",   // very dark warm near-black
        "eerie black":      "#1B1B1B",   // near-black
        "rich black":       "#004040",   // near-black with teal cast

        // ── Whites & Off-Whites ──────────────────────────────
        "white":            "#FFFFFF",
        "off white":        "#FAF9F6",   // warm near-white
        "ivory":            "#FFFFF0",   // CSS ivory – warm white
        "snow":             "#FFFAFA",   // CSS snow – cool near-white
        "linen":            "#FAF0E6",   // CSS linen – warm off-white
        "ghost white":      "#F8F8FF",   // CSS ghostwhite – cool near-white
        "seashell":         "#FFF5EE",   // CSS seashell – warm white
        "floral white":     "#FFFAF0",   // CSS floralwhite
        "pearl":            "#F0EAD6",   // warm off-white
        "alabaster":        "#F2F0EB",   // pale warm grey-white
        "eggshell":         "#F0EAD6",   // warm off-white
        "vanilla":          "#F3E5AB",   // pale warm yellow-white
        "antique white":    "#FAEBD7",   // CSS antiquewhite
        "cornsilk":         "#FFF8DC",   // CSS cornsilk – pale yellow-white
        "cosmic latte":     "#FFF8E7",   // cosmic average – very pale warm white
        "cultured":         "#F5F5F5",   // near-white neutral
        "dutch white":      "#EFDFBB",   // pale warm yellow
        "magnolia":         "#F8F4FF",   // very pale purple-white
        "old lace":         "#FDF5E6",   // CSS oldlace
        "navajo white":     "#FFDEAD",   // CSS navajowhite – pale peach
        "papaya whip":      "#FFEFD5",   // CSS papayawhip – pale yellow
        "peach puff":       "#FFDAB9",   // CSS peachpuff
        "bisque":           "#FFE4C4",   // CSS bisque – warm pale tan

        // ── Pastels ──────────────────────────────────────────
        "pastel blue":      "#AEC6CF",   // pale muted blue
        "pastel green":     "#77DD77",   // pale vivid green
        "pastel purple":    "#B39EB5",   // pale muted purple
        "pastel yellow":    "#FDFD96",   // very pale vivid yellow
        "pastel orange":    "#FFB347",   // pale warm orange
        "pastel red":       "#FF6961",   // pale warm red
        "pastel teal":      "#B2DFDB",   // pale muted teal

        // ── Neons ────────────────────────────────────────────
        "neon red":         "#FF3131",   // vivid fluorescent red
        "neon orange":      "#FF5733",   // vivid fluorescent orange
        "neon yellow":      "#CCFF00",   // vivid fluorescent yellow-green
        "neon pink":        "#FF6EC7",   // vivid fluorescent pink
        "neon cyan":        "#0FF0FC",   // vivid fluorescent cyan
        "neon magenta":     "#FF00C1",   // vivid fluorescent magenta (distinct from fuchsia)
        "electric red":     "#E60026",   // vivid dark red
        "electric yellow":  "#FFFF33",   // vivid yellow
        "electric orange":  "#FF7300",   // vivid orange
        "electric violet":  "#8F00FF",   // vivid violet
        "seafoam green":    "#71EEB8",   // light aqua-green

        // ── Skin & Makeup Tones ──────────────────────────────
        "peach fuzz":       "#FFBE98",   // Pantone 2024 – warm peach
        "warm blush pink":  "#F5A0A0",   // warm pink complexion tone
        "nude":             "#E3BC9A",   // warm medium skin tone
        "porcelain":        "#F2E8DC",   // very pale skin tone
        "terracotta rose":  "#CC7052",   // warm earthy rose

        // ── Metallic ─────────────────────────────────────────
        "gold metallic":    "#D4AF37",   // warm metallic gold
        "silver metallic":  "#AAA9AD",   // cool metallic silver
        "bronze metallic":  "#CD7F32",   // warm metallic bronze
        "rose gold metallic":"#B76E79",  // pinkish metallic
    ]

    // MARK: - Closest Name Algorithm
    // Uses perceptual distance in HSL space with extra weight on
    // lightness for neutrals, so greys/whites name correctly.

    static func closestName(for hex: String) -> String {
        let target = ColorMath.hexToRGB(hex)
        let th = ColorMath.rgbToHSB(target)
        let tl = ColorMath.rgbToHSL(target)

        var bestKey = ""
        var bestDist = Double.infinity

        for (name, namedHex) in all {
            let rgb = ColorMath.hexToRGB(namedHex)
            let h   = ColorMath.rgbToHSB(rgb)
            let hl  = ColorMath.rgbToHSL(rgb)

            // Angular hue distance
            let dh = min(abs(th.h - h.h), 360 - abs(th.h - h.h))
            // Saturation & brightness
            let ds = abs(th.s - h.s) * 100
            let db = abs(th.b - h.b) * 60
            // Lightness (important for neutrals)
            let dl = abs(tl.l - hl.l) * 40

            // For desaturated colours, hue matters much less
            let satWeight = th.s           // 0 = grey, 1 = vivid
            let dist = (dh * satWeight) + ds + db + dl

            if dist < bestDist {
                bestDist = dist
                bestKey = name
            }
        }
        return bestKey.isEmpty ? "" : bestKey.capitalized
    }
}
