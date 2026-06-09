import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - ADD COLOR VIEW
// ═════════════════════════════════════════════════════════════

struct AddColorView: View {
    @Bindable var palette: SavedPalette
    @Environment(\.dismiss) private var dismiss

    // ── Picker state (HSB 0–1) ──────────────────────────────────
    @State private var hue:        Double = 0.67
    @State private var saturation: Double = 0.78
    @State private var brightness: Double = 0.88

    // ── Input fields ────────────────────────────────────────────
    @State private var hexInput:  String = ""
    @State private var colorName: String = ""
    @State private var hexValid:  Bool   = true
    @FocusState private var nameFocused: Bool
    @FocusState private var hexFocused:  Bool

    // ── UI ───────────────────────────────────────────────────────
    @State private var animateIn   = false
    @State private var addSuccess  = false

    // ── Suggestions (computed once on init) ──────────────────────
    private let suggestions: [ACColorSuggestion]

    init(palette: SavedPalette) {
        self._palette = Bindable(wrappedValue: palette)
        // Start with a colour that contrasts the last palette colour
        let startH = AddColorView.suggestStartHue(palette)
        self._hue   = State(initialValue: startH)
        self.suggestions = AddColorView.buildSuggestions(palette)
    }

    // ── Derived ─────────────────────────────────────────────────
    var currentHex: String { ACColorMath.hsbToHex(hue, saturation, brightness) }
    var currentSwift: Color { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var canAdd: Bool { !colorName.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSwatch
                        pickerCard.padding(.top, 20)
                        nameCard.padding(.top, 14)
                        if !suggestions.isEmpty {
                            suggestionsCard.padding(.top, 14)
                        }
                        addButton.padding(.top, 22)
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add a Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                syncHexFromPicker()
                autoName()
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    animateIn = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: ── Hero Swatch ───────────────────────────────────────

    private var heroSwatch: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(currentSwift)
                .frame(height: 130)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12), lineWidth: 1))
                .shadow(color: currentSwift.opacity(0.38), radius: 18, y: 8)

            VStack(spacing: 6) {
                Text(currentHex.uppercased())
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 4)
                if !colorName.isEmpty {
                    Text(colorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .shadow(color: .black.opacity(0.2), radius: 3)
                }
            }
        }
        .scaleEffect(animateIn ? 1 : 0.92)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.04), value: animateIn)
    }

    // MARK: ── Picker Card ───────────────────────────────────────

    private var pickerCard: some View {
        VStack(spacing: 16) {
            // Section label
            sectionLabel("PICK YOUR COLOR")

            // Saturation / Brightness canvas
            ACSatBriCanvas(hue: hue, saturation: $saturation, brightness: $brightness)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color("AppText").opacity(0.08), radius: 8, y: 4)
                .onChange(of: saturation) { _ in syncHexFromPicker(); autoName() }
                .onChange(of: brightness) { _ in syncHexFromPicker(); autoName() }

            // Hue slider
            ACHueSlider(hue: $hue)
                .onChange(of: hue) { _ in syncHexFromPicker(); autoName() }

            // Hex input
            hexInputRow
        }
        .padding(18)
        .background(cardBackground)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.08), value: animateIn)
    }

    private var hexInputRow: some View {
        HStack(spacing: 12) {
            // Live colour dot
            Circle()
                .fill(currentSwift)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                .shadow(color: currentSwift.opacity(0.35), radius: 5)

            Text("#")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("AppText").opacity(0.35))

            TextField("000000", text: $hexInput)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(hexValid ? Color("AppText") : Color(hex: "#FF453A"))
                .tint(Color(hex: "#6C63FF"))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($hexFocused)
                .onChange(of: hexInput) { newVal in
                    let clean = String(newVal.uppercased()
                        .filter { "0123456789ABCDEF".contains($0) }
                        .prefix(6))
                    if hexInput != clean { hexInput = clean }
                    if clean.count == 6 {
                        loadFromHex("#\(clean)")
                        hexValid = true
                    } else {
                        hexValid = clean.isEmpty
                    }
                }

            Spacer()

            if hexInput.count == 6 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#34C759"))
                    .transition(.scale.combined(with: .opacity))
            } else if hexInput.count > 0 {
                Text("\(hexInput.count)/6")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.28))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("AppBackground"))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(hexFocused ? Color(hex: "#6C63FF").opacity(0.4) : Color("AppText").opacity(0.08), lineWidth: 1.2))
        )
        .animation(.easeInOut(duration: 0.2), value: hexFocused)
    }

    // MARK: ── Name Card ─────────────────────────────────────────

    private var nameCard: some View {
        VStack(spacing: 12) {
            sectionLabel("COLOR NAME")

            HStack(spacing: 12) {
                TextField("e.g. Dusty Violet", text: $colorName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
                    .tint(Color(hex: "#6C63FF"))
                    .focused($nameFocused)

                // Auto-name button
                Button {
                    withAnimation(.spring(response: 0.35)) { autoName(force: true) }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Auto")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "#6C63FF"))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "#6C63FF").opacity(0.1))
                            .overlay(Capsule().stroke(Color(hex: "#6C63FF").opacity(0.25), lineWidth: 1))
                    )
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("AppBackground"))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(nameFocused ? Color(hex: "#6C63FF").opacity(0.4) : Color("AppText").opacity(0.08), lineWidth: 1.2))
            )
            .animation(.easeInOut(duration: 0.2), value: nameFocused)

            if colorName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#6C63FF").opacity(0.7))
                    Text("Tap \"Auto\" to generate a name from this color")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.38))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
        }
        .padding(18)
        .background(cardBackground)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.13), value: animateIn)
    }

    // MARK: ── Suggestions Card ───────────────────────────────────

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("WORKS WITH YOUR PALETTE")
                Spacer()
                Text("Tap any to use it")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.3))
            }

            // Group suggestions by type
            let grouped = Dictionary(grouping: suggestions, by: \.type)
            let order: [ACColorSuggestion.SuggestionType] = [.tint, .shade, .analogous, .complement, .split]

            VStack(spacing: 12) {
                ForEach(order, id: \.self) { type in
                    if let group = grouped[type], !group.isEmpty {
                        suggestionRow(type: type, items: group)
                    }
                }
            }
        }
        .padding(18)
        .background(cardBackground)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.18), value: animateIn)
    }

    private func suggestionRow(type: ACColorSuggestion.SuggestionType, items: [ACColorSuggestion]) -> some View {
        HStack(spacing: 12) {
            Text(type.label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color("AppText").opacity(0.28))
                .frame(width: 66, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items.prefix(6)) { sug in
                        suggestionCircle(sug)
                    }
                }
            }
        }
    }

    private func suggestionCircle(_ sug: ACColorSuggestion) -> some View {
        let isActive = currentHex.uppercased() == sug.hex.uppercased()
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                loadFromHex(sug.hex)
                autoName(force: true)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: sug.hex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color("AppBackground") : Color("AppText").opacity(0.1),
                                    lineWidth: isActive ? 3 : 1)
                    )
                    .shadow(color: Color(hex: sug.hex).opacity(0.3), radius: 5, y: 2)

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color("AppBackground"))
                }
            }
            .scaleEffect(isActive ? 1.14 : 1.0)
        }
        .animation(.spring(response: 0.28), value: isActive)
    }

    // MARK: ── Add Button ────────────────────────────────────────

    private var addButton: some View {
        Button(action: addColor) {
            HStack(spacing: 10) {
                Image(systemName: addSuccess ? "checkmark.circle.fill" : "plus")
                    .font(.system(size: 18, weight: .bold))
                Text(addSuccess ? "Added!" : "Add to Palette")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(addSuccess ? Color(hex: "#34C759") : (canAdd ? Color("AppBackground") : Color("AppText").opacity(0.28)))
            .frame(maxWidth: .infinity).frame(height: 60)
            .background(
                Group {
                    if addSuccess {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#34C759").opacity(0.14))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5))
                    } else if canAdd {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .shadow(color: Color(hex: "#6C63FF").opacity(0.32), radius: 12, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color("AppText").opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                    }
                }
            )
        }
        .disabled(!canAdd || addSuccess)
        .animation(.spring(response: 0.35), value: addSuccess)
        .animation(.easeInOut(duration: 0.2), value: canAdd)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.22), value: animateIn)
    }

    // MARK: ── Shared UI helpers ──────────────────────────────────

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(2.5)
            .foregroundStyle(Color("AppText").opacity(0.28))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .shadow(color: Color("AppText").opacity(0.05), radius: 12, y: 4)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color("AppText").opacity(0.07), lineWidth: 1))
    }

    // MARK: ── Logic ──────────────────────────────────────────────

    private func syncHexFromPicker() {
        if !hexFocused {
            hexInput = String(currentHex.dropFirst())   // strip leading #
        }
    }

    private func loadFromHex(_ hex: String) {
        guard let hsb = ACColorMath.hexToHSB(hex) else { return }
        hue        = hsb.h
        saturation = hsb.s
        brightness = hsb.b
        hexInput   = String(hex.uppercased().replacingOccurrences(of: "#", with: "").prefix(6))
    }

    private func autoName(force: Bool = false) {
        // Don't overwrite a name the user has typed — unless force
        guard force || colorName.isEmpty else { return }
        colorName = ACColorMath.autoName(h: hue, s: saturation, b: brightness)
    }

    private func addColor() {
        let name = colorName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let newColor = SavedColor(name: name, hex: currentHex)
        palette.colors.append(newColor)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { addSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    // MARK: ── Suggestion helpers (static) ───────────────────────

    private static func suggestStartHue(_ palette: SavedPalette) -> Double {
        guard let last = palette.colors.last,
              let hsb = ACColorMath.hexToHSB(last.hex) else {
            return 0.67  // default violet
        }
        // Start at the complementary of the last color
        return (hsb.h + 0.5).truncatingRemainder(dividingBy: 1.0)
    }

    private static func buildSuggestions(_ palette: SavedPalette) -> [ACColorSuggestion] {
        guard !palette.colors.isEmpty else { return [] }
        var results: [ACColorSuggestion] = []
        let existingHexes = Set(palette.colors.map { $0.hex.uppercased() })

        for paletteColor in palette.colors.prefix(4) {
            guard let (h, s, l) = ACColorMath.hexToHSL(paletteColor.hex) else { continue }

            // Tints — lighter
            for step in [18.0, 30.0, 42.0] {
                let hex = ACColorMath.hslToHex(h, max(0, s - 8), min(95, l + step))
                results.append(.init(hex: hex, type: .tint))
            }
            // Shades — darker
            for step in [18.0, 30.0] {
                let hex = ACColorMath.hslToHex(h, s, max(8, l - step))
                results.append(.init(hex: hex, type: .shade))
            }
            // Analogous — neighbouring hues
            for offset in [-35.0, -20.0, 20.0, 35.0] {
                let hex = ACColorMath.hslToHex(ACColorMath.wrapH(h + offset), s, l)
                results.append(.init(hex: hex, type: .analogous))
            }
            // Complementary
            results.append(.init(hex: ACColorMath.hslToHex(ACColorMath.wrapH(h + 180), s, l), type: .complement))

            // Split-complementary
            for offset in [150.0, 210.0] {
                let hex = ACColorMath.hslToHex(ACColorMath.wrapH(h + offset), s, l)
                results.append(.init(hex: hex, type: .split))
            }
        }

        // Deduplicate + filter too-similar to existing
        var seen = Set<String>()
        return results.filter { sug in
            let key = sug.hex.uppercased()
            guard !seen.contains(key), !existingHexes.contains(key) else { return false }
            let tooClose = palette.colors.contains {
                ACColorMath.perceivedDist($0.hex, sug.hex) < 22
            }
            guard !tooClose else { return false }
            seen.insert(key)
            return true
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - SUGGESTION MODEL
// ═════════════════════════════════════════════════════════════

struct ACColorSuggestion: Identifiable {
    let id = UUID()
    let hex: String
    let type: SuggestionType

    enum SuggestionType: Hashable {
        case tint, shade, analogous, complement, split

        var label: String {
            switch self {
            case .tint:       return "TINTS"
            case .shade:      return "SHADES"
            case .analogous:  return "ANALOGOUS"
            case .complement: return "CONTRAST"
            case .split:      return "SPLIT"
            }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - SATURATION / BRIGHTNESS CANVAS
// ═════════════════════════════════════════════════════════════

struct ACSatBriCanvas: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    private let thumbSize: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // White → fully-saturated hue
                LinearGradient(
                    colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                    startPoint: .leading, endPoint: .trailing
                )
                // Transparent → black overlay
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .blendMode(.multiply)

                // Thumb
                ZStack {
                    Circle()
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .frame(width: thumbSize, height: thumbSize)
                    Circle().strokeBorder(.white, lineWidth: 2.5).frame(width: thumbSize, height: thumbSize)
                    Circle().strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                        .frame(width: thumbSize + 2, height: thumbSize + 2)
                }
                .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
                .position(x: saturation * geo.size.width, y: (1 - brightness) * geo.size.height)
            }
            // Explicit frame so GeometryReader's content fills it completely.
            // Without this the ZStack can have zero size and touches miss.
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            // highPriorityGesture overrides the parent ScrollView's scroll
            // gesture so dragging on the canvas always moves the thumb.
            // coordinateSpace: .local gives positions relative to THIS view.
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { val in
                        saturation = max(0, min(1, val.location.x / geo.size.width))
                        brightness = max(0, min(1.0, 1.0 - val.location.y / geo.size.height))
                    }
            )
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - HUE SLIDER
// ═════════════════════════════════════════════════════════════

struct ACHueSlider: View {
    @Binding var hue: Double
    private let thumbSize: CGFloat = 28

    private let stops: [Color] = stride(from: 0, through: 1, by: 1.0/12)
        .map { Color(hue: $0, saturation: 1, brightness: 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                LinearGradient(colors: stops, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 14).clipShape(Capsule()).frame(maxHeight: .infinity)
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

                ZStack {
                    Circle().fill(.white).frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                    Circle().fill(Color(hue: hue, saturation: 1, brightness: 1))
                        .frame(width: thumbSize - 10, height: thumbSize - 10)
                    Circle().strokeBorder(.white, lineWidth: 2.5).frame(width: thumbSize, height: thumbSize)
                }
                .position(x: hue * geo.size.width, y: geo.size.height / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { val in
                        hue = max(0, min(1, val.location.x / geo.size.width))
                    }
            )
        }
        .frame(height: thumbSize + 6)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR MATH ENGINE
// ═════════════════════════════════════════════════════════════

enum ACColorMath {

    // MARK: HSB → Hex

    static func hsbToHex(_ h: Double, _ s: Double, _ b: Double) -> String {
        if s == 0 {
            let v = Int(b * 255)
            return String(format: "#%02X%02X%02X", v, v, v)
        }
        let h6 = h * 6, i = Int(h6), f = h6 - Double(i)
        let p = b*(1-s), q = b*(1-s*f), t = b*(1-s*(1-f))
        var r = 0.0, g = 0.0, bv = 0.0
        switch i % 6 {
        case 0: r=b; g=t; bv=p
        case 1: r=q; g=b; bv=p
        case 2: r=p; g=b; bv=t
        case 3: r=p; g=q; bv=b
        case 4: r=t; g=p; bv=b
        default: r=b; g=p; bv=q
        }
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(bv*255))
    }

    // MARK: Hex → HSB

    static func hexToHSB(_ hex: String) -> (h: Double, s: Double, b: Double)? {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard h.count == 6 else { return nil }
        var v: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&v) else { return nil }
        let r = Double((v>>16)&0xFF)/255, g = Double((v>>8)&0xFF)/255, b = Double(v&0xFF)/255
        let mx = max(r,g,b), mn = min(r,g,b), d = mx - mn
        let s = mx == 0 ? 0.0 : d/mx
        var hh = 0.0
        if d != 0 {
            if mx==r      { hh = (g-b)/d + (g<b ? 6:0) }
            else if mx==g { hh = (b-r)/d + 2 }
            else           { hh = (r-g)/d + 4 }
            hh /= 6
        }
        return (hh, s, mx)
    }

    // MARK: Hex → HSL (for suggestion math)

    static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double)? {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard h.count == 6 else { return nil }
        var v: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&v) else { return nil }
        let r = Double((v>>16)&0xFF)/255, g = Double((v>>8)&0xFF)/255, b = Double(v&0xFF)/255
        let mx = max(r,g,b), mn = min(r,g,b)
        let l = (mx+mn)/2
        var hh = 0.0, s = 0.0
        if mx != mn {
            let d = mx-mn
            s = l > 0.5 ? d/(2-mx-mn) : d/(mx+mn)
            if mx==r      { hh = (g-b)/d + (g<b ? 6:0) }
            else if mx==g { hh = (b-r)/d + 2 }
            else           { hh = (r-g)/d + 4 }
            hh /= 6
        }
        return (hh*360, s*100, l*100)
    }

    // MARK: HSL → Hex (for suggestions)

    static func hslToHex(_ h: Double, _ s: Double, _ l: Double) -> String {
        let H = (h/360).truncatingRemainder(dividingBy: 1)
        let S = max(0, min(1, s/100)), L = max(0, min(1, l/100))
        if S == 0 { let v = Int(L*255); return String(format:"#%02X%02X%02X",v,v,v) }
        func f(_ p: Double, _ q: Double, _ t: Double) -> Double {
            var t = t; if t<0{t+=1}; if t>1{t-=1}
            if t<1/6{return p+(q-p)*6*t}; if t<0.5{return q}
            if t<2/3{return p+(q-p)*(2/3-t)*6}; return p
        }
        let q = L<0.5 ? L*(1+S) : L+S-L*S, p = 2*L-q
        return String(format:"#%02X%02X%02X",Int(f(p,q,H+1/3)*255),Int(f(p,q,H)*255),Int(f(p,q,H-1/3)*255))
    }

    static func wrapH(_ h: Double) -> Double {
        var v = h.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    // MARK: Perceived RGB distance (for deduplication)

    static func perceivedDist(_ hexA: String, _ hexB: String) -> Double {
        func rgb(_ h: String) -> (Double, Double, Double) {
            let s = h.replacingOccurrences(of: "#", with: "")
            var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
            return (Double((v>>16)&0xFF), Double((v>>8)&0xFF), Double(v&0xFF))
        }
        let a = rgb(hexA), b = rgb(hexB)
        let dr = a.0-b.0, dg = a.1-b.1, db = a.2-b.2
        return sqrt(0.299*dr*dr + 0.587*dg*dg + 0.114*db*db)
    }

    // MARK: Auto-name from HSB

    static func autoName(h: Double, s: Double, b: Double) -> String {
        if b < 0.14 { return "Midnight Black" }
        if b > 0.94 && s < 0.08 { return "Ivory White" }
        if s < 0.11 {
            if b < 0.32 { return "Charcoal" }
            if b < 0.60 { return "Slate Gray" }
            return "Silver"
        }
        let deg = h * 360
        let hueWord: String
        switch deg {
        case 0..<15, 345...360: hueWord = "Crimson"
        case 15..<38:    hueWord = "Orange"
        case 38..<55:    hueWord = "Amber"
        case 55..<75:    hueWord = "Yellow"
        case 75..<150:   hueWord = "Green"
        case 150..<185:  hueWord = "Teal"
        case 185..<220:  hueWord = "Blue"
        case 220..<260:  hueWord = "Indigo"
        case 260..<290:  hueWord = "Violet"
        case 290..<325:  hueWord = "Magenta"
        case 325..<345:  hueWord = "Rose"
        default:         hueWord = "Color"
        }
        let mod: String
        if b > 0.85 && s > 0.65 { mod = "Vivid" }
        else if b < 0.35         { mod = "Deep" }
        else if s < 0.32         { mod = "Muted" }
        else if b > 0.88         { mod = "Soft" }
        else if s > 0.82         { mod = "Bright" }
        else                     { mod = "" }
        return mod.isEmpty ? hueWord : "\(mod) \(hueWord)"
    }
}
