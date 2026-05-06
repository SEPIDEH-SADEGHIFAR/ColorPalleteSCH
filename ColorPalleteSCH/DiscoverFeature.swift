import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - MAIN TAB VIEW
// ═════════════════════════════════════════════════════════════

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case discover
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Palettes", systemImage: selectedTab == .home ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .tag(Tab.home)
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: selectedTab == .discover ? "sparkle.magnifyingglass" : "magnifyingglass")
                }
                .tag(Tab.discover)
        }
        .tint(Color(hex: "#1A1A1A"))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - DISCOVER VIEW
// ═════════════════════════════════════════════════════════════

struct DiscoverView: View {
    @Environment(\.modelContext) private var modelContext
    
    // ── Search & Input ─────────────────────────────────────────
    @State private var searchText: String = ""
    @State private var pickedColor: Color = .blue
    @State private var showColorPicker: Bool = false
    
    // ── Explored Color State ───────────────────────────────────
    @State private var exploredColor: ExploredColor? = nil
    
    // ── Selection State ────────────────────────────────────────
    @State private var selectedSwatches: Set<String> = [] // hex strings
    
    // ── UI State ───────────────────────────────────────────────
    @State private var animateIn = false
    @State private var showSavedConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(hex: "#F5F2EE").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.top, 16)
                        
                        // Search + Color Picker Input
                        searchSection
                            .padding(.top, 20)
                            .padding(.horizontal, 22)
                        
                        // Explored Color Display
                        if let explored = exploredColor {
                            exploredColorSection(explored: explored)
                                .padding(.top, 28)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            emptyState
                                .padding(.top, 80)
                        }
                        
                        Spacer(minLength: selectedSwatches.isEmpty ? 40 : 120)
                    }
                }
                
                // Floating Create Palette Button
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
                    exploreColor(pickedColor)
                }
            }
            .overlay(
                savedConfirmationOverlay
            )
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISCOVER")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
            Text("Color Explorer")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1A1A1A"))
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
            // Search bar with integrated color picker button
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
                    
                    TextField("Hex, name, or description...", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "#1A1A1A"))
                        .tint(Color(hex: "#1A1A1A"))
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            exploredColor = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.25))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color(hex: "#1A1A1A").opacity(0.06), radius: 12, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#1A1A1A").opacity(0.08), lineWidth: 1)
                        )
                )
                
                // Color Picker Button
                Button {
                    showColorPicker = true
                } label: {
                    Image(systemName: "eyedropper.halffull")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#1A1A1A"))
                        )
                }
            }
            
            // Quick suggestion chips
            if exploredColor == nil && searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["#FF6B6B", "#6C63FF", "#2DD4BF", "#F59E0B", "#EC4899"], id: \.self) { hex in
                            Button {
                                exploreColor(Color(hex: hex))
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(Color(hex: "#1A1A1A").opacity(0.1), lineWidth: 1))
                                    Text(hex)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "#1A1A1A").opacity(0.05))
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
                    .fill(Color(hex: "#1A1A1A").opacity(0.04))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.2))
            }
            VStack(spacing: 8) {
                Text("Explore Any Color")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.6))
                Text("Search by hex, name, or pick from the dropper")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.2), value: animateIn)
    }
    
    // MARK: - Explored Color Section
    
    private func exploredColorSection(explored: ExploredColor) -> some View {
        VStack(spacing: 24) {
            // Exact Match — Hero Swatch
            exactMatchCard(explored: explored)
                .padding(.horizontal, 22)
            
            // Tints (Lighter)
            colorRangeSection(
                title: "Tints",
                subtitle: "Lighter variations",
                colors: explored.tints,
                icon: "sun.max.fill"
            )
            
            // Shades (Darker)
            colorRangeSection(
                title: "Shades",
                subtitle: "Darker variations",
                colors: explored.shades,
                icon: "moon.fill"
            )
            
            // Analogous
            colorRangeSection(
                title: "Analogous",
                subtitle: "Neighboring hues",
                colors: explored.analogous,
                icon: "circle.hexagongrid.fill"
            )
            
            // Complementary
            colorRangeSection(
                title: "Complementary",
                subtitle: "Opposite contrasts",
                colors: explored.complementary,
                icon: "arrow.triangle.2.circlepath"
            )
        }
    }
    
    // MARK: - Exact Match Card
    
    private func exactMatchCard(explored: ExploredColor) -> some View {
        VStack(spacing: 0) {
            // Big swatch
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(explored.color)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#1A1A1A").opacity(0.08), lineWidth: 1)
                    )
                
                // Selection indicator if this exact color is selected
                if selectedSwatches.contains(explored.hex) {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .padding(16)
                        }
                        Spacer()
                    }
                }
            }
            .onTapGesture {
                toggleSelection(hex: explored.hex)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EXACT MATCH")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
                        Text(explored.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1A1A1A"))
                    }
                    Spacer()
                    // Copy button
                    Button {
                        UIPasteboard.general.string = explored.hex
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "#1A1A1A").opacity(0.06))
                            )
                    }
                }
                
                HStack(spacing: 12) {
                    Label(explored.hex.uppercased(), systemImage: "number")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.45))
                    
                    Label(explored.rgbString, systemImage: "circle.grid.3x3.fill")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.45))
                }
            }
            .padding(18)
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24
            ))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: "#1A1A1A").opacity(0.08), radius: 20, y: 8)
    }
    
    // MARK: - Color Range Section
    
    private func colorRangeSection(title: String, subtitle: String, colors: [ColorSwatch], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1A1A1A"))
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.4))
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            
            // Horizontal scrolling swatches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colors, id: \.hex) { swatch in
                        SwatchCard(
                            swatch: swatch,
                            isSelected: selectedSwatches.contains(swatch.hex),
                            onTap: { toggleSelection(hex: swatch.hex) }
                        )
                    }
                }
                .padding(.horizontal, 22)
            }
        }
    }
    
    // MARK: - Create Palette Button
    
    private var createPaletteButton: some View {
        Button {
            createPaletteFromSelection()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("Create Palette from Selected (\(selectedSwatches.count))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: "#1A1A1A"))
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
                        .onTapGesture {
                            withAnimation { showSavedConfirmation = false }
                        }
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Color(hex: "#34C759"))
                        
                        VStack(spacing: 6) {
                            Text("Palette Created!")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#1A1A1A"))
                            Text("Saved to your collection")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.5))
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
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
        let cleaned = searchText.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return }
        
        // Try hex first
        if cleaned.hasPrefix("#"), cleaned.count == 7 {
            exploreColor(Color(hex: cleaned))
            return
        }
        
        // Try named color match (simple example — expand as needed)
        let namedColors: [String: String] = [
            "red": "#FF0000",
            "blue": "#0000FF",
            "green": "#00FF00",
            "navy": "#000080",
            "coral": "#FF6B6B",
            "violet": "#6C63FF",
            "mint": "#2DD4BF"
        ]
        
        if let hex = namedColors[cleaned.lowercased()] {
            exploreColor(Color(hex: hex))
            return
        }
        
        // Fallback: treat as a hex without # or random color
        if cleaned.count == 6, cleaned.allSatisfy({ "0123456789ABCDEFabcdef".contains($0) }) {
            exploreColor(Color(hex: "#\(cleaned)"))
        }
    }
    
    private func exploreColor(_ color: Color) {
        withAnimation(.spring(response: 0.5)) {
            exploredColor = ColorMath.explore(color: color)
        }
        searchText = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func toggleSelection(hex: String) {
        withAnimation(.spring(response: 0.3)) {
            if selectedSwatches.contains(hex) {
                selectedSwatches.remove(hex)
            } else {
                selectedSwatches.insert(hex)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func createPaletteFromSelection() {
        guard !selectedSwatches.isEmpty else { return }
        
        let colors = selectedSwatches.prefix(8).map { hex in
            SavedColor(name: ColorMath.nameForHex(hex), hex: hex)
        }
        
        let title = exploredColor?.name ?? "Discovered Palette"
        let palette = SavedPalette(title: title, colors: Array(colors))
        
        modelContext.insert(palette)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        withAnimation {
            showSavedConfirmation = true
            selectedSwatches.removeAll()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showSavedConfirmation = false
            }
        }
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
            // Color square
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: swatch.hex))
                    .frame(width: 110, height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isSelected ? Color.white : Color(hex: "#1A1A1A").opacity(0.08),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            
            // Info
            VStack(spacing: 3) {
                Text(swatch.hex.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(width: 110)
            .background(Color.white)
            .clipShape(UnevenRoundedRectangle(
                bottomLeadingRadius: 14,
                bottomTrailingRadius: 14
            ))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "#1A1A1A").opacity(isSelected ? 0.15 : 0.06), radius: isSelected ? 12 : 8, y: 4)
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
                Color(hex: "#F5F2EE").ignoresSafeArea()
                VStack(spacing: 24) {
                    // Big preview
                    RoundedRectangle(cornerRadius: 24)
                        .fill(selectedColor)
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(hex: "#1A1A1A").opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 22)
                    
                    // Native picker
                    ColorPicker("Pick a Color", selection: $selectedColor)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 22)
                    
                    Spacer()
                    
                    // Confirm button
                    Button {
                        onConfirm()
                        dismiss()
                    } label: {
                        Text("Explore This Color")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#1A1A1A"))
                            )
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
                        .foregroundStyle(Color(hex: "#1A1A1A"))
                }
            }
            .toolbarBackground(Color(hex: "#F5F2EE"), for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR MATH ENGINE
// ═════════════════════════════════════════════════════════════

struct ColorSwatch: Identifiable {
    let id = UUID()
    let hex: String
}

struct ExploredColor {
    let color: Color
    let hex: String
    let name: String
    let rgbString: String
    let tints: [ColorSwatch]
    let shades: [ColorSwatch]
    let analogous: [ColorSwatch]
    let complementary: [ColorSwatch]
}

enum ColorMath {
    
    /// Main entry point: explore a color and generate all variations
    static func explore(color: Color) -> ExploredColor {
        let hex = color.toHex() ?? "#000000"
        let rgb = hexToRGB(hex)
        let hsb = rgbToHSB(rgb)
        
        return ExploredColor(
            color: color,
            hex: hex,
            name: nameForHex(hex),
            rgbString: "RGB(\(rgb.r), \(rgb.g), \(rgb.b))",
            tints: generateTints(from: rgb),
            shades: generateShades(from: rgb),
            analogous: generateAnalogous(from: hsb),
            complementary: generateComplementary(from: hsb)
        )
    }
    
    // MARK: - Tints (Lighter — Mix with White)
    
    static func generateTints(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        let steps = 6
        return (1...steps).map { step in
            let ratio = Double(step) / Double(steps + 1)
            let r = Int(Double(rgb.r) + (255 - Double(rgb.r)) * ratio)
            let g = Int(Double(rgb.g) + (255 - Double(rgb.g)) * ratio)
            let b = Int(Double(rgb.b) + (255 - Double(rgb.b)) * ratio)
            return ColorSwatch(hex: rgbToHex(r: r, g: g, b: b))
        }
    }
    
    // MARK: - Shades (Darker — Mix with Black)
    
    static func generateShades(from rgb: (r: Int, g: Int, b: Int)) -> [ColorSwatch] {
        let steps = 6
        return (1...steps).map { step in
            let ratio = Double(step) / Double(steps + 1)
            let r = Int(Double(rgb.r) * (1 - ratio))
            let g = Int(Double(rgb.g) * (1 - ratio))
            let b = Int(Double(rgb.b) * (1 - ratio))
            return ColorSwatch(hex: rgbToHex(r: r, g: g, b: b))
        }
    }
    
    // MARK: - Analogous (±30° on Hue Wheel)
    
    static func generateAnalogous(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        let offsets: [Double] = [-60, -45, -30, -15, 15, 30, 45, 60]
        return offsets.map { offset in
            var newH = hsb.h + offset
            if newH < 0 { newH += 360 }
            if newH >= 360 { newH -= 360 }
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            return ColorSwatch(hex: rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b))
        }
    }
    
    // MARK: - Complementary (180° Opposite + Variations)
    
    static func generateComplementary(from hsb: (h: Double, s: Double, b: Double)) -> [ColorSwatch] {
        // Pure complement + slight variations
        let offsets: [Double] = [165, 172.5, 180, 187.5, 195]
        return offsets.map { offset in
            var newH = hsb.h + offset
            if newH >= 360 { newH -= 360 }
            let rgb = hsbToRGB(h: newH, s: hsb.s, b: hsb.b)
            return ColorSwatch(hex: rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b))
        }
    }
    
    // MARK: - Color Space Conversions
    
    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        return (
            r: Int((value >> 16) & 0xFF),
            g: Int((value >> 8) & 0xFF),
            b: Int(value & 0xFF)
        )
    }
    
    static func rgbToHex(r: Int, g: Int, b: Int) -> String {
        String(format: "#%02X%02X%02X", r, g, b)
    }
    
    static func rgbToHSB(_ rgb: (r: Int, g: Int, b: Int)) -> (h: Double, s: Double, b: Double) {
        let r = Double(rgb.r) / 255.0
        let g = Double(rgb.g) / 255.0
        let b = Double(rgb.b) / 255.0
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var h: Double = 0
        let s: Double = max == 0 ? 0 : delta / max
        let brightness: Double = max
        
        if delta != 0 {
            if max == r {
                h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if max == g {
                h = 60 * (((b - r) / delta) + 2)
            } else {
                h = 60 * (((r - g) / delta) + 4)
            }
        }
        
        if h < 0 { h += 360 }
        
        return (h: h, s: s, b: brightness)
    }
    
    static func hsbToRGB(h: Double, s: Double, b: Double) -> (r: Int, g: Int, b: Int) {
        let c = b * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        
        var rgb: (Double, Double, Double)
        
        switch h {
        case 0..<60:   rgb = (c, x, 0)
        case 60..<120: rgb = (x, c, 0)
        case 120..<180: rgb = (0, c, x)
        case 180..<240: rgb = (0, x, c)
        case 240..<300: rgb = (x, 0, c)
        default:       rgb = (c, 0, x)
        }
        
        return (
            r: Int((rgb.0 + m) * 255),
            g: Int((rgb.1 + m) * 255),
            b: Int((rgb.2 + m) * 255)
        )
    }
    
    // MARK: - Color Naming (Simple Example)
    
    static func nameForHex(_ hex: String) -> String {
        let rgb = hexToRGB(hex)
        let hsb = rgbToHSB(rgb)
        
        // Brightness check
        if hsb.b < 0.15 { return "Deep Black" }
        if hsb.b > 0.92 && hsb.s < 0.08 { return "Pure White" }
        
        // Low saturation = gray
        if hsb.s < 0.12 {
            if hsb.b < 0.35 { return "Charcoal" }
            if hsb.b < 0.65 { return "Gray" }
            return "Silver"
        }
        
        // Hue-based naming
        let prefix: String
        switch hsb.h {
        case 0..<15, 345..<360:   prefix = "Red"
        case 15..<38:             prefix = "Orange"
        case 38..<55:             prefix = "Amber"
        case 55..<75:             prefix = "Yellow"
        case 75..<150:            prefix = "Green"
        case 150..<185:           prefix = "Teal"
        case 185..<220:           prefix = "Blue"
        case 220..<260:           prefix = "Indigo"
        case 260..<290:           prefix = "Violet"
        case 290..<325:           prefix = "Magenta"
        case 325..<345:           prefix = "Pink"
        default:                  prefix = "Color"
        }
        
        let modifier: String
        if hsb.b > 0.80 && hsb.s > 0.5 { modifier = "Bright" }
        else if hsb.b < 0.40 { modifier = "Deep" }
        else if hsb.s < 0.4  { modifier = "Muted" }
        else { modifier = "" }
        
        return modifier.isEmpty ? prefix : "\(modifier) \(prefix)"
    }
}
