import SwiftUI
import SwiftData

// MARK: - Saved Palette Detail View

struct SavedPaletteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var palette: SavedPalette

    @State private var isAddingColor = false
    @State private var colorToExport: SavedColor?
    @State private var colorToEdit: SavedColor?
    @State private var showPaletteExport = false
    @State private var copiedHex: String? = nil
    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea() // Adaptive Background
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // 1. Full Width Edge-to-Edge Color Header
                    HStack(spacing: 0) {
                        ForEach(palette.colors) { color in
                            Color(hex: color.hex)
                        }
                    }
                    .frame(height: 220)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animateIn)
                    
                    // 2. Content Area (Title + Colors)
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Info Header & Export Button
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(palette.timestamp.relativeFormatted().uppercased())")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                
                                Text(palette.title)
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color("AppText")) // Adaptive Text
                                    .kerning(-0.5)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("\(palette.colors.count) colors")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Full Palette Export Button
                            Button(action: { showPaletteExport = true }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(Color("AppText")) // Adaptive
                                    .frame(width: 44, height: 44)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Card
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
                        
                        Divider()
                            .opacity(animateIn ? 1 : 0)
                        
                        // 3. Feature-Rich Color List
                        VStack(spacing: 12) {
                            ForEach(Array(palette.colors.enumerated()), id: \.element.id) { index, color in
                                DetailColorRow(
                                    color: color,
                                    copiedHex: $copiedHex,
                                    onEdit: { colorToEdit = color },
                                    onExport: { colorToExport = color },
                                    onDelete: {
                                        deleteColor(color) // Uses the instant-delete fix
                                    }
                                )
                                .opacity(animateIn ? 1 : 0)
                                .offset(y: animateIn ? 0 : 16)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.82)
                                        .delay(0.18 + Double(index) * 0.06),
                                    value: animateIn
                                )
                            }
                            
                            // 4. Dashed "Add Color" Button
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
                                .background(Color("AppText").opacity(0.05)) // Adaptive
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 8)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.spring(response: 0.5).delay(0.38), value: animateIn)
                        }
                    }
                    .padding(24)
                    
                    Spacer(minLength: 60)
                }
            }
            .ignoresSafeArea(edges: .top) // Pushes colors smoothly into the notch
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    // Frosted glass pill so the back button is visible on ANY color header
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color("AppText")) // Adaptive Text
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                   // .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
        }
        .toolbarBackground(Color("AppBackground"), for: .navigationBar) // Adaptive Toolbar
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { animateIn = true }
        }
        .sheet(isPresented: $isAddingColor) {
            AddColorView(palette: palette)
        }
        .sheet(item: $colorToEdit) { color in
            EditColorSheet(color: color)
        }
        .sheet(item: $colorToExport) { color in
            ExportColorPreviewView(color: color)
        }
        .sheet(isPresented: $showPaletteExport) {
            ExportPalettePreviewView(palette: palette)
        }
    }

    // Instant-delete fix to prevent lag
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

// MARK: - Feature-Rich Detail Color Row

struct DetailColorRow: View {
    let color: SavedColor
    @Binding var copiedHex: String?
    let onEdit: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    private var isCopied: Bool { copiedHex == color.hex }

    var body: some View {
        HStack(spacing: 14) {
            // Swatch
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: color.hex))
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("AppText").opacity(0.08), lineWidth: 1)
                )

            // Name + hex
            VStack(alignment: .leading, spacing: 4) {
                Text(color.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText")) // Adaptive
                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.38)) // Adaptive
            }

            Spacer()

            // Copy Button
            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copiedHex = color.hex }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation { if copiedHex == color.hex { copiedHex = nil } }
                }
            } label: {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        isCopied ? Color(hex: "#34C759") : Color("AppText").opacity(0.38)
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCopied
                                  ? Color(hex: "#34C759").opacity(0.1)
                                  : Color("AppText").opacity(0.07))
                    )
            }

            // Edit Button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.38))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("AppText").opacity(0.07))
                    )
            }

            // Export Button
            Button(action: onExport) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText").opacity(0.38))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("AppText").opacity(0.07))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground)) // Adaptive Card
                .shadow(color: Color("AppText").opacity(0.05), radius: 10, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("AppText").opacity(0.06), lineWidth: 1)
                )
        )
        // Trailing Swipe to Delete
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        // Leading Swipe to Edit
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(Color(hex: "#6C63FF")) // Accent purple
        }
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Shared Helpers
// ─────────────────────────────────────────────────────────────

extension SavedColor {
    func detailedData() -> (r: Int, g: Int, b: Int, c: Int, m: Int, y: Int, k: Int) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Int((value >> 16) & 0xFF), g = Int((value >> 8) & 0xFF), b = Int(value & 0xFF)
        let rf = CGFloat(r)/255, gf = CGFloat(g)/255, bf = CGFloat(b)/255
        let c_ = 1-rf, m_ = 1-gf, y_ = 1-bf, k_ = min(min(c_, m_), y_)
        if k_ == 1 { return (r, g, b, 0, 0, 0, 100) }
        return (r, g, b, Int((c_-k_)/(1-k_)*100), Int((m_-k_)/(1-k_)*100), Int((y_-k_)/(1-k_)*100), Int(k_*100))
    }
}

extension Date {
    func relativeFormatted() -> String {
        let diff = Calendar.current.dateComponents([.day, .hour], from: self, to: Date())
        if let d = diff.day, d > 0 { return d == 1 ? "1d ago" : "\(d)d ago" }
        if let h = diff.hour, h > 0 { return "\(h)h ago" }
        return "Just now"
    }
}
