import SwiftUI
import SwiftData

enum ActiveSheet: Identifiable {
    case generator
    case manual
    var id: Int { hashValue }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    // Sorted with the newest first
    @Query(sort: \SavedPalette.timestamp, order: .reverse) private var palettes: [SavedPalette]
    
    @State private var activeSheet: ActiveSheet? = nil
    @State private var showAddMenu = false
    
    let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    // Helpers to split the most recent palette from the rest
    var recentPalette: SavedPalette? {
        palettes.first
    }
    var olderPalettes: [SavedPalette] {
        if palettes.isEmpty { return [] }
        return Array(palettes.dropFirst())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. App Header
                    HStack {
                        Text("Palettes")
                            .font(.system(size: 36, weight: .heavy, design: .default))
                        
                        Spacer()
                        
                        Button(action: { showAddMenu = true }) {
                            Image(systemName: "plus")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if palettes.isEmpty {
                        // Empty State
                        VStack(spacing: 12) {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No palettes yet. Create one!")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                        
                    } else {
                        // 2. RECENT SECTION
                        if let recent = recentPalette {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RECENT")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                NavigationLink {
                                    SavedPaletteDetailView(palette: recent)
                                } label: {
                                    RecentPaletteCard(palette: recent)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                                .contextMenu {
                                    Button(role: .destructive) { deletePalette(recent) } label: {
                                        Label("Delete Palette", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        
                        // 3. ALL PALETTES GRID
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ALL PALETTES")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(olderPalettes) { palette in
                                    NavigationLink {
                                        SavedPaletteDetailView(palette: palette)
                                    } label: {
                                        ModernPaletteCard(palette: palette)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) { deletePalette(palette) } label: {
                                            Label("Delete Palette", systemImage: "trash")
                                        }
                                    }
                                }
                                
                                // Dashed "New" Card at the end of the grid
                                Button(action: { showAddMenu = true }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "plus")
                                            .font(.title)
                                            .foregroundColor(.gray)
                                        Text("New")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 180)
                                    .background(Color.gray.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea()) // Off-white background makes the white cards pop
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { item in
                switch item {
                case .generator: ContentView()
                case .manual: ManualPaletteView()
                }
            }
            .sheet(isPresented: $showAddMenu) {
                AddPaletteMenuSheet(activeSheet: $activeSheet)
            }
        }
    }

    private func deletePalette(_ palette: SavedPalette) {
        modelContext.delete(palette)
    }
}

// MARK: - New Recent Palette Card (Horizontal)
struct RecentPaletteCard: View {
    let palette: SavedPalette
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side: Horizontal stacked color bands
            VStack(spacing: 0) {
                ForEach(palette.colors.prefix(5)) { color in
                    Color(hex: color.hex)
                }
            }
            .frame(width: 120)
            
            // Right side: Info
            VStack(alignment: .leading, spacing: 10) {
                Text(palette.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // Hex Code Pills (shows up to 3 to fit nicely)
                HStack(spacing: 6) {
                    ForEach(palette.colors.prefix(3)) { color in
                        Text(color.hex.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                // Date formatter to show like "4 colors • Oct 24"
                Text("\(palette.colors.count) colors • \(palette.timestamp.formatted(.dateTime.month().day()))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(16)
            
            Spacer()
        }
        .frame(height: 120)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Modern Palette Card (Vertical Grid)
struct ModernPaletteCard: View {
    let palette: SavedPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Color Band
            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(5)) { color in
                    Color(hex: color.hex)
                }
            }
            .frame(height: 100)
            
            // Bottom Info Area
            VStack(alignment: .leading, spacing: 4) {
                Text(palette.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 5, height: 5)
                    Text("\(palette.colors.count) colors")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Custom Bottom Menu Sheet
struct AddPaletteMenuSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var activeSheet: ActiveSheet?
    
    var body: some View {
        VStack(spacing: 16) {
            MenuRow(icon: "sparkles.square.filled.on.square", color: .indigo, title: "Generate with AI", subtitle: "Pick a color, let AI do the rest") {
                dismiss()
                activeSheet = .generator
            }
            
            Divider()
            
            MenuRow(icon: "paintbrush.fill", color: .orange, title: "Build Manually", subtitle: "Mix your own colors by hand") {
                dismiss()
                activeSheet = .manual
            }
            
            Divider()
            
            MenuRow(icon: "photo.badge.arrow.down.fill", color: .green, title: "Import from Image", subtitle: "Extract colors from a photo") {
                dismiss() // Placeholder
            }
            
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.top, 16)
        }
        .padding(24)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }
}

struct MenuRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: icon).foregroundColor(.white))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundColor(.black)
                    Text(subtitle).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}
