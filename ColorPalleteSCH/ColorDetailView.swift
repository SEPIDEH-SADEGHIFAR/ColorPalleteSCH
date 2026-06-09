import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - COLOR DETAIL VIEW
// Presented as a sheet when the user taps a color swatch.
// Shows a custom picker + all color space conversions.
// ═════════════════════════════════════════════════════════════

struct ColorDetailView: View {
    @Bindable var color: SavedColor
    @Environment(\.dismiss) private var dismiss

    // ── Picker state (HSV/HSB) ──────────────────────────────────
    @State private var hue:        Double = 0
    @State private var saturation: Double = 1
    @State private var brightness: Double = 1

    // ── Hex field ───────────────────────────────────────────────
    @State private var hexInput:   String = ""
    @State private var hexValid:   Bool   = true
    @FocusState private var hexFocused: Bool

    // ── Change tracking ─────────────────────────────────────────
    @State private var originalHex: String = ""
    @State private var savedFlash:  Bool   = false

    // ── Animation ───────────────────────────────────────────────
    @State private var animateIn = false

    // ─────────────────────────────────────────────────────────────
    private var hasChanges: Bool { currentHex != originalHex }

    private var currentHex: String {
        let rgb = ColorSpaceMath.hsvToRGB(h: hue, s: saturation, v: brightness)
        return String(format: "#%02X%02X%02X",
                      Int(rgb.r * 255), Int(rgb.g * 255), Int(rgb.b * 255))
    }

    private var currentSwiftColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private var conversions: ColorConversions {
        let rgb = ColorSpaceMath.hsvToRGB(h: hue, s: saturation, v: brightness)
        return ColorSpaceMath.convert(r: rgb.r, g: rgb.g, b: rgb.b)
    }

    // ─────────────────────────────────────────────────────────────
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSwatch
                        pickerSection.padding(.top, 20)
                        conversionsSection.padding(.top, 28)
                        if hasChanges { saveSection.padding(.top, 24) }
                        Spacer(minLength: 52)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(color.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        // Revert if not saved
                        if hasChanges { revertColor() }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("AppText").opacity(0.55))
                            .frame(width: 30, height: 30)
                            //.background(Color("AppText").opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                if hasChanges {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", action: saveChanges)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: "#6C63FF"))
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
        .presentationDetents([.large])
        .onAppear {
            loadFromHex(color.hex)
            originalHex = color.hex
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
    }

    // MARK: - Hero Swatch

    private var heroSwatch: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(currentSwiftColor)
                .frame(height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                )
                .shadow(color: currentSwiftColor.opacity(0.35), radius: 20, y: 8)

            VStack(spacing: 6) {
                Text(currentHex.uppercased())
                    .font(.system(size: 26, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6)

                Text(color.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.2), radius: 3)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .scaleEffect(animateIn ? 1 : 0.95)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: - Picker Section

    private var pickerSection: some View {
        VStack(spacing: 14) {
            // ── Saturation / Brightness canvas ──────────────────
            SatBriCanvas(hue: hue, saturation: $saturation, brightness: $brightness)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: Color("AppText").opacity(0.08), radius: 8, y: 4)
                .onChange(of: saturation) { _ in syncHexField() }
                .onChange(of: brightness) { _ in syncHexField() }

            // ── Hue rainbow slider ──────────────────────────────
            HueRainbowSlider(hue: $hue)
                .frame(height: 34)
                .onChange(of: hue) { _ in syncHexField() }

            // ── Hex input row ───────────────────────────────────
            HStack(spacing: 12) {
                // Live preview dot
                Circle()
                    .fill(currentSwiftColor)
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color("AppText").opacity(0.12), lineWidth: 1))
                    .shadow(color: currentSwiftColor.opacity(0.4), radius: 6)

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
                        let clean = String(
                            newVal.uppercased()
                                .replacingOccurrences(of: "#", with: "")
                                .filter { "0123456789ABCDEF".contains($0) }
                                .prefix(6)
                        )
                        if hexInput != clean { hexInput = clean }
                        if clean.count == 6 {
                            loadFromHex("#\(clean)")
                            hexValid = true
                        } else {
                            hexValid = clean.isEmpty
                        }
                    }

                Spacer()

