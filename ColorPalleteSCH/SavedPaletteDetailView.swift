import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers

// MARK: - Saved Palette Detail View

struct SavedPaletteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var palette: SavedPalette

    @State private var isAddingColor     = false
    @State private var colorToExport:    SavedColor?
    @State private var colorToEdit:      SavedColor?
    @State private var colorToDetail:    SavedColor?
    @State private var showPaletteExport = false
    @State private var showWidgetPicker  = false       // ← opens WidgetPickerView
    @State private var copiedHex: String? = nil
    @State private var animateIn = false
    @State private var draggedColor: SavedColor?

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // 1. Full-Width Color Header
                    HStack(spacing: 0) {
                        ForEach(palette.colors, id: \.self) { color in
                            Color(hex: color.hex)
                        }
                    }
                    .frame(height: 220)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animateIn)

                    // 2. Content Area
                    VStack(alignment: .leading, spacing: 24) {

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(palette.timestamp.relativeFormatted().uppercased())")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)

                                HStack(spacing: 8) {
                                    TextField("Palette Name", text: $palette.title)
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color("AppText"))
                                        .kerning(-0.5)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .submitLabel(.done)
                                }

                                Text("\(palette.colors.count) colors")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer(minLength: 16)

                            // ── Widget Picker Button ─────────────────────
                            Button(action: { showWidgetPicker = true }) {
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.headline)
                                    .foregroundColor(Color("AppText"))
                                    .frame(width: 44, height: 44)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color("AppText").opacity(0.05), radius: 5, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("AppText").opacity(0.06), lineWidth: 1)
                                    )
                            }

                            // ── Export Button ────────────────────────────
                            Button(action: { showPaletteExport = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(Color("AppText"))
                                    .frame(width: 44, height: 44)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: Color("AppText").opacity(0.05), radius: 5, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color("AppText").opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 10)
                        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)

                        Divider().opacity(animateIn ? 1 : 0)

                        // 3. Color List
                        VStack(spacing: 12) {
                            ForEach(palette.colors) { color in
                                let index = palette.colors.firstIndex(of: color) ?? 0
                                DetailColorRow(
                                    color: color,
                                    copiedHex: $copiedHex,
                                    onDetail: { colorToDetail = color },
                                    onEdit:   { colorToEdit   = color },
                                    onExport: { colorToExport = color },
                                    onDelete: { deleteColor(color) }
                                )
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 16)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.82)
                                        .delay(0.18 + Double(index) * 0.06),
                                    value: animateIn
                                )
                                .onDrag {
                                    self.draggedColor = color
                                    return NSItemProvider(object: color.hex as NSString)
                                }
                                .onDrop(of: [.plainText],
                                        delegate: PaletteDropDelegate(
                                            item: color,
                                            items: $palette.colors,
                                            draggedItem: $draggedColor))
                            }
                        }

                        // 4. Add Color Button
                        Button {
                            isAddingColor = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add a color")
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color("AppText").opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.spring(response: 0.5).delay(0.38), value: animateIn)
                    }
                    .padding(24)

                    Spacer(minLength: 60)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color("AppText"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .clipShape(Capsule())
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { animateIn = true }
        }
        .sheet(isPresented: $isAddingColor)    { AddColorView(palette: palette) }
        .sheet(item: $colorToEdit)             { EditColorSheet(color: $0, palette: palette) }
        .sheet(item: $colorToExport)           { ExportColorPreviewView(color: $0) }
        .sheet(isPresented: $showPaletteExport){ ExportPalettePreviewView(palette: palette) }
        .sheet(item: $colorToDetail)           { ColorDetailView(color: $0) }
        .sheet(isPresented: $showWidgetPicker) { WidgetPickerView(palette: palette) }   // ← NEW
    }

    private func deleteColor(_ color: SavedColor) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let index = palette.colors.firstIndex(of: color) {
                palette.colors.remove(at: index)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            modelContext.delete(color)
            try? modelContext.save()
        }
    }
}


// MARK: - Detail Color Row

struct DetailColorRow: View {
    let color:    SavedColor
    @Binding var copiedHex: String?
    let onDetail: () -> Void
    let onEdit:   () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    private var isCopied: Bool { copiedHex == color.hex }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: color.hex))
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                )
                .onTapGesture(perform: onDetail)

            VStack(alignment: .leading, spacing: 4) {
                Text(color.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.38))
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onDetail)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.38))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color("AppText").opacity(0.07)))
            }

            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.38))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color("AppText").opacity(0.07)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: Color("AppText").opacity(0.05), radius: 10, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("AppText").opacity(0.06), lineWidth: 1)
                )
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color(hex: "#6C63FF"))
        }
    }
}


// MARK: - Drag & Drop Delegate

struct PaletteDropDelegate: DropDelegate {
    let item:             SavedColor
    @Binding var items:       [SavedColor]
    @Binding var draggedItem: SavedColor?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem != item,
              let from = items.firstIndex(of: draggedItem),
              let to   = items.firstIndex(of: item),
              from != to else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let moved = items.remove(at: from)
            items.insert(moved, at: to)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}


// MARK: - Helpers

extension SavedColor {
    func detailedData() -> (r: Int, g: Int, b: Int, c: Int, m: Int, y: Int, k: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Int((value >> 16) & 0xFF)
        let g = Int((value >>  8) & 0xFF)
        let b = Int( value        & 0xFF)
        let rf = CGFloat(r)/255, gf = CGFloat(g)/255, bf = CGFloat(b)/255
        let c_ = 1-rf, m_ = 1-gf, y_ = 1-bf, k_ = min(min(c_, m_), y_)
        if k_ == 1 { return (r, g, b, 0, 0, 0, 100) }
        return (r, g, b,
                Int((c_-k_)/(1-k_)*100),
                Int((m_-k_)/(1-k_)*100),
                Int((y_-k_)/(1-k_)*100),
                Int(k_*100))
    }
}

extension Date {
    func relativeFormatted() -> String {
        let diff = Calendar.current.dateComponents([.day, .hour], from: self, to: Date())
        if let d = diff.day,  d > 0 { return d == 1 ? "1d ago" : "\(d)d ago" }
        if let h = diff.hour, h > 0 { return "\(h)h ago" }
        return "Just now"
    }
}
