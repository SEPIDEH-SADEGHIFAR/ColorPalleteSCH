//
//  EditColorSheet.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 06/05/26.
//
import SwiftUI
import SwiftData

// ═════════════════════════════════════════════════════════════
// MARK: - EDIT COLOR SHEET
// ═════════════════════════════════════════════════════════════

struct EditColorSheet: View {
    let color: SavedColor
    @Environment(\.dismiss) private var dismiss

    // Local editable copies — committed only on Save
    @State private var editedName: String
    @State private var editedColor: Color
    @State private var hexInput: String
    @State private var hexIsValid: Bool = true

    @FocusState private var nameFocused: Bool
    @FocusState private var hexFocused: Bool

    init(color: SavedColor) {
        self.color = color
        _editedName  = State(initialValue: color.name)
        _editedColor = State(initialValue: Color(hex: color.hex))
        _hexInput    = State(initialValue: String(color.hex.dropFirst())) // strip leading #
    }

    var canSave: Bool {
        !editedName.trimmingCharacters(in: .whitespaces).isEmpty && hexInput.count == 6 && hexIsValid
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive mode background
                Color("AppBackground").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        // ── Large color preview ─────────────────────
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(editedColor)
                                .frame(height: 180)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                                )

                            VStack(spacing: 6) {
                                Text("#\(hexInput.uppercased())")
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white) // Always white for contrast on color
                                    .shadow(color: .black.opacity(0.4), radius: 4)
                                Text(editedName.isEmpty ? "Name your color" : editedName)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.85)) // Always white for contrast
                                    .shadow(color: .black.opacity(0.4), radius: 4)
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: editedColor)

                        // ── Color picker ────────────────────────────
                        HStack(spacing: 14) {
                            ColorPicker("", selection: $editedColor)
                                .labelsHidden()
                                .scaleEffect(1.2)
                                .frame(width: 40, height: 40)
                                .onChange(of: editedColor) { newColor in
                                    if let hex = newColor.toHex() {
                                        let stripped = String(hex.dropFirst())
                                        hexInput = stripped
                                        hexIsValid = true
                                    }
                                }

                            Text("Tap the circle to pick a new color")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.5))

                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        // ── Name field ──────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("COLOR NAME")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2.5)
                                .foregroundStyle(Color("AppText").opacity(0.4))

                            HStack(spacing: 12) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "#6C63FF").opacity(0.8))

                                TextField("e.g. Ocean Blue", text: $editedName)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color("AppText"))
                                    .tint(Color(hex: "#6C63FF"))
                                    .focused($nameFocused)
                                    .submitLabel(.next)
                                    .onSubmit { hexFocused = true }

                                if !editedName.isEmpty {
                                    Button { editedName = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color("AppText").opacity(0.25))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                    .shadow(color: Color("AppText").opacity(0.03), radius: 5, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                nameFocused
                                                    ? Color(hex: "#6C63FF").opacity(0.5)
                                                    : Color("AppText").opacity(0.08),
                                                lineWidth: 1.2
                                            )
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: nameFocused)
                        }

                        // ── Hex field ───────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HEX CODE")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2.5)
                                .foregroundStyle(Color("AppText").opacity(0.4))

                            HStack(spacing: 10) {
                                // Live dot
                                Circle()
                                    .fill(editedColor)
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Circle().stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                                    )
                                    .animation(.easeInOut(duration: 0.15), value: editedColor)

                                Text("#")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color("AppText").opacity(0.4))

                                TextField("000000", text: $hexInput)
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(hexIsValid ? Color("AppText") : Color(hex: "#FF453A"))
                                    .tint(Color(hex: "#6C63FF"))
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .focused($hexFocused)
                                    .submitLabel(.done)
                                    .onChange(of: hexInput) { newVal in
                                        // Sanitise: uppercase, hex chars only, max 6
                                        let sanitised = String(
                                            newVal
                                                .uppercased()
                                                .replacingOccurrences(of: "#", with: "")
                                                .filter { "0123456789ABCDEF".contains($0) }
                                                .prefix(6)
                                        )
                                        if hexInput != sanitised { hexInput = sanitised }

                                        if sanitised.count == 6 {
                                            editedColor = Color(hex: "#\(sanitised)")
                                            hexIsValid = true
                                        } else {
                                            hexIsValid = sanitised.isEmpty
                                        }
                                    }

                                Spacer()

                                // Validation badge
                                if hexInput.count == 6 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(Color(hex: "#34C759"))
                                        .transition(.scale.combined(with: .opacity))
                                } else if hexInput.count > 0 {
                                    Text("\(hexInput.count)/6")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color("AppText").opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                    .shadow(color: Color("AppText").opacity(0.03), radius: 5, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                hexFocused
                                                    ? Color(hex: "#6C63FF").opacity(0.5)
                                                    : (hexIsValid
                                                       ? Color("AppText").opacity(0.08)
                                                       : Color(hex: "#FF453A").opacity(0.4)),
                                                lineWidth: 1.2
                                            )
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: hexFocused)
                            .animation(.easeInOut(duration: 0.15), value: hexIsValid)
                        }

                        // ── Save button ─────────────────────────────
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(canSave ? Color("AppBackground") : Color("AppText").opacity(0.3))
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(canSave ? Color("AppText") : Color("AppText").opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(Color("AppText").opacity(canSave ? 0 : 0.1), lineWidth: 1)
                                        )
                                )
                        }
                        .disabled(!canSave)
                        .animation(.easeInOut(duration: 0.2), value: canSave)

                        // ── Delete button ───────────────────────────
                        Button(action: deleteColor) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Delete Color")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color(hex: "#FF453A"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#FF453A").opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(hex: "#FF453A").opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppText"))
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
        }
        .presentationDetents([.large])
    }

    // MARK: - Actions

    private func saveChanges() {
        guard canSave else { return }
        color.name = editedName.trimmingCharacters(in: .whitespaces)
        color.hex  = "#\(hexInput.uppercased())"
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteColor() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // 1. Tell SwiftData to delete the color
        modelContext.delete(color)
        
        // 2. FORCE SAVE immediately so the parent UI refreshes without lag
        try? modelContext.save()
        
        // 3. Dismiss the sheet
        dismiss()
    }
}
