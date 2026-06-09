import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - EDIT COLOR SHEET
//
// Fully self-contained — no dependency on AddColorView.swift.
//
// In SavedPaletteDetailView update the sheet call to:
//   .sheet(item: $colorToEdit) { color in
//       EditColorSheet(color: color, palette: palette)
//   }
// ═════════════════════════════════════════════════════════════

struct EditColorSheet: View {
    @Bindable var color: SavedColor
    let palette: SavedPalette
    @Environment(\.dismiss) private var dismiss

    // ── Originals — used for the Before panel and Reset ─────────
    private let originalHex:  String
    private let originalName: String

    // ── Picker state (HSB 0–1) ───────────────────────────────────
    @State private var hue:        Double
    @State private var saturation: Double
    @State private var brightness: Double

    // ── Fields ───────────────────────────────────────────────────
    @State private var hexInput:  String
    @State private var colorName: String
    @State private var hexValid:  Bool = true
    @FocusState private var nameFocused: Bool
    @FocusState private var hexFocused:  Bool

    // ── UI ───────────────────────────────────────────────────────
    @State private var animateIn   = false
    @State private var saveSuccess = false

    // ── Suggestions ─────────────────────────────────────────────
    private let suggestions: [ECSuggestion]

    init(color: SavedColor, palette: SavedPalette) {
        self._color       = Bindable(wrappedValue: color)
        self.palette      = palette
        self.originalHex  = color.hex
        self.originalName = color.name

        if let hsb = ECColorMath.hexToHSB(color.hex) {
            self._hue        = State(initialValue: hsb.h)
            self._saturation = State(initialValue: hsb.s)
            self._brightness = State(initialValue: hsb.b)
        } else {
            self._hue        = State(initialValue: 0.67)
            self._saturation = State(initialValue: 0.78)
            self._brightness = State(initialValue: 0.88)
        }
        self._hexInput  = State(initialValue: String(color.hex
            .replacingOccurrences(of: "#", with: "").prefix(6).uppercased()))
        self._colorName = State(initialValue: color.name)
        self.suggestions = EditColorSheet.buildSuggestions(palette, excluding: color)
    }

