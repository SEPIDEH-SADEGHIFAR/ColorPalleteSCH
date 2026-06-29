import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - DISCOVER VIEW
// ═════════════════════════════════════════════════════════════

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
    @State private var isExploring = false               // background-task guard
    @State private var recentlyExplored: [RecentColor] = []  // session history

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

                        // Recent history bar (shows once there's history)
                        if !recentlyExplored.isEmpty && exploredColor == nil && !searchHadNoResults {
                            recentHistoryBar
                                .padding(.top, 18)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if isExploring {
                            exploringSpinner.padding(.top, 80)
                        } else if let explored = exploredColor {
                            exploredColorSection(explored: explored)
                                .padding(.top, 28)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else if searchHadNoResults {
                            noResultsState.padding(.top, 80)
                        } else {
                            emptyState.padding(.top, 60)
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { animateIn = true }
            }
            .sheet(isPresented: $showColorPicker) {
                ColorPickerSheet(selectedColor: $pickedColor) {
                    searchHadNoResults = false
                    exploreColorAsync(pickedColor)
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

                    TextField("Try \"pink\", \"navy\", \"#FF6B6B\", \"rgb(255,100,50)\"...", text: $searchText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("AppText"))
                        .tint(Color("AppText"))
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                        .onChange(of: searchText) { newValue in
                            searchHadNoResults = false
                            let stripped = newValue.trimmingCharacters(in: .whitespaces)
                            // Auto-search on complete hex
                            if stripped.hasPrefix("#") && stripped.count == 7 { performSearch() }
                            else if !stripped.hasPrefix("#") && stripped.count == 6 &&
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
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("AppText").opacity(0.08), lineWidth: 1))
                )

                Button { showColorPicker = true } label: {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("AppBackground"))
                        .frame(width: 50, height: 50)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("AppText")))
                }
            }

            // Quick preset chips
            if exploredColor == nil && searchText.isEmpty && !isExploring {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ColorNameDictionary.quickPresets, id: \.hex) { preset in
                            Button {
                                searchHadNoResults = false
                                exploreColorAsync(Color(hex: preset.hex))
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

    // MARK: - Recent History Bar

    private var recentHistoryBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECENTLY EXPLORED")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color("AppText").opacity(0.3))
                .padding(.horizontal, 22)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentlyExplored) { recent in
                        Button {
                            exploreColorAsync(Color(hex: recent.hex))
                        } label: {
                            VStack(spacing: 5) {
                                Circle()
                                    .fill(Color(hex: recent.hex))
                                    .frame(width: 44, height: 44)
                                    .overlay(Circle().stroke(Color("AppText").opacity(0.08), lineWidth: 1))
                                    .shadow(color: Color(hex: recent.hex).opacity(0.35), radius: 6, y: 3)
                                Text(recent.name)
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(Color("AppText").opacity(0.45))
                                    .lineLimit(1)
                                    .frame(width: 52)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 4)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.15), value: animateIn)
    }

    // MARK: - Exploring Spinner

    private var exploringSpinner: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color("AppText").opacity(0.4))
            Text("Exploring color…")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.35))
        }
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
                Text("Search by name, hex, rgb(), or hsl()")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 8) {
                Text("Try searching for:")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color("AppText").opacity(0.25))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["pink", "forest green", "lavender", "crimson", "rgb(255,107,107)", "hsl(200,80%,50%)"], id: \.self) { term in
                            Button {
                                searchText = term
                                performSearch()
                            } label: {
                                Text(term)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color("AppText").opacity(0.5))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().stroke(Color("AppText").opacity(0.15), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.horizontal, 22)
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
                Text("\"\(searchText)\" didn't match anything.\nTry a hex like #FF6B6B, rgb(255,107,107),\nor hsl(0,100%,67%)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.35))
                    .multilineTextAlignment(.center)
            }
            Button { showColorPicker = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "eyedropper.halffull").font(.system(size: 14, weight: .semibold))
                    Text("Pick a Color Instead").font(.system(size: 14, weight: .semibold, design: .rounded))
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
            colorRangeSection(title: "Tints",         subtitle: "Lighter variations",   colors: explored.tints,         icon: "sun.max.fill",                baseHex: explored.hex)
            colorRangeSection(title: "Shades",        subtitle: "Darker variations",    colors: explored.shades,        icon: "moon.fill",                   baseHex: explored.hex)
            colorRangeSection(title: "Analogous",     subtitle: "Neighboring hues",     colors: explored.analogous,     icon: "circle.hexagongrid.fill",     baseHex: nil)
            colorRangeSection(title: "Complementary", subtitle: "Opposite contrasts",   colors: explored.complementary, icon: "arrow.triangle.2.circlepath", baseHex: nil)
            colorRangeSection(title: "Triadic",       subtitle: "Three-way harmony",    colors: explored.triadic,       icon: "triangle",                    baseHex: nil)
            colorRangeSection(title: "Split",         subtitle: "Near-complement pair", colors: explored.split,         icon: "arrow.branch",                baseHex: nil)
        }
    }

    // MARK: - Exact Match Card

    private func exactMatchCard(explored: ExploredColor) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(explored.color)
                    .frame(height: 200)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color("AppText").opacity(0.08), lineWidth: 1))
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

                // HEX + RGB + HSL chips — all three copyable
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CopyableChip(icon: "number",               label: explored.hex.uppercased(),  value: explored.hex.uppercased())
                        CopyableChip(icon: "circle.grid.3x3.fill", label: explored.rgbString,         value: explored.rgbString)
                        CopyableChip(icon: "humidity",             label: explored.hslString,         value: explored.hslString)
                        CopyableChip(icon: "paintpalette",         label: explored.labString,         value: explored.labString)
                    }
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
    // baseHex: when set (tints/shades), we suppress the name if it's the
    //          same as the base, showing a tint/shade label instead.

    private func colorRangeSection(title: String, subtitle: String, colors: [ColorSwatch], icon: String, baseHex: String?) -> some View {
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
                    ForEach(Array(colors.enumerated()), id: \.element.hex) { idx, swatch in
                        SwatchCard(
                            swatch: swatch,
                            displayLabel: swatchLabel(swatch: swatch, index: idx, total: colors.count,
                                                      title: title, baseHex: baseHex),
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

    /// Decides what label to show on a swatch.
    /// For tints/shades, shows a percentage instead of the colour name
    /// when the name would be identical to the base colour name.
    private func swatchLabel(swatch: ColorSwatch, index: Int, total: Int, title: String, baseHex: String?) -> String {
        guard let baseHex else { return swatch.name }
        let baseName = ColorNameDictionary.closestName(for: baseHex)
        if swatch.name.lowercased() == baseName.lowercased() {
            // e.g. "20% Tint" / "30% Shade"
            let pct = Int(Double(index + 1) / Double(total) * 100)
            let kind = title == "Tints" ? "Tint" : "Shade"
            return "\(pct)% \(kind)"
        }
        return swatch.name
    }

    // MARK: - Create Palette Button

    private var createPaletteButton: some View {
        Button { createPaletteFromSelection() } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill").font(.system(size: 17, weight: .semibold))
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

    // MARK: - Saved Confirmation

    private var savedConfirmationOverlay: some View {
        Group {
            if showSavedConfirmation {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
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

    // MARK: - Search Logic (scored matching)

    private func performSearch() {
        let raw = searchText.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }

        // 1. Full hex with #
        if raw.hasPrefix("#") && raw.count == 7 {
            searchHadNoResults = false
            exploreColorAsync(Color(hex: raw))
            return
        }
        // 2. Hex without #
        if raw.count == 6 && raw.allSatisfy({ "0123456789ABCDEFabcdef".contains($0) }) {
            searchHadNoResults = false
            exploreColorAsync(Color(hex: "#\(raw)"))
            return
        }
        // 3. rgb(r, g, b)
        if let color = ColorParser.parseRGB(raw) {
            searchHadNoResults = false
            exploreColorAsync(color)
            return
        }
        // 4. hsl(h, s%, l%)
        if let color = ColorParser.parseHSL(raw) {
            searchHadNoResults = false
            exploreColorAsync(color)
            return
        }
        // 5. Named color — scored match (exact → startsWith → contains, shorter wins)
        let lowered = raw.lowercased()
        let dict = ColorNameDictionary.all

        struct Match { let key: String; let hex: String; let score: Int }
        var matches: [Match] = []

        for (name, hex) in dict {
            if name == lowered               { matches.append(Match(key: name, hex: hex, score: 0)) }
            else if name.hasPrefix(lowered)  { matches.append(Match(key: name, hex: hex, score: 1 + name.count)) }
            else if name.contains(lowered)   { matches.append(Match(key: name, hex: hex, score: 2 + name.count)) }
            else if lowered.contains(name)   { matches.append(Match(key: name, hex: hex, score: 3 + name.count)) }
        }

        if let best = matches.sorted(by: { $0.score < $1.score }).first {
            searchHadNoResults = false
            if best.score > 0 { searchText = best.key.capitalized }
            exploreColorAsync(Color(hex: best.hex))
            return
        }

        withAnimation(.spring(response: 0.4)) {
            searchHadNoResults = true
            exploredColor = nil
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Async Explore (off main thread)

    private func exploreColorAsync(_ color: Color) {
        guard !isExploring else { return }
        withAnimation(.spring(response: 0.3)) {
            isExploring = true
            exploredColor = nil
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task.detached(priority: .userInitiated) {
            let result = ColorMath.explore(color: color)
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) {
                    exploredColor = result
                    isExploring = false
                }
                addToRecent(hex: result.hex, name: result.name)
            }
        }
    }

    private func addToRecent(hex: String, name: String) {
        recentlyExplored.removeAll { $0.hex == hex }
        recentlyExplored.insert(RecentColor(hex: hex, name: name), at: 0)
        if recentlyExplored.count > 8 { recentlyExplored.removeLast() }
    }

    private func toggleSelection(hex: String, name: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedSwatches[hex] != nil { selectedSwatches.removeValue(forKey: hex) }
            else { selectedSwatches[hex] = name }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func createPaletteFromSelection() {
        guard !selectedSwatches.isEmpty else { return }
        let colors = selectedSwatches.prefix(8).map { SavedColor(name: $0.value, hex: $0.key) }
        let title = exploredColor?.name.capitalized ?? "Discovered Palette"
        modelContext.insert(SavedPalette(title: title, colors: Array(colors)))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showSavedConfirmation = true; selectedSwatches.removeAll() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showSavedConfirmation = false }
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - RECENT COLOR MODEL
// ═════════════════════════════════════════════════════════════

struct RecentColor: Identifiable {
    let id = UUID()
    let hex: String
    let name: String
}

// ═════════════════════════════════════════════════════════════
// MARK: - COPYABLE CHIP  (tap to copy value)
// ═════════════════════════════════════════════════════════════

struct CopyableChip: View {
    let icon: String
    let label: String
    let value: String
    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = value
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3)) { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { copied = false }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: copied ? "checkmark" : icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(copied ? Color.green : Color("AppText").opacity(0.35))
                Text(copied ? "Copied!" : label)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(copied ? Color.green : Color("AppText").opacity(0.55))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(copied ? Color.green.opacity(0.1) : Color("AppText").opacity(0.06)))
            .animation(.spring(response: 0.3), value: copied)
        }
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - SWATCH CARD
// ═════════════════════════════════════════════════════════════

struct SwatchCard: View {
    let swatch: ColorSwatch
    let displayLabel: String   // may differ from swatch.name for tints/shades
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
                            .stroke(isSelected ? Color("AppBackground") : Color("AppText").opacity(0.08),
                                    lineWidth: isSelected ? 3 : 1)
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
                if !displayLabel.isEmpty {
                    Text(displayLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color("AppText"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(swatch.hex.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(displayLabel.isEmpty ? 0.8 : 0.4))
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
    @State private var hValue: Double = 0    // 0–360
    @State private var sValue: Double = 0    // 0–100
    @State private var lValue: Double = 0    // 0–100
    @State private var inputMode: InputMode = .wheel
    @State private var updatingFromSlider = false
    @FocusState private var hexFieldFocused: Bool

    enum InputMode: String, CaseIterable {
        case wheel = "Wheel"
        case rgb = "RGB"
        case hsl = "HSL"
        case palettes = "Palettes"
    }

    private let paletteRows: [(name: String, hexes: [String])] = [
        ("Warm",    ["#FF6B6B", "#FF7F50", "#FFA500", "#FFD700", "#FFECB3"]),
        ("Cool",    ["#6C63FF", "#3B82F6", "#00BFFF", "#00CED1", "#20B2AA"]),
        ("Earth",   ["#8B4513", "#A0522D", "#CD853F", "#D2B48C", "#F4A460"]),
        ("Pastel",  ["#FFB3BA", "#FFDFBA", "#FFFFBA", "#BAFFC9", "#BAE1FF"]),
        ("Deep",    ["#1A0533", "#1D2671", "#134E5E", "#0B3D2E", "#1C0A00"]),
        ("Neon",    ["#FF003F", "#FF6700", "#CCFF00", "#00FF41", "#00CFFF"]),
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
                        colorHero.padding(.top, 8).padding(.horizontal, 20)

                        // Mode tabs
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(InputMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Group {
                            switch inputMode {
                            case .wheel:    wheelSection
                            case .rgb:      rgbSlidersSection
                            case .hsl:      hslSlidersSection
                            case .palettes: palettesSection
                            }
                        }
                        .padding(.top, 20)

                        hexInputSection.padding(.top, 20).padding(.horizontal, 20)
                        quickPicksSection.padding(.top, 24).padding(.horizontal, 20)
                        Spacer(minLength: 120)
                    }
                }
                VStack { Spacer(); confirmButton }
            }
            .navigationTitle("Pick a Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .onAppear { syncFromColor(selectedColor) }
            .onChange(of: selectedColor) { if !updatingFromSlider { syncFromColor($0) } }
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

    // MARK: Wheel

    private var wheelSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("COLOR WHEEL").padding(.horizontal, 20)
            HStack {
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.3)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: RGB Sliders

    private var rgbSlidersSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("RGB SLIDERS").padding(.horizontal, 20)
            VStack(spacing: 16) {
                pickerSlider(label: "R", value: $rValue, range: 0...255, trackColor: .red)
                pickerSlider(label: "G", value: $gValue, range: 0...255, trackColor: .green)
                pickerSlider(label: "B", value: $bValue, range: 0...255, trackColor: .blue)
            }
            .padding(.horizontal, 20)
            .onChange(of: rValue) { _ in applyRGB() }
            .onChange(of: gValue) { _ in applyRGB() }
            .onChange(of: bValue) { _ in applyRGB() }
        }
    }

    // MARK: HSL Sliders

    private var hslSlidersSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("HSL SLIDERS").padding(.horizontal, 20)
            VStack(spacing: 16) {
                pickerSlider(label: "H", value: $hValue, range: 0...360,
                             trackColor: Color(hue: hValue/360, saturation: 1, brightness: 1),
                             unit: "°")
                pickerSlider(label: "S", value: $sValue, range: 0...100,
                             trackColor: Color(hue: hValue/360, saturation: sValue/100, brightness: 0.8),
                             unit: "%")
                pickerSlider(label: "L", value: $lValue, range: 0...100,
                             trackColor: Color(white: lValue/100),
                             unit: "%")
            }
            .padding(.horizontal, 20)
            .onChange(of: hValue) { _ in applyHSL() }
            .onChange(of: sValue) { _ in applyHSL() }
            .onChange(of: lValue) { _ in applyHSL() }
        }
    }

    private func pickerSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>,
                               trackColor: Color, unit: String = "") -> some View {
        HStack(spacing: 14) {
            Text(label)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(trackColor)
                .frame(width: 16)
            Slider(value: value, in: range, step: 1)
                .tint(trackColor)
            Text("\(Int(value.wrappedValue))\(unit)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AppText").opacity(0.5))
                .frame(width: unit.isEmpty ? 30 : 42, alignment: .trailing)
        }
    }

    // MARK: Palettes

    private var palettesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("CURATED PALETTES").padding(.horizontal, 20)
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
                                    withAnimation(.spring(response: 0.3)) { selectedColor = Color(hex: hex) }
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
                            if clean.count == 6 { selectedColor = Color(hex: "#\(clean)") }
                        }
                        .onSubmit { if hexInput.count < 6 { withAnimation { hexIsInvalid = true } } }
                    if hexIsInvalid {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red).font(.system(size: 16))
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(hexIsInvalid ? Color.red.opacity(0.5) : Color("AppText").opacity(0.08), lineWidth: 1))
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
                        withAnimation(.spring(response: 0.3)) { selectedColor = Color(hex: hex) }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        let isActive = selectedColor.toHex()?.uppercased() == hex.uppercased()
                        Circle()
                            .fill(Color(hex: hex))
                            .overlay(Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                            .overlay(Circle().stroke(Color("AppText").opacity(0.8), lineWidth: 2.5)
                                .scaleEffect(isActive ? 1.2 : 1).opacity(isActive ? 1 : 0))
                            .animation(.spring(response: 0.25), value: isActive)
                    }
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: Confirm

    private var confirmButton: some View {
        Button { onConfirm(); dismiss() } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.25), lineWidth: 1))
                Text("Explore This Color")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppBackground"))
            }
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color("AppText"))
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
            )
        }
        .padding(.horizontal, 20).padding(.bottom, 28)
        .background(
            LinearGradient(colors: [Color("AppBackground").opacity(0), Color("AppBackground")],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea().allowsHitTesting(false)
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
        let hex = color.toHex() ?? "#000000"
        hexInput = hex.replacingOccurrences(of: "#", with: "").uppercased()
        let rgb = ColorMath.hexToRGB(hex)
        rValue = Double(rgb.r); gValue = Double(rgb.g); bValue = Double(rgb.b)
        let hsl = ColorMath.rgbToHSL(rgb)
        hValue = hsl.h; sValue = hsl.s * 100; lValue = hsl.l * 100
    }

    private func applyRGB() {
        updatingFromSlider = true
        let hex = ColorMath.rgbToHex(r: Int(rValue), g: Int(gValue), b: Int(bValue))
        selectedColor = Color(hex: hex)
        hexInput = hex.replacingOccurrences(of: "#", with: "").uppercased()
        let hsl = ColorMath.rgbToHSL((r: Int(rValue), g: Int(gValue), b: Int(bValue)))
        hValue = hsl.h; sValue = hsl.s * 100; lValue = hsl.l * 100
        updatingFromSlider = false
    }

    private func applyHSL() {
        updatingFromSlider = true
        let rgb = ColorMath.hslToRGB(h: hValue, s: sValue / 100, l: lValue / 100)
        let hex = ColorMath.rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
        selectedColor = Color(hex: hex)
        hexInput = hex.replacingOccurrences(of: "#", with: "").uppercased()
        rValue = Double(rgb.r); gValue = Double(rgb.g); bValue = Double(rgb.b)
        updatingFromSlider = false
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - COLOR PARSER  (rgb() and hsl() string input)
// ═════════════════════════════════════════════════════════════

enum ColorParser {

    /// Parses "rgb(255, 107, 107)" or "rgb(255 107 107)"
    static func parseRGB(_ input: String) -> Color? {
        let cleaned = input.lowercased()
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ",", with: " ")
        let parts = cleaned.split(separator: " ").compactMap { Double($0) }
        guard parts.count == 3 else { return nil }
        let r = max(0, min(255, parts[0]))
        let g = max(0, min(255, parts[1]))
        let b = max(0, min(255, parts[2]))
        return Color(red: r/255, green: g/255, blue: b/255)
    }

    /// Parses "hsl(200, 80%, 50%)" or "hsl(200 80% 50%)"
    static func parseHSL(_ input: String) -> Color? {
        let cleaned = input.lowercased()
            .replacingOccurrences(of: "hsl(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: ",", with: " ")
        let parts = cleaned.split(separator: " ").compactMap { Double($0) }
        guard parts.count == 3 else { return nil }
        let h = max(0, min(360, parts[0]))
        let s = max(0, min(100, parts[1])) / 100
        let l = max(0, min(100, parts[2])) / 100
        let rgb = ColorMath.hslToRGB(h: h, s: s, l: l)
        return Color(red: Double(rgb.r)/255, green: Double(rgb.g)/255, blue: Double(rgb.b)/255)
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - COLOR SWATCH MODEL
// ═════════════════════════════════════════════════════════════

struct ColorSwatch: Identifiable {
    let id = UUID()
    let hex: String
    var name: String = ""
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
    let labString: String      // CIELAB values for display
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
        let hsl = rgbToHSL(rgb)
        let hsb = rgbToHSB(rgb)
        let lab = rgbToLab(rgb)

        return ExploredColor(
            color:         color,
            hex:           hex,
            name:          ColorNameDictionary.closestName(for: hex),
            rgbString:     "RGB \(rgb.r) \(rgb.g) \(rgb.b)",
            hslString:     "HSL \(Int(hsl.h))° \(Int(hsl.s * 100))% \(Int(hsl.l * 100))%",
            labString:     "L\(Int(lab.l)) a\(Int(lab.a)) b\(Int(lab.b))",
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
        [-60, -45, -30, -15, 15, 30, 45, 60].map { offset -> ColorSwatch in
            let rgb = hsbToRGB(h: wrap(hsb.h + Double(offset)), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateComplementary(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [165, 172.5, 180, 187.5, 195].map { offset -> ColorSwatch in
            let rgb = hsbToRGB(h: wrap(hsb.h + offset), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateTriadic(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [100, 110, 120, 240, 250, 260].map { offset -> ColorSwatch in
            let rgb = hsbToRGB(h: wrap(hsb.h + Double(offset)), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    static func generateSplit(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        [140, 150, 160, 200, 210, 220].map { offset -> ColorSwatch in
            let rgb = hsbToRGB(h: wrap(hsb.h + Double(offset)), s: hsb.s, b: hsb.b)
            let hex = rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
            return ColorSwatch(hex: hex, name: ColorNameDictionary.closestName(for: hex))
        }
    }

    // MARK: - Conversions

    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (r: Int((value >> 16) & 0xFF), g: Int((value >> 8) & 0xFF), b: Int(value & 0xFF))
    }

    static func rgbToHex(r: Int, g: Int, b: Int) -> String {
        String(format: "#%02X%02X%02X", max(0,min(255,r)), max(0,min(255,g)), max(0,min(255,b)))
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
        case 0..<60:    t=(c,x,0)
        case 60..<120:  t=(x,c,0)
        case 120..<180: t=(0,c,x)
        case 180..<240: t=(0,x,c)
        case 240..<300: t=(x,0,c)
        default:        t=(c,0,x)
        }
        return (r:Int((t.0+m)*255), g:Int((t.1+m)*255), b:Int((t.2+m)*255))
    }

    /// HSL → RGB  (needed for HSL sliders and hsl() search parsing)
    static func hslToRGB(h: Double, s: Double, l: Double) -> (r: Int, g: Int, b: Int) {
        if s == 0 {
            let v = Int(l * 255)
            return (r: v, g: v, b: v)
        }
        func hue2rgb(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1/6 { return p + (q-p)*6*t }
            if t < 1/2 { return q }
            if t < 2/3 { return p + (q-p)*(2/3-t)*6 }
            return p
        }
        let q = l < 0.5 ? l*(1+s) : l+s - l*s
        let p = 2*l - q
        let hN = h/360
        return (r: Int(hue2rgb(p,q,hN+1/3)*255),
                g: Int(hue2rgb(p,q,hN)*255),
                b: Int(hue2rgb(p,q,hN-1/3)*255))
    }

    // MARK: - CIELAB conversion
    // sRGB → linear RGB → XYZ (D65) → CIELAB

    static func rgbToLab(_ rgb: (r: Int, g: Int, b: Int)) -> (l: Double, a: Double, b: Double) {
        func linearise(_ c: Double) -> Double {
            c <= 0.04045 ? c/12.92 : pow((c+0.055)/1.055, 2.4)
        }
        let r = linearise(Double(rgb.r)/255)
        let g = linearise(Double(rgb.g)/255)
        let b = linearise(Double(rgb.b)/255)

        // sRGB → XYZ (D65 illuminant, IEC 61966-2-1)
        let x = r*0.4124564 + g*0.3575761 + b*0.1804375
        let y = r*0.2126729 + g*0.7151522 + b*0.0721750
        let z = r*0.0193339 + g*0.1191920 + b*0.9503041

        // Normalise to D65 white point
        let xn = x/0.95047, yn = y/1.00000, zn = z/1.08883

        func f(_ t: Double) -> Double {
            t > pow(6.0/29, 3) ? pow(t, 1.0/3) : (t / (3 * pow(6.0/29, 2))) + 4.0/29
        }
        let l = 116*f(yn) - 16
        let a = 500*(f(xn) - f(yn))
        let bv = 200*(f(yn) - f(zn))
        return (l: l, a: a, b: bv)
    }

    /// CIELAB ΔE (CIE76) — perceptually uniform Euclidean distance
    static func deltaE(_ lab1: (l: Double, a: Double, b: Double),
                       _ lab2: (l: Double, a: Double, b: Double)) -> Double {
        let dl = lab1.l - lab2.l
        let da = lab1.a - lab2.a
        let db = lab1.b - lab2.b
        return sqrt(dl*dl + da*da + db*db)
    }

    private static func wrap(_ h: Double) -> Double {
        var v = h.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }
}

// ═════════════════════════════════════════════════════════════
// MARK: - COLOR NAME DICTIONARY
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

    // Pre-computed CIELAB cache — built once at first call, then reused
    // for all closestName() calls (avoids re-computing 440 × N times).
    private static var _labCache: [(name: String, lab: (l: Double, a: Double, b: Double))]?
    private static var labCache: [(name: String, lab: (l: Double, a: Double, b: Double))] {
        if let cache = _labCache { return cache }
        let built = all.map { (name: $0.key, lab: ColorMath.rgbToLab(ColorMath.hexToRGB($0.value))) }
        _labCache = built
        return built
    }

    // MARK: - Closest Name using CIELAB ΔE (CIE76)
    // Far more perceptually accurate than HSB distance.
    // Runs on a background thread via Task.detached in exploreColorAsync.

    static func closestName(for hex: String) -> String {
        let targetRGB = ColorMath.hexToRGB(hex)
        let targetLab = ColorMath.rgbToLab(targetRGB)
        var bestName = ""
        var bestDelta = Double.infinity
        for entry in labCache {
            let d = ColorMath.deltaE(targetLab, entry.lab)
            if d < bestDelta { bestDelta = d; bestName = entry.name }
        }
        return bestName.isEmpty ? "" : bestName.capitalized
    }

    static let all: [String: String] = [

        // ── Reds ────────────────────────────────────────────
        "red":              "#FF0000",
        "dark red":         "#8B0000",
        "crimson":          "#DC143C",
        "scarlet":          "#FF2400",
        "ruby":             "#9B111E",
        "firebrick":        "#B22222",
        "tomato":           "#FF6347",
        "indian red":       "#CD5C5C",
        "maroon":           "#800000",
        "burgundy":         "#800020",
        "wine":             "#722F37",
        "blood red":        "#8A0303",
        "brick red":        "#CB4154",
        "candy apple red":  "#FF0800",
        "venetian red":     "#C80815",
        "carmine":          "#960018",
        "cardinal":         "#C41E3A",
        "alizarin":         "#E32636",
        "raspberry":        "#E30B5C",
        "amaranth":         "#E52B50",
        "imperial red":     "#ED2939",
        "lava":             "#CF1020",
        "infrared":         "#FF496C",
        "folly":            "#FF004F",

        // ── Pinks ───────────────────────────────────────────
        "pink":             "#FFC0CB",
        "hot pink":         "#FF69B4",
        "deep pink":        "#FF1493",
        "light pink":       "#FFB6C1",
        "baby pink":        "#F4C2C2",
        "blush":            "#DE5D83",
        "rose":             "#FF007F",
        "flamingo":         "#FC8EAC",
        "carnation":        "#FFA6C9",
        "fuchsia":          "#FF00FF",
        "magenta":          "#CC00CC",
        "orchid":           "#DA70D6",
        "mauve":            "#E0B0FF",
        "bubblegum pink":   "#FFC1CC",
        "salmon pink":      "#FF91A4",
        "dusty rose":       "#C08081",
        "pastel pink":      "#FFD1DC",
        "cerise":           "#DE3163",
        "french rose":      "#F64A8A",
        "ultra pink":       "#FF6FFF",
        "watermelon":       "#FC6C85",
        "cherry blossom":   "#FFB7C5",
        "light coral":      "#F08080",
        "amaranth pink":    "#F19CBB",
        "puce":             "#CC8899",
        "cotton candy":     "#FFBCD9",
        "millennial pink":  "#F4A7B9",
        "punch":            "#FF4D79",
        "rose gold":        "#B76E79",

        // ── Oranges ─────────────────────────────────────────
        "orange":           "#FFA500",
        "dark orange":      "#FF8C00",
        "light orange":     "#FFB347",
        "amber":            "#FFBF00",
        "tangerine":        "#F28500",
        "apricot":          "#FBCEB1",
        "peach":            "#FFCBA4",
        "pumpkin":          "#FF7518",
        "burnt orange":     "#CC5500",
        "coral":            "#FF7F50",
        "tiger orange":     "#FD6A02",
        "mango":            "#FDBE02",
        "cadmium orange":   "#ED872D",
        "atomic tangerine": "#FF9966",
        "deep saffron":     "#FF9933",
        "safety orange":    "#FF6700",
        "harvest gold":     "#DA9100",
        "gamboge":          "#E49B0F",

        // ── Yellows ─────────────────────────────────────────
        "yellow":           "#FFFF00",
        "light yellow":     "#FFFFE0",
        "gold":             "#FFD700",
        "lemon":            "#FFF44F",
        "canary yellow":    "#FFEF00",
        "cream":            "#FFFDD0",
        "butter":           "#FFFD74",
        "banana yellow":    "#FAE7B5",
        "mustard":          "#FFDB58",
        "khaki":            "#F0E68C",
        "dark khaki":       "#BDB76B",
        "straw":            "#E4D96F",
        "champagne":        "#F7E7CE",
        "lemon chiffon":    "#FFFACD",
        "pear":             "#D1E231",
        "citron":           "#9FA91F",
        "golden yellow":    "#FFDF00",
        "aureolin":         "#FDEE00",
        "naples yellow":    "#FADA5E",
        "old gold":         "#CFB53B",
        "saffron":          "#F4C430",
        "school bus yellow":"#FFD800",
        "jasmine":          "#F8DE7E",
        "flax":             "#EEDC82",
        "sandstorm":        "#ECD540",
        "gen z yellow":     "#F5E642",

        // ── Greens ──────────────────────────────────────────
        "green":            "#008000",
        "light green":      "#90EE90",
        "dark green":       "#006400",
        "lime green":       "#32CD32",
        "forest green":     "#228B22",
        "sage":             "#BCB88A",
        "olive":            "#808000",
        "dark olive green": "#556B2F",
        "emerald":          "#50C878",
        "mint":             "#98FF98",
        "seafoam":          "#71EEB8",
        "jade":             "#00A86B",
        "hunter green":     "#355E3B",
        "moss":             "#8A9A5B",
        "fern":             "#4F7942",
        "pistachio":        "#93C572",
        "avocado":          "#568203",
        "chartreuse":       "#7FFF00",
        "spring green":     "#00FF7F",
        "lawn green":       "#7CFC00",
        "bottle green":     "#006A4E",
        "pine green":       "#01796F",
        "viridian":         "#40826D",
        "army green":       "#4B5320",
        "artichoke":        "#8F9779",
        "asparagus":        "#87A96B",
        "celadon":          "#ACE1AF",
        "dollar bill":      "#85BB65",
        "hookers green":    "#49796B",
        "india green":      "#138808",
        "malachite":        "#0BDA51",
        "mantis":           "#74C365",
        "mountain meadow":  "#30BA8F",
        "sea green":        "#2E8B57",
        "shamrock":         "#009E60",
        "tea green":        "#D0F0C0",
        "medium sea green": "#3CB371",
        "pale green":       "#98FB98",
        "yellow green":     "#9ACD32",
        "neon green":       "#39FF14",
        "electric green":   "#00DD00",
        "sage green":       "#8A9A6A",

        // ── Teals & Cyans ───────────────────────────────────
        "teal":             "#008080",
        "dark teal":        "#005F5F",
        "light teal":       "#90D4C5",
        "cyan":             "#00FFFF",
        "aqua":             "#00E5CC",
        "turquoise":        "#40E0D0",
        "dark turquoise":   "#00CED1",
        "medium turquoise": "#48D1CC",
        "cadet blue":       "#5F9EA0",
        "cerulean":         "#007BA7",
        "aquamarine":       "#7FFFD4",
        "tiffany blue":     "#0ABAB5",
        "pale turquoise":   "#AFEEEE",
        "medium aquamarine":"#66CDAA",
        "light sea green":  "#20B2AA",
        "midnight green":   "#004953",
        "viridian green":   "#009698",
        "zomp":             "#39A78E",
        "robin egg blue":   "#00CCCC",
        "calming teal":     "#83C5BE",
        "tropical rain forest": "#00755E",
        "deep sea":         "#095872",
        "cool mint":        "#B2EBF2",

        // ── Blues ───────────────────────────────────────────
        "blue":             "#0000FF",
        "light blue":       "#ADD8E6",
        "dark blue":        "#00008B",
        "sky blue":         "#87CEEB",
        "baby blue":        "#89CFF0",
        "royal blue":       "#4169E1",
        "navy":             "#000080",
        "midnight blue":    "#191970",
        "cobalt blue":      "#0047AB",
        "cornflower blue":  "#6495ED",
        "periwinkle":       "#CCCCFF",
        "steel blue":       "#4682B4",
        "powder blue":      "#B0E0E6",
        "slate blue":       "#6A5ACD",
        "dodger blue":      "#1E90FF",
        "sapphire":         "#0F52BA",
        "azure":            "#007FFF",
        "peacock blue":     "#005F6A",
        "air force blue":   "#5D8AA8",
        "columbia blue":    "#B9D9EB",
        "denim":            "#1560BD",
        "electric blue":    "#7DF9FF",
        "french blue":      "#0072BB",
        "glaucous":         "#6082B6",
        "indigo dye":       "#00416A",
        "international klein blue": "#002FA7",
        "lapis lazuli":     "#26619C",
        "majorelle blue":   "#6050DC",
        "maya blue":        "#73C2FB",
        "medium blue":      "#0000CD",
        "neon blue":        "#1F51FF",
        "oxford blue":      "#002147",
        "persian blue":     "#1C39BB",
        "prussian blue":    "#003153",
        "ultramarine":      "#3F00FF",
        "yale blue":        "#0F4D92",
        "zaffre":           "#0014A8",
        "classic blue":     "#0F4C81",
        "tranquil blue":    "#3C91E6",
        "moody blue":       "#7B7DBF",
        "dusty blue":       "#7393B3",
        "morning mist":     "#C4DFE6",
        "deep sky blue":    "#00BFFF",

        // ── Purples & Violets ────────────────────────────────
        "purple":           "#800080",
        "light purple":     "#B39DDB",
        "dark purple":      "#4A0072",
        "violet":           "#EE82EE",
        "lavender":         "#E6E6FA",
        "dark lavender":    "#967BB6",
        "indigo":           "#4B0082",
        "plum":             "#DDA0DD",
        "thistle":          "#D8BFD8",
        "grape":            "#6F2DA8",
        "eggplant":         "#614051",
        "amethyst":         "#9966CC",
        "lilac":            "#C8A2C8",
        "wisteria":         "#C9A0DC",
        "heliotrope":       "#DF73FF",
        "mulberry":         "#C54B8C",
        "byzantium":        "#702963",
        "royal purple":     "#7851A9",
        "african violet":   "#B284BE",
        "bright lilac":     "#D891EF",
        "cyber grape":      "#58427C",
        "dark orchid":      "#9932CC",
        "dark violet":      "#9400D3",
        "eminence":         "#6C3082",
        "fandango":         "#B53389",
        "french violet":    "#8806CE",
        "glossy grape":     "#AB92B3",
        "halaya ube":       "#663854",
        "han purple":       "#5218FA",
        "imperial purple":  "#66023C",
        "iris":             "#5A4FCF",
        "lavender indigo":  "#9457EB",
        "lavender purple":  "#967BB6",
        "medium orchid":    "#BA55D3",
        "medium purple":    "#9370DB",
        "medium violet red":"#C71585",
        "muted purple":     "#7B5EAE",
        "old mauve":        "#673147",
        "pansy purple":     "#78184A",
        "purple heart":     "#69359C",
        "regalia":          "#522D80",
        "rich lavender":    "#A76BCF",
        "royal fuchsia":    "#CA2C92",
        "slate purple":     "#7F5AF0",
        "tyrian purple":    "#66023C",
        "ultra violet":     "#5F4B8B",
        "violet blue":      "#324AB2",
        "violet red":       "#F75394",
        "vivid violet":     "#9F00FF",
        "neon purple":      "#BC13FE",
        "electric purple":  "#BF00FF",
        "digital lavender": "#9E9CC2",
        "periwinkle dream": "#CCBBFF",
        "viva magenta":     "#BB2649",

        // ── Browns & Tans ────────────────────────────────────
        "brown":            "#A52A2A",
        "light brown":      "#C4A882",
        "dark brown":       "#5C4033",
        "tan":              "#D2B48C",
        "beige":            "#F5F5DC",
        "sand":             "#C2B280",
        "caramel":          "#C68642",
        "coffee":           "#6F4E37",
        "chocolate":        "#D2691E",
        "mahogany":         "#C04000",
        "sienna":           "#A0522D",
        "chestnut":         "#954535",
        "tawny":            "#CD5700",
        "russet":           "#80461B",
        "sepia":            "#704214",
        "terracotta":       "#E2725B",
        "clay":             "#B66A50",
        "copper":           "#B87333",
        "bronze":           "#CD7F32",
        "ochre":            "#CC7722",
        "rust":             "#B7410E",
        "hazel":            "#8E7618",
        "almond":           "#EFDECD",
        "bistre":           "#3D2B1F",
        "brown sugar":      "#AF6E4D",
        "buff":             "#F0DC82",
        "burlywood":        "#DEB887",
        "burnt sienna":     "#E97451",
        "burnt umber":      "#8A3324",
        "camel":            "#C19A6B",
        "cinnamon":         "#D2691E",
        "coconut":          "#965A3E",
        "fawn":             "#E5AA70",
        "ginger":           "#B06500",
        "golden brown":     "#996515",
        "leather":          "#967117",
        "liver":            "#674C47",
        "mocha":            "#6B4226",
        "nougat":           "#D4956A",
        "nutmeg":           "#944D1F",
        "pecan":            "#CB8E5E",
        "peru":             "#CD853F",
        "raw umber":        "#826644",
        "redwood":          "#A45A52",
        "saddle brown":     "#8B4513",
        "sandy brown":      "#F4A460",
        "shadow":           "#8A795D",
        "sinopia":          "#CB410B",
        "spicy mix":        "#8B5052",
        "tahiti gold":      "#E97C07",
        "tobacco brown":    "#715D47",
        "umber":            "#635147",
        "van dyke brown":   "#664228",
        "wenge":            "#645452",
        "wheat":            "#F5DEB3",
        "wood brown":       "#C19A6B",
        "warm sand":        "#C2A97C",
        "blush gold":       "#C9956C",
        "soft gold":        "#D4AF37",
        "warm blush":       "#E8B4B8",
        "peach fuzz":       "#FFBE98",
        "nude":             "#E3BC9A",
        "terracotta rose":  "#CC7052",

        // ── Grays ───────────────────────────────────────────
        "gray":             "#808080",
        "grey":             "#808080",
        "light gray":       "#D3D3D3",
        "dark gray":        "#A9A9A9",
        "very dark gray":   "#404040",
        "silver":           "#C0C0C0",
        "charcoal":         "#36454F",
        "slate gray":       "#708090",
        "dim gray":         "#696969",
        "gainsboro":        "#DCDCDC",
        "ash":              "#B2BEB5",
        "smoke":            "#738276",
        "gunmetal":         "#2A3439",
        "onyx":             "#353839",
        "jet":              "#343434",
        "battleship grey":  "#848482",
        "cadet grey":       "#91A3B0",
        "cool grey":        "#9090C0",
        "davy grey":        "#555555",
        "feldgrau":         "#4D5D53",
        "french grey":      "#BDBDC8",
        "independence":     "#4C516D",
        "marengo":          "#4C5866",
        "nickel":           "#727472",
        "outer space":      "#414A4C",
        "payne grey":       "#536878",
        "pewter":           "#96A8A1",
        "platinum":         "#E5E4E2",
        "quick silver":     "#A6A6A6",
        "roman silver":     "#838996",
        "space cadet":      "#1D2951",
        "spanish grey":     "#989898",
        "stormcloud":       "#4F666A",
        "taupe grey":       "#8B8589",
        "tin":              "#8A9597",
        "warm grey":        "#808069",
        "wet concrete":     "#645855",
        "xanadu":           "#738678",

        // ── Near-Blacks ──────────────────────────────────────
        "black":            "#000000",
        "off black":        "#0F0F0F",
        "licorice":         "#1A1110",
        "eerie black":      "#1B1B1B",
        "rich black":       "#004040",

        // ── Whites & Off-Whites ──────────────────────────────
        "white":            "#FFFFFF",
        "off white":        "#FAF9F6",
        "ivory":            "#FFFFF0",
        "snow":             "#FFFAFA",
        "linen":            "#FAF0E6",
        "ghost white":      "#F8F8FF",
        "seashell":         "#FFF5EE",
        "floral white":     "#FFFAF0",
        "pearl":            "#F0EAD6",
        "alabaster":        "#F2F0EB",
        "eggshell":         "#F0EAD6",
        "vanilla":          "#F3E5AB",
        "antique white":    "#FAEBD7",
        "cornsilk":         "#FFF8DC",
        "cosmic latte":     "#FFF8E7",
        "cultured":         "#F5F5F5",
        "dutch white":      "#EFDFBB",
        "magnolia":         "#F8F4FF",
        "old lace":         "#FDF5E6",
        "navajo white":     "#FFDEAD",
        "papaya whip":      "#FFEFD5",
        "peach puff":       "#FFDAB9",
        "bisque":           "#FFE4C4",

        // ── Pastels ──────────────────────────────────────────
        "pastel blue":      "#AEC6CF",
        "pastel green":     "#77DD77",
        "pastel purple":    "#B39EB5",
        "pastel yellow":    "#FDFD96",
        "pastel orange":    "#FFB347",
        "pastel red":       "#FF6961",
        "pastel teal":      "#B2DFDB",

        // ── Neons ────────────────────────────────────────────
        "neon red":         "#FF3131",
        "neon orange":      "#FF5733",
        "neon yellow":      "#CCFF00",
        "neon pink":        "#FF6EC7",
        "neon cyan":        "#0FF0FC",
        "neon magenta":     "#FF00C1",
        "electric red":     "#E60026",
        "electric yellow":  "#FFFF33",
        "electric orange":  "#FF7300",
        "electric violet":  "#8F00FF",
    ]
}
