import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Image Color Extractor View

struct ImageColorExtractorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Image picking
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false

    // Extraction state
    @State private var extractedColors: [ExtractedColor] = []
    @State private var isExtracting = false
    @State private var colorCount: Int = 5

    // Save state
    @State private var paletteName: String = ""
    @State private var savedSuccessfully = false
    @State private var animateIn = false
    @FocusState private var nameFocused: Bool

    var canSave: Bool {
        !paletteName.trimmingCharacters(in: .whitespaces).isEmpty && !extractedColors.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea() // Adaptive Background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        imagePickerSection
                            .padding(.top, 28)

                        if isExtracting {
                            extractingIndicator
                                .padding(.top, 36)
                        } else if !extractedColors.isEmpty {
                            resultsSection
                                .padding(.top, 32)
                        }

                        Spacer(minLength: 60)
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
                            .foregroundStyle(Color("AppText").opacity(0.55))
                            .frame(width: 30, height: 30)
                            .background(Color("AppText").opacity(0.09))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(Color("AppBackground"), for: .navigationBar)
            .sheet(isPresented: $showCamera) {
                CameraPickerView { image in
                    selectedImage = image
                    showCamera = false
                    extractColors(from: image)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        extractColors(from: image)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("IMAGE STUDIO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(Color(hex: "#2DD4BF"))

                Text("Extract\nfrom Image")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppText")) // Adaptive
                    .lineSpacing(0)
            }
            Spacer()

            // Teal orb
           /* ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(hex: "#2DD4BF").opacity(0.45), .clear],
                        center: .center, startRadius: 0, endRadius: 44
                    ))
                    .frame(width: 88, height: 88)
                    .blur(radius: 16)

                Circle()
                    .stroke(Color(hex: "#2DD4BF").opacity(0.25), lineWidth: 1)
                    .frame(width: 58, height: 58)

                Circle()
                    .fill(Color(hex: "#2DD4BF"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    )
            }*/
        }
        .padding(.top, 18)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: - Image Picker Section

    private var imagePickerSection: some View {
        VStack(spacing: 14) {
            // Image preview / drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("AppText").opacity(0.05)) // Adaptive
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                style: StrokeStyle(
                                    lineWidth: selectedImage == nil ? 1.5 : 0,
                                    dash: [8, 5]
                                )
                            )
                            .foregroundStyle(Color(hex: "#2DD4BF").opacity(0.35))
                    )
                    .frame(height: selectedImage == nil ? 200 : 260)

                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            // Re-pick overlay (Kept white as it's an overlay on a photo)
                            VStack {
                                HStack {
                                    Spacer()
                                    PhotosPicker(selection: $selectedItem, matching: .images) {
                                        Label("Change", systemImage: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(
                                                Capsule()
                                                    .fill(Color.black.opacity(0.55))
                                                    .background(
                                                        Capsule().fill(.ultraThinMaterial)
                                                    )
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .padding(14)
                                }
                                Spacer()
                            }
                        )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(Color(hex: "#2DD4BF").opacity(0.6))

                        Text("Choose a photo to extract colors from")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color("AppText").opacity(0.35))
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .animation(.spring(response: 0.4), value: selectedImage != nil)

            // Picker buttons row
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Photo Library")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: "#2DD4BF"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#2DD4BF").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: "#2DD4BF").opacity(0.3), lineWidth: 1.2)
                            )
                    )
                }

                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Camera")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color("AppText").opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("AppText").opacity(0.1), lineWidth: 1.2)
                            )
                    )
                }
            }

            // Color count stepper (only shown after image loaded)
            if selectedImage != nil && !isExtracting {
                HStack(spacing: 0) {
                    Text("EXTRACT")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color("AppText").opacity(0.3))
                    Spacer()
                    HStack(spacing: 16) {
                        Button {
                            if colorCount > 3 {
                                colorCount -= 1
                                if let img = selectedImage { extractColors(from: img) }
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(colorCount > 3 ? Color(hex: "#2DD4BF") : Color("AppText").opacity(0.2))
                                .frame(width: 30, height: 30)
                                .background(Color("AppText").opacity(0.07))
                                .clipShape(Circle())
                        }
                        .disabled(colorCount <= 3)

                        Text("\(colorCount) colors")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("AppText"))
                            .frame(minWidth: 70, alignment: .center)

                        Button {
                            if colorCount < 8 {
                                colorCount += 1
                                if let img = selectedImage { extractColors(from: img) }
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(colorCount < 8 ? Color(hex: "#2DD4BF") : Color("AppText").opacity(0.2))
                                .frame(width: 30, height: 30)
                                .background(Color("AppText").opacity(0.07))
                                .clipShape(Circle())
                        }
                        .disabled(colorCount >= 8)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    // MARK: - Extracting Indicator

    private var extractingIndicator: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 3)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Color(hex: "#2DD4BF"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "eyedropper")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "#2DD4BF"))
            }
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) { }
            }

            Text("Sampling pixels…")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("AppText").opacity(0.5))
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Section label
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("EXTRACTED")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(Color("AppText").opacity(0.28))
                    Text("Your Colors")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                }
                Spacer()

                // Re-extract button
                Button {
                    if let img = selectedImage { extractColors(from: img) }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color("AppText").opacity(0.5))
                        .frame(width: 36, height: 36)
                        .background(Color("AppText").opacity(0.08))
                        .clipShape(Circle())
                }
            }

            // Color strip preview
            HStack(spacing: 3) {
                ForEach(extractedColors) { c in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: c.hex))
                }
            }
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Editable color cards
            VStack(spacing: 10) {
                ForEach(Array(extractedColors.enumerated()), id: \.element.id) { index, color in
                    ExtractedColorCard(color: binding(for: color), index: index)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            // Palette name field
            VStack(alignment: .leading, spacing: 8) {
                Text("PALETTE NAME")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(Color("AppText").opacity(0.28))

                HStack(spacing: 12) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "#2DD4BF").opacity(0.8))

                    TextField("e.g. Golden Hour", text: $paletteName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .tint(Color(hex: "#2DD4BF"))
                        .focused($nameFocused)
                        .submitLabel(.done)

                    if !paletteName.isEmpty {
                        Button { paletteName = "" } label: {
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
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    nameFocused
                                        ? Color(hex: "#2DD4BF").opacity(0.5)
                                        : Color("AppText").opacity(0.08),
                                    lineWidth: 1.2
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: nameFocused)
            }
            .padding(.top, 4)

            // Save button
            saveButton
        }
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
                    : (canSave ? Color("AppBackground") : Color("AppText").opacity(0.25))
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
                        RoundedRectangle(cornerRadius: 18).fill(Color("AppText"))
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
    }

    // MARK: - Logic

    private func binding(for color: ExtractedColor) -> Binding<ExtractedColor> {
        guard let index = extractedColors.firstIndex(where: { $0.id == color.id }) else {
            return .constant(color)
        }
        return $extractedColors[index]
    }

    private func extractColors(from image: UIImage) {
        isExtracting = true
        extractedColors = []

        Task.detached(priority: .userInitiated) {
            let colors = ColorExtractor.extract(from: image, count: await colorCount)
            await MainActor.run {
                withAnimation(.spring(response: 0.5)) {
                    extractedColors = colors
                    isExtracting = false
                }
            }
        }
    }

    private func savePalette() {
        let savedColors = extractedColors.map {
            SavedColor(
                name: $0.name.isEmpty ? "Color" : $0.name,
                hex: $0.hex
            )
        }
        let newPalette = SavedPalette(
            title: paletteName.trimmingCharacters(in: .whitespaces),
            colors: savedColors
        )
        modelContext.insert(newPalette)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { savedSuccessfully = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
}

// MARK: - Extracted Color Card

struct ExtractedColorCard: View {
    @Binding var color: ExtractedColor
    let index: Int
    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {
            // Swatch
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: color.hex))
                .frame(width: 52, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color("AppText").opacity(0.1), lineWidth: 1)
                )

            // Editable name
            VStack(alignment: .leading, spacing: 3) {
                TextField("Color name", text: $color.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText"))
                    .tint(Color(hex: "#2DD4BF"))

                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.4))
            }

            Spacer()

            // Copy hex
            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { copied = false }
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.45))
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(copied
                                  ? Color(hex: "#34C759").opacity(0.14)
                                  : Color("AppText").opacity(0.08))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
                )
        )
    }
}