    // ── Derived ──────────────────────────────────────────────────
    var currentHex:   String { ECColorMath.hsbToHex(hue, saturation, brightness) }
    var currentColor: Color  { Color(hue: hue, saturation: saturation, brightness: brightness) }
    var hasChanges:   Bool   {
        currentHex.uppercased() != originalHex.uppercased() ||
        colorName.trimmingCharacters(in: .whitespaces) != originalName
    }
    var canSave: Bool { !colorName.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        beforeAfterPanel
                        pickerCard.padding(.top, 20)
                        nameCard.padding(.top, 14)
                        if !suggestions.isEmpty {
                            suggestionsCard.padding(.top, 14)
                        }
                        actionButtons.padding(.top, 22)
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
                if hasChanges {
                    ToolbarItem(placement: .status) {
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: "#6C63FF")).frame(width: 6, height: 6)
                            Text("Unsaved changes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.4))
                        }
                        .transition(.opacity)
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                    animateIn = true
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: ── Before / After Panel ──────────────────────────────

    private var beforeAfterPanel: some View {
        HStack(spacing: 12) {

            // BEFORE
            VStack(spacing: 8) {
                Text("BEFORE")
                    .font(.system(size: 9, weight: .bold)).tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.28))
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: originalHex))
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("AppText").opacity(0.08), lineWidth: 1))
                Text(originalHex.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.45))
            }
            .frame(maxWidth: .infinity)

            // Arrow
            VStack(spacing: 4) {
                Image(systemName: hasChanges ? "arrow.right.circle.fill" : "arrow.right.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(hasChanges ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.2))
                    .animation(.spring(response: 0.35), value: hasChanges)
                if hasChanges {
                    Text("Changed")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(hex: "#6C63FF").opacity(0.8))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(width: 56)
            .animation(.spring(response: 0.35), value: hasChanges)

            // NOW
            VStack(spacing: 8) {
                Text("NOW")
                    .font(.system(size: 9, weight: .bold)).tracking(2)
                    .foregroundStyle(Color(hex: "#6C63FF").opacity(0.7))
                RoundedRectangle(cornerRadius: 18)
                    .fill(currentColor)
                    .frame(height: 90)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(hasChanges ? Color(hex: "#6C63FF").opacity(0.4) : Color("AppText").opacity(0.08),
                                lineWidth: hasChanges ? 2 : 1))
                    .shadow(color: currentColor.opacity(hasChanges ? 0.32 : 0.1),
                            radius: hasChanges ? 12 : 5, y: 4)
                    .animation(.easeInOut(duration: 0.2), value: hasChanges)
                Text(currentHex.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(hasChanges ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.45))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(cardBG)
        .scaleEffect(animateIn ? 1 : 0.95)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.04), value: animateIn)
    }

    // MARK: ── Picker Card ────────────────────────────────────────

    private var pickerCard: some View {
        VStack(spacing: 16) {
            sectionLabel("PICK YOUR COLOR")

            // Saturation / Brightness canvas — gesture fixed
            ECSatBriCanvas(hue: hue, saturation: $saturation, brightness: $brightness)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color("AppText").opacity(0.07), radius: 8, y: 4)
                .onChange(of: saturation) { _ in syncHex() }
                .onChange(of: brightness) { _ in syncHex() }

            // Hue slider — gesture fixed
            ECHueSlider(hue: $hue)
                .onChange(of: hue) { _ in syncHex() }

            hexField
        }
        .padding(18)
        .background(cardBG)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.08), value: animateIn)
    }

    private var hexField: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(currentColor)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                .shadow(color: currentColor.opacity(0.3), radius: 5)

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
                    if clean.count == 6 { loadFromHex("#\(clean)"); hexValid = true }
                    else { hexValid = clean.isEmpty }
                }

            Spacer()

            if hexInput.count == 6 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(hex: "#34C759"))
                    .transition(.scale.combined(with: .opacity))
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

    // MARK: ── Name Card ──────────────────────────────────────────

    private var nameCard: some View {
        VStack(spacing: 12) {
            sectionLabel("COLOR NAME")

            HStack(spacing: 12) {
                TextField("Color name", text: $colorName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
                    .tint(Color(hex: "#6C63FF"))
                    .focused($nameFocused)

                Button {
                    withAnimation(.spring(response: 0.35)) {
                        colorName = ECColorMath.autoName(h: hue, s: saturation, b: brightness)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles").font(.system(size: 12, weight: .semibold))
                        Text("Auto").font(.system(size: 12, weight: .bold))
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
        }
        .padding(18)
        .background(cardBG)
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
                    .foregroundStyle(Color("AppText").opacity(0.28))
            }

            let grouped = Dictionary(grouping: suggestions, by: \.type)
            let order: [ECSuggestion.SuggestionType] = [.tint, .shade, .analogous, .complement, .split]

            VStack(spacing: 12) {
                ForEach(order, id: \.self) { type in
                    if let group = grouped[type], !group.isEmpty {
                        suggestionRow(type: type, items: group)
                    }
                }
            }
        }
        .padding(18)
        .background(cardBG)
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.18), value: animateIn)
    }

    private func suggestionRow(type: ECSuggestion.SuggestionType, items: [ECSuggestion]) -> some View {
        HStack(spacing: 12) {
            Text(type.label)
                .font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundStyle(Color("AppText").opacity(0.28))
                .frame(width: 66, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items.prefix(6)) { sug in
                        let isActive = currentHex.uppercased() == sug.hex.uppercased()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                loadFromHex(sug.hex)
                                colorName = ECColorMath.autoName(h: hue, s: saturation, b: brightness)
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: sug.hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle()
                                        .stroke(isActive ? Color("AppBackground") : Color("AppText").opacity(0.1),
                                                lineWidth: isActive ? 3 : 1))
                                    .shadow(color: Color(hex: sug.hex).opacity(0.3), radius: 5, y: 2)
                                if isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(Color("AppBackground"))
                                }
                            }
                            .scaleEffect(isActive ? 1.14 : 1.0)
                            .animation(.spring(response: 0.28), value: isActive)
                        }
                    }
                }
            }
        }
    }

    // MARK: ── Action Buttons ─────────────────────────────────────

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if hasChanges {
                Button {
                    withAnimation(.spring(response: 0.4)) { reset() }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Reset to Original")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color("AppText").opacity(0.5))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("AppText").opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("AppText").opacity(0.09), lineWidth: 1))
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Button(action: save) {
                HStack(spacing: 10) {
                    Image(systemName: saveSuccess ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 18, weight: .bold))
                    Text(saveSuccess ? "Saved!" : (hasChanges ? "Save Changes" : "No Changes"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .foregroundStyle(
                    saveSuccess ? Color(hex: "#34C759") :
                    hasChanges  ? Color("AppBackground") :
                    Color("AppText").opacity(0.28)
                )
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(
                    Group {
                        if saveSuccess {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "#34C759").opacity(0.14))
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5))
                        } else if hasChanges {
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
            .disabled(!hasChanges || !canSave || saveSuccess)
            .animation(.spring(response: 0.35), value: hasChanges)
            .animation(.spring(response: 0.35), value: saveSuccess)
        }
        .opacity(animateIn ? 1 : 0).offset(y: animateIn ? 0 : 10)
        .animation(.spring(response: 0.5).delay(0.22), value: animateIn)
    }

    // MARK: ── Helpers ────────────────────────────────────────────

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(2.5)
            .foregroundStyle(Color("AppText").opacity(0.28))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .shadow(color: Color("AppText").opacity(0.05), radius: 12, y: 4)
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(Color("AppText").opacity(0.07), lineWidth: 1))
    }

    private func syncHex() {
        if !hexFocused {
            hexInput = String(currentHex.dropFirst().prefix(6))
        }
    }

    private func loadFromHex(_ hex: String) {
        guard let hsb = ECColorMath.hexToHSB(hex) else { return }
        hue        = hsb.h
        saturation = hsb.s
        brightness = hsb.b
        hexInput   = String(hex.uppercased().replacingOccurrences(of: "#", with: "").prefix(6))
    }

    private func reset() {
        loadFromHex(originalHex)
        colorName = originalName
    }

    private func save() {
        guard hasChanges, canSave else { return }
        color.hex  = currentHex
        color.name = colorName.trimmingCharacters(in: .whitespaces)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { saveSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { dismiss() }
    }

    // MARK: ── Suggestion builder ─────────────────────────────────

    private static func buildSuggestions(_ palette: SavedPalette, excluding edited: SavedColor) -> [ECSuggestion] {
        let sources  = palette.colors.filter { $0.id != edited.id }
        let allHexes = Set(palette.colors.map { $0.hex.uppercased() })
        guard !sources.isEmpty else { return [] }

        var results: [ECSuggestion] = []
        for src in sources.prefix(4) {
            guard let (h, s, l) = ECColorMath.hexToHSL(src.hex) else { continue }
            for step in [18.0, 30.0, 42.0] {
                results.append(.init(hex: ECColorMath.hslToHex(h, max(0, s-8), min(95, l+step)), type: .tint))
            }
            for step in [18.0, 30.0] {
                results.append(.init(hex: ECColorMath.hslToHex(h, s, max(8, l-step)), type: .shade))
            }
            for offset in [-35.0, -20.0, 20.0, 35.0] {
                results.append(.init(hex: ECColorMath.hslToHex(ECColorMath.wrapH(h+offset), s, l), type: .analogous))
            }
            results.append(.init(hex: ECColorMath.hslToHex(ECColorMath.wrapH(h+180), s, l), type: .complement))
            for offset in [150.0, 210.0] {
                results.append(.init(hex: ECColorMath.hslToHex(ECColorMath.wrapH(h+offset), s, l), type: .split))
            }
        }

        var seen = Set<String>()
        return results.filter { sug in
            let key = sug.hex.uppercased()
            guard !seen.contains(key), !allHexes.contains(key) else { return false }
            let tooClose = palette.colors.contains { ECColorMath.perceivedDist($0.hex, sug.hex) < 20 }
            guard !tooClose else { return false }
            seen.insert(key)
            return true
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - SUGGESTION MODEL
// ═════════════════════════════════════════════════════════════

struct ECSuggestion: Identifiable {
    let id   = UUID()
    let hex:  String
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
// MARK: - SAT / BRI CANVAS  ← gesture fix applied here
// ═════════════════════════════════════════════════════════════

struct ECSatBriCanvas: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    private let thumbSize: CGFloat = 26

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // White → fully-saturated hue (horizontal)
                LinearGradient(
                    colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                    startPoint: .leading, endPoint: .trailing
                )
                // Transparent → black (vertical)
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .blendMode(.multiply)

                // Thumb
                ZStack {
                    Circle()
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                        .frame(width: thumbSize + 2, height: thumbSize + 2)
                }
                .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
                .position(
                    x: saturation * geo.size.width,
                    y: (1 - brightness) * geo.size.height
                )
            }
            // Explicit frame fills the GeometryReader so touches register everywhere
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            // highPriorityGesture wins over the parent ScrollView scroll gesture
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { val in
                        saturation = max(0.0, min(1.0, val.location.x / geo.size.width))
                        brightness = max(0.0, min(1.0, 1.0 - val.location.y / geo.size.height))
                    }
            )
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - HUE SLIDER  ← gesture fix applied here
// ═════════════════════════════════════════════════════════════

struct ECHueSlider: View {
    @Binding var hue: Double
    private let thumbSize: CGFloat = 28

    private let stops: [Color] = stride(from: 0, through: 1, by: 1.0/12)
        .map { Color(hue: $0, saturation: 1, brightness: 1) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Rainbow track
                LinearGradient(colors: stops, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 14)
                    .clipShape(Capsule())
                    .frame(maxHeight: .infinity)
                    .shadow(color: .black.opacity(0.08), radius: 2, y: 1)

                // Thumb
                ZStack {
                    Circle().fill(.white).frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 2)
                    Circle()
                        .fill(Color(hue: hue, saturation: 1, brightness: 1))
                        .frame(width: thumbSize - 10, height: thumbSize - 10)
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: thumbSize, height: thumbSize)
                }
                .position(x: hue * geo.size.width, y: geo.size.height / 2)
            }
            // Explicit frame so the touch area matches the rendered size
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            // highPriorityGesture wins over the parent ScrollView scroll gesture
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
// MARK: - COLOR MATH
// ═════════════════════════════════════════════════════════════

enum ECColorMath {

    static func hsbToHex(_ h: Double, _ s: Double, _ b: Double) -> String {
        if s == 0 { let v = Int(b*255); return String(format:"#%02X%02X%02X",v,v,v) }
        let h6=h*6, i=Int(h6), f=h6-Double(i)
        let p=b*(1-s), q=b*(1-s*f), t=b*(1-s*(1-f))
        var r=0.0, g=0.0, bv=0.0
        switch i%6 {
        case 0:r=b;g=t;bv=p; case 1:r=q;g=b;bv=p; case 2:r=p;g=b;bv=t
        case 3:r=p;g=q;bv=b; case 4:r=t;g=p;bv=b; default:r=b;g=p;bv=q
        }
        return String(format:"#%02X%02X%02X",Int(r*255),Int(g*255),Int(bv*255))
    }

    static func hexToHSB(_ hex: String) -> (h: Double, s: Double, b: Double)? {
        let h = hex.replacingOccurrences(of:"#",with:"")
        guard h.count==6 else { return nil }
        var v:UInt64=0; guard Scanner(string:h).scanHexInt64(&v) else { return nil }
        let r=Double((v>>16)&0xFF)/255, g=Double((v>>8)&0xFF)/255, b=Double(v&0xFF)/255
        let mx=max(r,g,b), mn=min(r,g,b), d=mx-mn
        let s = mx==0 ? 0.0 : d/mx
        var hh=0.0
        if d != 0 {
            if mx==r      { hh=(g-b)/d+(g<b ? 6:0) }
            else if mx==g { hh=(b-r)/d+2 }
            else           { hh=(r-g)/d+4 }
            hh/=6
        }
        return (hh, s, mx)
    }

    static func hexToHSL(_ hex: String) -> (h: Double, s: Double, l: Double)? {
        let h = hex.replacingOccurrences(of:"#",with:"")
        guard h.count==6 else { return nil }
        var v:UInt64=0; guard Scanner(string:h).scanHexInt64(&v) else { return nil }
        let r=Double((v>>16)&0xFF)/255, g=Double((v>>8)&0xFF)/255, b=Double(v&0xFF)/255
        let mx=max(r,g,b), mn=min(r,g,b), l=(mx+mn)/2
        var hh=0.0, s=0.0
        if mx != mn {
            let d=mx-mn; s = l>0.5 ? d/(2-mx-mn) : d/(mx+mn)
            if mx==r      { hh=(g-b)/d+(g<b ? 6:0) }
            else if mx==g { hh=(b-r)/d+2 }
            else           { hh=(r-g)/d+4 }
            hh/=6
        }
        return (hh*360, s*100, l*100)
    }

    static func hslToHex(_ h: Double, _ s: Double, _ l: Double) -> String {
        let H=(h/360).truncatingRemainder(dividingBy:1)
        let S=max(0,min(1,s/100)), L=max(0,min(1,l/100))
        if S==0 { let v=Int(L*255); return String(format:"#%02X%02X%02X",v,v,v) }
        func f(_ p:Double,_ q:Double,_ t:Double)->Double {
            var t=t; if t<0{t+=1}; if t>1{t-=1}
            if t<1/6{return p+(q-p)*6*t}; if t<0.5{return q}
            if t<2/3{return p+(q-p)*(2/3-t)*6}; return p
        }
        let q=L<0.5 ? L*(1+S):L+S-L*S, p=2*L-q
        return String(format:"#%02X%02X%02X",Int(f(p,q,H+1/3)*255),Int(f(p,q,H)*255),Int(f(p,q,H-1/3)*255))
    }

    static func wrapH(_ h: Double) -> Double {
        var v=h.truncatingRemainder(dividingBy:360); if v<0{v+=360}; return v
    }

    static func perceivedDist(_ a: String, _ b: String) -> Double {
        func rgb(_ h:String)->(Double,Double,Double) {
            let s=h.replacingOccurrences(of:"#",with:"")
            var v:UInt64=0; Scanner(string:s).scanHexInt64(&v)
            return (Double((v>>16)&0xFF),Double((v>>8)&0xFF),Double(v&0xFF))
        }
        let ra=rgb(a), rb=rgb(b)
        let dr=ra.0-rb.0, dg=ra.1-rb.1, db=ra.2-rb.2
        return sqrt(0.299*dr*dr+0.587*dg*dg+0.114*db*db)
    }

    static func autoName(h: Double, s: Double, b: Double) -> String {
        if b < 0.14 { return "Midnight Black" }
        if b > 0.94 && s < 0.08 { return "Ivory White" }
        if s < 0.11 { return b < 0.32 ? "Charcoal" : b < 0.60 ? "Slate Gray" : "Silver" }
        let deg = h * 360
        let hueWord: String
        switch deg {
        case 0..<15, 345...360: hueWord = "Crimson"
        case 15..<38:  hueWord = "Orange"
        case 38..<55:  hueWord = "Amber"
        case 55..<75:  hueWord = "Yellow"
        case 75..<150: hueWord = "Green"
        case 150..<185: hueWord = "Teal"
        case 185..<220: hueWord = "Blue"
        case 220..<260: hueWord = "Indigo"
        case 260..<290: hueWord = "Violet"
        case 290..<325: hueWord = "Magenta"
        case 325..<345: hueWord = "Rose"
        default:        hueWord = "Color"
        }
        let mod: String
        if b > 0.85 && s > 0.65      { mod = "Vivid"  }
        else if b < 0.35              { mod = "Deep"   }
        else if s < 0.32              { mod = "Muted"  }
        else if b > 0.88              { mod = "Soft"   }
        else if s > 0.82              { mod = "Bright" }
        else                          { mod = ""       }
        return mod.isEmpty ? hueWord : "\(mod) \(hueWord)"
    }
}
