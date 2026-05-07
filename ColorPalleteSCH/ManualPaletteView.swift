import SwiftUI
import SwiftData

// MARK: - Manual Palette View

struct ManualPaletteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var slots: [ColorSlot] = ColorSlot.defaults()
    @State private var activeSlotID: UUID? = nil
    @State private var savedSuccessfully = false
    @State private var animateIn = false
    @FocusState private var titleFocused: Bool

    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && !slots.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea() // Adaptive Background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        livePreviewStrip
                            .padding(.top, 28)
                        titleField
                            .padding(.top, 24)
                        colorSlotsSection
                            .padding(.top, 28)
                        addColorButton
                            .padding(.top, 14)
                        saveButton
                            .padding(.top, 32)
                        Spacer(minLength: 48)
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
                            .foregroundStyle(Color("AppText").opacity(0.55)) // Adaptive
                            .frame(width: 30, height: 30)
                            .background(Color("AppText").opacity(0.09)) // Adaptive
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar) // Adaptive Toolbar
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MANUAL STUDIO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "#FF8C42"))
                Text("Build Your\nPalette")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText")) // Adaptive Text
                    .lineSpacing(0)
            }
            Spacer()
        }
        .padding(.top, 18)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -12)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: - Live Preview Strip

    private var livePreviewStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LIVE PREVIEW")
                .font(.system(size: 9, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(Color("AppText").opacity(0.4))

            ZStack(alignment: .bottomLeading) {
                // Color stripes
                if slots.isEmpty {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(height: 100)
                        .overlay(
                            Text("Add colors below")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.4))
                        )
                } else {
                    HStack(spacing: 0) {
                        ForEach(slots) { slot in
                            Color(hex: slot.hex)
                                .overlay(
                                    // Highlight active slot
                                    slot.id == activeSlotID
                                    ? Color.white.opacity(0.25) : Color.clear
                                )
                        }
                    }
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("AppText").opacity(0.09), lineWidth: 1)
                    )
                    
                    // Palette title overlay
                    if !title.isEmpty {
                        Text(title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white) // Keep white for contrast over colors
                            .shadow(color: .black.opacity(0.5), radius: 6)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                }
            }
            .animation(.spring(response: 0.35), value: slots.map(\.hex))
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.15), value: animateIn)
    }

    // MARK: - Title Field

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PALETTE NAME")
                .font(.system(size: 9, weight: .bold))
                .tracking(2.5)
                .foregroundStyle(Color("AppText").opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#FF8C42").opacity(0.8))

                TextField("e.g. Sunset Over Rome", text: $title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText")) // Adaptive Text
                    .tint(Color(hex: "#FF8C42"))
                    .focused($titleFocused)
                    .submitLabel(.done)

                if !title.isEmpty {
                    Button {
                        title = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color("AppText").opacity(0.3))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Card
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                titleFocused
                                    ? Color(hex: "#FF8C42").opacity(0.5)
                                    : Color("AppText").opacity(0.08),
                                lineWidth: 1.2
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: titleFocused)
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.15), value: animateIn)
    }

    // MARK: - Color Slots Section

    private var colorSlotsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("COLORS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Color("AppText").opacity(0.4))
                Spacer()
                Text("\(slots.count) / 8")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.4))
            }

            VStack(spacing: 10) {
                ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                    ColorSlotRow(
                        slot: binding(for: slot),
                        isActive: activeSlotID == slot.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                activeSlotID = activeSlotID == slot.id ? nil : slot.id
                            }
                        },
                        onDelete: slots.count > 1 ? {
                            withAnimation(.spring(response: 0.4)) {
                                slots.removeAll { $0.id == slot.id }
                                if activeSlotID == slot.id { activeSlotID = nil }
                            }
                        } : nil
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 16)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.82)
                            .delay(0.18 + Double(index) * 0.06),
                        value: animateIn
                    )
                }
            }
        }
    }

    // MARK: - Add Color Button

    private var addColorButton: some View {
        Button {
            guard slots.count < 8 else { return }
            let newSlot = ColorSlot(
                hex: ColorSlot.randomHex(),
                name: "Color \(slots.count + 1)"
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                slots.append(newSlot)
                activeSlotID = newSlot.id
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                Text(slots.count >= 8 ? "Maximum 8 colors" : "Add Another Color")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(
                slots.count >= 8
                    ? Color("AppText").opacity(0.3)
                    : Color(hex: "#FF8C42")
            )
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])
                            )
                            .foregroundStyle(
                                slots.count >= 8
                                    ? Color("AppText").opacity(0.08)
                                    : Color(hex: "#FF8C42").opacity(0.35)
                            )
                    )
            )
        }
        .disabled(slots.count >= 8)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.35), value: animateIn)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: savePalette) {
            HStack(spacing: 10) {
                Image(systemName: savedSuccessfully ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))
                Text(savedSuccessfully ? "Saved!" : "Save Palette")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(
                savedSuccessfully
                    ? Color(hex: "#34C759")
                    : (canSave ? Color("AppBackground") : Color("AppText").opacity(0.3)) // Adaptive Text
            )
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if savedSuccessfully {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "#34C759").opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5)
                            )
                    } else if canSave {
                        RoundedRectangle(cornerRadius: 18).fill(Color("AppText")) // Adaptive Solid
                    } else {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color("AppText").opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            )
        }
        .disabled(!canSave || savedSuccessfully)
        .animation(.spring(response: 0.4), value: savedSuccessfully)
        .animation(.easeInOut(duration: 0.2), value: canSave)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.38), value: animateIn)
    }

    // MARK: - Helpers

    private func binding(for slot: ColorSlot) -> Binding<ColorSlot> {
        guard let index = slots.firstIndex(where: { $0.id == slot.id }) else {
            return .constant(slot)
        }
        return $slots[index]
    }

    private func savePalette() {
        let savedColors = slots.map {
            SavedColor(name: $0.name.isEmpty ? "Color" : $0.name, hex: $0.hex)
        }
        let newPalette = SavedPalette(
            title: title.trimmingCharacters(in: .whitespaces),
            colors: savedColors
        )
        modelContext.insert(newPalette)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { savedSuccessfully = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}

// MARK: - Color Slot Row

struct ColorSlotRow: View {
    @Binding var slot: ColorSlot
    let isActive: Bool
    let onTap: () -> Void
    let onDelete: (() -> Void)?

    @State private var hexInput: String = ""
    @State private var hexIsValid: Bool = true
    @FocusState private var hexFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Color swatch — tappable ColorPicker
                ColorPicker("", selection: Binding(
                    get: { Color(hex: slot.hex) },
                    set: { newColor in
                        if let hex = newColor.toHex() {
                            slot.hex = hex
                            hexInput = String(hex.dropFirst())
                        }
                    }
                ))
                .labelsHidden()
                .scaleEffect(1.1)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: slot.hex))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Name field
                TextField("Color name", text: $slot.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText")) // Adaptive
                    .tint(Color(hex: "#FF8C42"))

                Spacer()

                // Expand / collapse
                Button(action: onTap) {
                    Image(systemName: isActive ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color("AppText").opacity(0.5)) // Adaptive
                        .frame(width: 28, height: 28)
                        .background(Color("AppText").opacity(0.07))
                        .clipShape(Circle())
                }

                // Delete
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "#FF453A"))
                            .frame(width: 28, height: 28)
                            .background(Color(hex: "#FF453A").opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Expanded hex editor
            if isActive {
                Divider()
                    .background(Color("AppText").opacity(0.1))
                    .padding(.horizontal, 14)

                HStack(spacing: 10) {
                    // Hex preview dot
                    Circle()
                        .fill(Color(hex: slot.hex))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1)
                        )

                    Text("#")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("AppText").opacity(0.4))

                    TextField("000000", text: $hexInput)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(hexIsValid ? Color("AppText") : Color(hex: "#FF453A")) // Adaptive
                        .tint(Color(hex: "#FF8C42"))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($hexFocused)
                        .onChange(of: hexInput) { newVal in
                            let cleaned = newVal
                                .uppercased()
                                .replacingOccurrences(of: "#", with: "")
                                .filter { "0123456789ABCDEF".contains($0) }
                                .prefix(6)
                            let result = String(cleaned)
                            if hexInput != result { hexInput = result }
                            if result.count == 6 {
                                slot.hex = "#\(result)"
                                hexIsValid = true
                            } else {
                                hexIsValid = result.isEmpty
                            }
                        }

                    Spacer()

                    // Random color
                    Button {
                        let newHex = ColorSlot.randomHex()
                        slot.hex = newHex
                        hexInput = String(newHex.dropFirst())
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 11, weight: .bold))
                            Text("Random")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "#FF8C42"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#FF8C42").opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "#FF8C42").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Card Background
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isActive
                                ? Color(hex: "#FF8C42").opacity(0.4)
                                : Color("AppText").opacity(0.07),
                            lineWidth: 1.2
                        )
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isActive)
        .onAppear {
            hexInput = String(slot.hex.dropFirst())
        }
    }
}

// MARK: - Color Slot Model

struct ColorSlot: Identifiable {
    let id: UUID
    var hex: String
    var name: String

    init(id: UUID = UUID(), hex: String, name: String) {
        self.id = id
        self.hex = hex
        self.name = name
    }

    static func defaults() -> [ColorSlot] {
        [
            ColorSlot(hex: "#E63946", name: "Crimson"),
            ColorSlot(hex: "#F4A261", name: "Amber"),
            ColorSlot(hex: "#2A9D8F", name: "Teal"),
            ColorSlot(hex: "#457B9D", name: "Steel Blue"),
            ColorSlot(hex: "#1D3557", name: "Midnight"),
        ]
    }

    static func randomHex() -> String {
        let r = Int.random(in: 60...220)
        let g = Int.random(in: 60...220)
        let b = Int.random(in: 60...220)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