// MARK: - Extracted Color Model

struct ExtractedColor: Identifiable {
    let id = UUID()
    var hex: String
    var name: String
}

// MARK: - Color Extractor Engine

enum ColorExtractor {

    /// Samples pixels from a downscaled image, clusters them, returns the N most distinct colors.
    static func extract(from image: UIImage, count: Int) -> [ExtractedColor] {
        guard let cgImage = image.cgImage else { return [] }

        // 1. Downscale for performance — 100×100 is plenty for color sampling
        let sampleSize = CGSize(width: 100, height: 100)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * Int(sampleSize.width)
        var rawData = [UInt8](repeating: 0, count: Int(sampleSize.width) * Int(sampleSize.height) * bytesPerPixel)

        guard let context = CGContext(
            data: &rawData,
            width: Int(sampleSize.width),
            height: Int(sampleSize.height),
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(origin: .zero, size: sampleSize))

        // 2. Collect all pixels
        var pixels: [(r: Float, g: Float, b: Float)] = []
        let total = Int(sampleSize.width) * Int(sampleSize.height)
        for i in 0..<total {
            let offset = i * bytesPerPixel
            let r = Float(rawData[offset])     / 255.0
            let g = Float(rawData[offset + 1]) / 255.0
            let b = Float(rawData[offset + 2]) / 255.0
            let a = Float(rawData[offset + 3]) / 255.0
            // Skip nearly transparent pixels
            guard a > 0.3 else { continue }
            // Skip very dark (shadows) and very light (highlights) pixels
            let brightness = (r + g + b) / 3.0
            guard brightness > 0.08, brightness < 0.97 else { continue }
            pixels.append((r, g, b))
        }

        guard !pixels.isEmpty else { return [] }

        // 3. K-means clustering to find dominant colors
        let clusters = kMeans(pixels: pixels, k: count, iterations: 12)

        // 4. Sort by frequency (most dominant first)
        let sorted = clusters.sorted { $0.count > $1.count }

        // 5. Convert to ExtractedColor with auto-generated names
        return sorted.prefix(count).enumerated().map { index, cluster in
            let hex = String(
                format: "#%02X%02X%02X",
                Int(cluster.center.r * 255),
                Int(cluster.center.g * 255),
                Int(cluster.center.b * 255)
            )
            let name = ColorNamer.name(r: cluster.center.r, g: cluster.center.g, b: cluster.center.b)
            return ExtractedColor(hex: hex, name: name)
        }
    }

