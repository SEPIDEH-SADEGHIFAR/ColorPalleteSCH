import SwiftUI
import SwiftData

enum ActiveSheet: Identifiable {
    case generator
    case manual
    var id: Int { hashValue }
}

struct HomeView: View {
    // Access the database context to delete items
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedPalette.timestamp, order: .reverse) private var palettes: [SavedPalette]
    @State private var activeSheet: ActiveSheet? = nil
    
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if palettes.isEmpty {
                    ContentUnavailableView("No Palettes", systemImage: "paintpalette")
                        .padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(palettes) { palette in
                            NavigationLink {
                                SavedPaletteDetailView(palette: palette)
                            } label: {
                                PaletteCard(palette: palette)
                            }
                            .buttonStyle(.plain)
                            // --- NEW: Long Press to Delete ---
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletePalette(palette)
                                } label: {
                                    Label("Delete Palette", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Palettes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { activeSheet = .generator } label: {
                            Label("Generate with AI", systemImage: "wand.and.stars")
                        }
                        Button { activeSheet = .manual } label: {
                            Label("Create Manually", systemImage: "paintbrush.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .generator: ContentView()
                case .manual: ManualPaletteView()
                }
            }
        }
    }

    private func deletePalette(_ palette: SavedPalette) {
        modelContext.delete(palette)
    }
}

// Extracted Card View for cleaner code
struct PaletteCard: View {
    let palette: SavedPalette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 0) {
                ForEach(palette.colors.prefix(5)) { color in
                    Color(hex: color.hex)
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            Text(palette.title)
                .font(.headline)
                .lineLimit(1)
            
            Text("\(palette.colors.count) colors")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