                // Validation indicator
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
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                hexFocused
                                    ? Color(hex: "#6C63FF").opacity(0.4)
                                    : Color("AppText").opacity(0.08),
                                lineWidth: 1.2
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: hexFocused)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 12)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    // MARK: - Conversions Section

    private var conversionsSection: some View {
        let conv = conversions
        
        // 1. Helper struct so the compiler doesn't choke on tuples
        struct ConvCard {
            let label: String
            let value: String
        }
        
        // 2. Build the flat array of cards
        let cards: [ConvCard] = [
            ConvCard(label: "HEX",  value: conv.hex),
            ConvCard(label: "RGB",  value: "\(conv.rgb.r), \(conv.rgb.g), \(conv.rgb.b)"),
            ConvCard(label: "HSL",  value: "\(conv.hsl.h)°, \(conv.hsl.s)%, \(conv.hsl.l)%"),
            ConvCard(label: "HSB",  value: "\(conv.hsb.h)°, \(conv.hsb.s)%, \(conv.hsb.b)%"),
            ConvCard(label: "CMYK", value: "\(conv.cmyk.c), \(conv.cmyk.m), \(conv.cmyk.y), \(conv.cmyk.k)"),
            ConvCard(label: "HWB",  value: "\(conv.hwb.h)°, \(conv.hwb.w)%, \(conv.hwb.b)%"),
            ConvCard(label: "XYZ",  value: "\(conv.xyz.x), \(conv.xyz.y), \(conv.xyz.z)"),
            ConvCard(label: "LAB",  value: "\(conv.lab.l), \(conv.lab.a), \(conv.lab.b)"),
            ConvCard(label: "LUV",  value: "\(conv.luv.l), \(conv.luv.u), \(conv.luv.v)")
        ]

        // 3. Explicitly chunk them into an array of rows (arrays of ConvCard)
        var rows: [[ConvCard]] = []
        for i in stride(from: 0, to: cards.count, by: 2) {
            if i + 1 < cards.count {
                rows.append([cards[i], cards[i+1]])
            } else {
                rows.append([cards[i]])
            }
        }

        // 4. Return the clean View
        return VStack(alignment: .leading, spacing: 14) {
            Text("CONVERSIONS")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(Color("AppText").opacity(0.28))

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 12) {
                    // First card in the row
                    ConversionCard(label: row[0].label, value: row[0].value, accentColor: currentSwiftColor)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 16)
                        .animation(.spring(response: 0.5).delay(0.15 + Double(rowIdx) * 0.05), value: animateIn)

                    // Second card in the row (if it exists)
                    if row.count > 1 {
                        ConversionCard(label: row[1].label, value: row[1].value, accentColor: currentSwiftColor)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 16)
                            .animation(.spring(response: 0.5).delay(0.18 + Double(rowIdx) * 0.05), value: animateIn)
                    } else {
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Save Section

    private var saveSection: some View {
        Button(action: saveChanges) {
            HStack(spacing: 10) {
                Image(systemName: savedFlash ? "checkmark.circle.fill" : "paintbrush.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(savedFlash ? "Color Updated!" : "Save Changes")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(savedFlash ? Color(hex: "#34C759") : Color("AppBackground"))
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(savedFlash ? Color(hex: "#34C759").opacity(0.15) : Color("AppText"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(savedFlash ? Color(hex: "#34C759").opacity(0.4) : Color.clear,
                                    lineWidth: 1.5)
                    )
            )
        }
        .animation(.spring(response: 0.4), value: savedFlash)
    }

    // MARK: - Logic

    private func loadFromHex(_ hex: String) {
        guard let rgb = ColorSpaceMath.hexToRGB(hex) else { return }
        let hsv = ColorSpaceMath.rgbToHSV(r: rgb.r, g: rgb.g, b: rgb.b)
        hue        = hsv.h
        saturation = hsv.s
        brightness = hsv.v
        let clean  = hex.replacingOccurrences(of: "#", with: "")
        if !hexFocused { hexInput = clean }
    }

    private func syncHexField() {
        if !hexFocused {
            hexInput = String(currentHex.dropFirst())
        }
    }

    private func saveChanges() {
            color.hex = currentHex
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // 1. Trigger the green "Color Updated!" animation on your button
            withAnimation(.spring(response: 0.4)) { savedFlash = true }
            originalHex = currentHex
            
            // 2. Wait 0.8 seconds so the user can see the green button, then close the sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        }

    private func revertColor() {
        loadFromHex(originalHex)
        color.hex = originalHex
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - SAT/BRI CANVAS
// 2D gradient: white→hue (X) × opaque→black (Y).
// Drag to move the selection point.
// ═════════════════════════════════════════════════════════════

struct SatBriCanvas: View {
    let hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Base gradient: white → pure hue color ───────
                LinearGradient(
                    colors: [.white, Color(hue: hue, saturation: 1, brightness: 1)],
                    startPoint: .leading, endPoint: .trailing
                )

                // ── Overlay: transparent → black top → bottom ────
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top, endPoint: .bottom
                )
                .blendMode(.multiply)

                // ── Thumb ────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                        .frame(width: thumbSize + 2, height: thumbSize + 2)
                }
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                .position(
                    x: saturation * geo.size.width,
                    y: (1 - brightness) * geo.size.height
                )
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        saturation = max(0, min(1, Double(val.location.x / geo.size.width)))
                        brightness = max(0, min(1, 1 - Double(val.location.y / geo.size.height)))
                    }
            )
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - HUE RAINBOW SLIDER
// Horizontal rainbow gradient with a draggable thumb.
// ═════════════════════════════════════════════════════════════

struct HueRainbowSlider: View {
    @Binding var hue: Double

    private let thumbSize: CGFloat = 28
    private let trackHeight: CGFloat = 14

    // Build the rainbow from 13 hue stops
    private let rainbowColors: [Color] = stride(from: 0, through: 360, by: 30).map {
        Color(hue: Double($0) / 360, saturation: 1, brightness: 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Rainbow track
                LinearGradient(colors: rainbowColors,
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: trackHeight)
                    .clipShape(Capsule())
                    .frame(maxHeight: .infinity)

                // Thumb
                ZStack {
                    Circle()
                        .fill(Color(hue: hue, saturation: 1, brightness: 1))
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                        .frame(width: thumbSize, height: thumbSize)
                    Circle()
                        .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
                        .frame(width: thumbSize + 2, height: thumbSize + 2)
                }
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                .offset(x: hue * (geo.size.width - thumbSize))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        hue = max(0, min(1, Double(val.location.x / geo.size.width)))
                    }
            )
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - CONVERSION CARD
// One card in the 2-column conversions grid.
// Shows label, value, and a copy button.
// ═════════════════════════════════════════════════════════════

struct ConversionCard: View {
    let label: String
    let value: String
    let accentColor: Color

    @State private var copied = false

    var body: some View {
        HStack(spacing: 0) {
            // Label
            Text(label)
                .font(.system(size: 12, weight: .black))
                .tracking(0.5)
                .foregroundStyle(Color("AppText").opacity(0.45))
                .frame(width: 48, alignment: .leading)
                .padding(.leading, 14)

            // Value
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AppText"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Copy button
            Button {
                UIPasteboard.general.string = value
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation { copied = false }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.35))
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(copied
                                  ? Color(hex: "#34C759").opacity(0.1)
                                  : Color("AppText").opacity(0.06))
                    )
                    .padding(.trailing, 4)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.3), value: copied)
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR CONVERSIONS MODEL
// ═════════════════════════════════════════════════════════════

struct ColorConversions {
    let hex:  String
    let rgb:  (r: Int, g: Int, b: Int)
    let hsl:  (h: Int, s: Int, l: Int)
    let hsb:  (h: Int, s: Int, b: Int)
    let cmyk: (c: Int, m: Int, y: Int, k: Int)
    let hwb:  (h: Int, w: Int, b: Int)
    let xyz:  (x: Int, y: Int, z: Int)
    let lab:  (l: Int, a: Int, b: Int)
    let luv:  (l: Int, u: Int, v: Int)
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR SPACE MATH ENGINE
// All conversions use normalized doubles (0–1) internally.
// ═════════════════════════════════════════════════════════════

enum ColorSpaceMath {

    // MARK: Main conversion entry point

    static func convert(r: Double, g: Double, b: Double) -> ColorConversions {
        let hex  = String(format: "#%02X%02X%02X",
                          Int(r*255), Int(g*255), Int(b*255))
        let hsl  = rgbToHSL(r: r, g: g, b: b)
        let hsb  = rgbToHSB(r: r, g: g, b: b)
        let cmyk = rgbToCMYK(r: r, g: g, b: b)
        let hwb  = rgbToHWB(r: r, g: g, b: b)
        let xyz  = rgbToXYZ(r: r, g: g, b: b)
        let lab  = xyzToLAB(xyz)
        let luv  = xyzToLUV(xyz)

        return ColorConversions(
            hex:  hex,
            rgb:  (Int(r*255), Int(g*255), Int(b*255)),
            hsl:  hsl,
            hsb:  hsb,
            cmyk: cmyk,
            hwb:  hwb,
            xyz:  xyz,
            lab:  lab,
            luv:  luv
        )
    }

    // MARK: HSL

    static func rgbToHSL(r: Double, g: Double, b: Double) -> (h: Int, s: Int, l: Int) {
        let mx = max(r, g, b), mn = min(r, g, b)
        let l = (mx + mn) / 2
        var h = 0.0, s = 0.0
        if mx != mn {
            let d = mx - mn
            s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
            if      mx == r { h = (g - b) / d + (g < b ? 6 : 0) }
            else if mx == g { h = (b - r) / d + 2 }
            else            { h = (r - g) / d + 4 }
            h /= 6
        }
        return (Int(h * 360), Int(s * 100), Int(l * 100))
    }

    // MARK: HSB / HSV

    static func rgbToHSB(r: Double, g: Double, b: Double) -> (h: Int, s: Int, b: Int) {
        let hsv = rgbToHSV(r: r, g: g, b: b)
        return (Int(hsv.h * 360), Int(hsv.s * 100), Int(hsv.v * 100))
    }

    // Internal normalized HSV
    static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        let s = mx == 0 ? 0.0 : d / mx
        var h = 0.0
        if d != 0 {
            if      mx == r { h = (g - b) / d + (g < b ? 6 : 0) }
            else if mx == g { h = (b - r) / d + 2 }
            else            { h = (r - g) / d + 4 }
            h /= 6
        }
        return (h, s, mx)
    }

    // HSV → RGB (used by the picker to get current colour)
    static func hsvToRGB(h: Double, s: Double, v: Double) -> (r: Double, g: Double, b: Double) {
        if s == 0 { return (v, v, v) }
        let h6 = h * 6, i = Int(h6), f = h6 - Double(i)
        let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch i % 6 {
        case 0:  return (v, t, p)
        case 1:  return (q, v, p)
        case 2:  return (p, v, t)
        case 3:  return (p, q, v)
        case 4:  return (t, p, v)
        default: return (v, p, q)
        }
    }

    // MARK: CMYK

    static func rgbToCMYK(r: Double, g: Double, b: Double) -> (c: Int, m: Int, y: Int, k: Int) {
        let k = 1 - max(r, g, b)
        guard k < 1 else { return (0, 0, 0, 100) }
        let inv = 1 - k
        return (Int((1 - r - k) / inv * 100),
                Int((1 - g - k) / inv * 100),
                Int((1 - b - k) / inv * 100),
                Int(k * 100))
    }

    // MARK: HWB

    static func rgbToHWB(r: Double, g: Double, b: Double) -> (h: Int, w: Int, b: Int) {
        let hsv = rgbToHSV(r: r, g: g, b: b)
        return (Int(hsv.h * 360),
                Int(min(r, g, b) * 100),
                Int((1 - max(r, g, b)) * 100))
    }

    // MARK: XYZ (D65/sRGB)

    static func rgbToXYZ(r: Double, g: Double, b: Double) -> (x: Int, y: Int, z: Int) {
        func lin(_ c: Double) -> Double {
            c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let rl = lin(r), gl = lin(g), bl = lin(b)
        let x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
        let y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        let z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041
        // Scale ×100 then round, matching industry tools
        return (Int((x * 100).rounded()),
                Int((y * 100).rounded()),
                Int((z * 100).rounded()))
    }

    // MARK: LAB (D65)

    static func xyzToLAB(_ xyz: (x: Int, y: Int, z: Int)) -> (l: Int, a: Int, b: Int) {
        func f(_ t: Double) -> Double {
            t > 0.008856 ? cbrt(t) : 7.787 * t + 16.0 / 116.0
        }
        let xn = Double(xyz.x) / 100 / 0.95047
        let yn = Double(xyz.y) / 100 / 1.00000
        let zn = Double(xyz.z) / 100 / 1.08883
        let L  = 116 * f(yn) - 16
        let a  = 500 * (f(xn) - f(yn))
        let b  = 200 * (f(yn) - f(zn))
        return (Int(L.rounded()), Int(a.rounded()), Int(b.rounded()))
    }

    // MARK: LUV (D65)

    static func xyzToLUV(_ xyz: (x: Int, y: Int, z: Int)) -> (l: Int, u: Int, v: Int) {
        let x = Double(xyz.x) / 100
        let y = Double(xyz.y) / 100
        let z = Double(xyz.z) / 100
        let denom = x + 15 * y + 3 * z
        guard denom > 0 else { return (0, 0, 0) }
        let uP  = 4 * x / denom
        let vP  = 9 * y / denom
        let yr  = y  // Yn = 1.0 for D65
        let L   = yr > 0.008856 ? 116 * cbrt(yr) - 16 : 903.3 * yr
        // D65 reference whites: u0 = 0.2009, v0 = 0.4610
        let u   = 13 * L * (uP - 0.2009)
        let v   = 13 * L * (vP - 0.4610)
        return (Int(L.rounded()), Int(u.rounded()), Int(v.rounded()))
    }

    // MARK: Hex → RGB

    static func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        let h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard h.count == 6 else { return nil }
        var val: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&val) else { return nil }
        return (Double((val >> 16) & 0xFF) / 255,
                Double((val >> 8)  & 0xFF) / 255,
                Double( val        & 0xFF) / 255)
    }
}