    // MARK: K-Means

    private struct Cluster {
        var center: (r: Float, g: Float, b: Float)
        var count: Int
    }

    private static func kMeans(
        pixels: [(r: Float, g: Float, b: Float)],
        k: Int,
        iterations: Int
    ) -> [Cluster] {
        guard pixels.count >= k else { return [] }

        // Init centers by spreading through the pixel array
        var centers: [(r: Float, g: Float, b: Float)] = []
        let step = pixels.count / k
        for i in 0..<k {
            centers.append(pixels[i * step])
        }

        var assignments = [Int](repeating: 0, count: pixels.count)

        for _ in 0..<iterations {
            // Assign each pixel to nearest center
            for (i, pixel) in pixels.enumerated() {
                var minDist: Float = .infinity
                var nearest = 0
                for (j, center) in centers.enumerated() {
                    let d = distance(pixel, center)
                    if d < minDist {
                        minDist = d
                        nearest = j
                    }
                }
                assignments[i] = nearest
            }

            // Recompute centers
            var sums = [(r: Float, g: Float, b: Float)](repeating: (0, 0, 0), count: k)
            var counts = [Int](repeating: 0, count: k)
            for (i, pixel) in pixels.enumerated() {
                let c = assignments[i]
                sums[c].r += pixel.r
                sums[c].g += pixel.g
                sums[c].b += pixel.b
                counts[c] += 1
            }
            for j in 0..<k {
                let n = Float(max(counts[j], 1))
                centers[j] = (sums[j].r / n, sums[j].g / n, sums[j].b / n)
            }
        }

        return (0..<k).map { j in
            Cluster(center: centers[j], count: assignments.filter { $0 == j }.count)
        }
    }

    private static func distance(
        _ a: (r: Float, g: Float, b: Float),
        _ b: (r: Float, g: Float, b: Float)
    ) -> Float {
        let dr = a.r - b.r
        let dg = a.g - b.g
        let db = a.b - b.b
        return dr*dr + dg*dg + db*db
    }
}

// MARK: - Color Namer

/// Converts RGB floats into a human-readable color name using HSB hue bucketing.
enum ColorNamer {
    static func name(r: Float, g: Float, b: Float) -> String {
        let uiColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        let h = Double(hue) * 360.0
        let s = Double(sat)
        let v = Double(bri)

        if v < 0.15 { return "Midnight Black" }
        if v > 0.92 && s < 0.08 { return "Ivory White" }
        if s < 0.12 {
            if v < 0.35 { return "Charcoal" }
            if v < 0.65 { return "Slate Gray" }
            return "Silver"
        }

        let prefix: String
        switch h {
        case 0..<15, 345..<360:   prefix = "Crimson"
        case 15..<38:             prefix = "Burnt Orange"
        case 38..<55:             prefix = "Amber"
        case 55..<75:             prefix = "Golden"
        case 75..<150:            prefix = "Sage"
        case 150..<185:           prefix = "Teal"
        case 185..<220:           prefix = "Sky"
        case 220..<260:           prefix = "Cobalt"
        case 260..<290:           prefix = "Violet"
        case 290..<325:           prefix = "Magenta"
        case 325..<345:           prefix = "Rose"
        default:                  prefix = "Color"
        }

        let modifier: String
        if v > 0.80 && s > 0.5 { modifier = "Vivid" }
        else if v < 0.40        { modifier = "Deep" }
        else if s < 0.4         { modifier = "Muted" }
        else if v > 0.88        { modifier = "Soft" }
        else                    { modifier = "" }

        return modifier.isEmpty ? prefix : "\(modifier) \(prefix)"
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss // Let SwiftUI handle dismissal safely

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            // We DO NOT call picker.dismiss here anymore.
            // The onCapture closure handles setting showCamera = false!
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Safely use SwiftUI's native dismiss if the user hits "Cancel"
            parent.dismiss()
        }
    }
}
