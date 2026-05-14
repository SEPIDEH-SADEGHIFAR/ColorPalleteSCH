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
    
    // Manual Color Picker State
    @State private var isDraggingPicker = false
    @State private var dragLocation: CGPoint = .zero
    @State private var currentDraggedColor: UIColor = .clear

    var canSave: Bool {
        !paletteName.trimmingCharacters(in: .whitespaces).isEmpty && !extractedColors.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()

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
                    handleNewImage(image)
                    showCamera = false
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
                        handleNewImage(image)
                    }
                }
            }
        }
    }

    // MARK: - Handlers

    private func handleNewImage(_ image: UIImage) {
        // Normalizes orientation AND strips Retina @2x/@3x scale mismatch
        let normalized = image.normalized()
        selectedImage = normalized
        extractColors(from: normalized)
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
                    .foregroundStyle(Color("AppText"))
                    .lineSpacing(0)
            }
            Spacer()
        }
        .padding(.top, 18)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : -10)
        .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
    }

    // MARK: - Image Picker Section

    private var imagePickerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color("AppText").opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(style: StrokeStyle(lineWidth: selectedImage == nil ? 1.5 : 0, dash: [8, 5]))
                            .foregroundStyle(Color(hex: "#2DD4BF").opacity(0.35))
                    )
                    .frame(height: selectedImage == nil ? 200 : 320)

                if let image = selectedImage {
                    GeometryReader { geo in
                        let renderRect = calculateRenderRect(imageSize: image.size, viewSize: geo.size)
                        
                        ZStack(alignment: .topTrailing) {
                            
                            // The Main Image Area
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .contentShape(Rectangle()) // Ensures entire area catches gestures
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            isDraggingPicker = true
                                            dragLocation = value.location
                                            
                                            if let color = getColor(from: image, at: value.location, in: renderRect) {
                                                currentDraggedColor = color
                                            }
                                        }
                                        .onEnded { value in
                                            isDraggingPicker = false
                                            if let color = getColor(from: image, at: value.location, in: renderRect) {
                                                addManualColor(uiColor: color)
                                            }
                                        }
                                )

                            // Change Photo Overlay
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.55).background(.ultraThinMaterial))
                                    .clipShape(Circle())
                            }
                            .padding(12)
                            
                            // Magnifying Zoom Loupe
                            if isDraggingPicker {
                                ZoomLoupeView(
                                    image: image,
                                    location: dragLocation,
                                    renderRect: renderRect,
                                    color: Color(uiColor: currentDraggedColor)
                                )
                                // Float the loupe above the finger so you can see it
                                .position(x: dragLocation.x, y: dragLocation.y - 85)
                                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.9), value: dragLocation)
                            }
                        }
                    }
                    .frame(height: 320)
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(Color(hex: "#2DD4BF").opacity(0.6))

                            Text("Choose a photo to extract colors from")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.35))
                                .multilineTextAlignment(.center)
                        }
                        // This ensures the entire dashed area is clickable, not just the text/icon
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain) // Prevents the whole box from turning blue when tapped
                }
            }
            .animation(.spring(response: 0.4), value: selectedImage != nil)
            
            if selectedImage != nil && !isExtracting {
                Text("Hold and drag anywhere on the image to magnify and pick a precise color.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
            }

            // Picker buttons
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.stack").font(.system(size: 15, weight: .semibold))
                        Text("Photo Library").font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: "#2DD4BF"))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#2DD4BF").opacity(0.1)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#2DD4BF").opacity(0.3), lineWidth: 1.2)))
                }

                Button { showCamera = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera").font(.system(size: 15, weight: .semibold))
                        Text("Camera").font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color("AppText").opacity(0.6))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("AppText").opacity(0.1), lineWidth: 1.2)))
                }
            }

            // Color count stepper
            if selectedImage != nil && !isExtracting {
                HStack(spacing: 0) {
                    Text("AUTO-EXTRACT").font(.system(size: 10, weight: .bold)).tracking(2).foregroundStyle(Color("AppText").opacity(0.3))
                    Spacer()
                    HStack(spacing: 16) {
                        Button {
                            if colorCount > 3 { colorCount -= 1; if let img = selectedImage { extractColors(from: img) } }
                        } label: {
                            Image(systemName: "minus").font(.system(size: 13, weight: .bold)).foregroundStyle(colorCount > 3 ? Color(hex: "#2DD4BF") : Color("AppText").opacity(0.2))
                                .frame(width: 30, height: 30).background(Color("AppText").opacity(0.07)).clipShape(Circle())
                        }.disabled(colorCount <= 3)

                        Text("\(colorCount) colors").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Color("AppText")).frame(minWidth: 70, alignment: .center)

                        Button {
                            if colorCount < 8 { colorCount += 1; if let img = selectedImage { extractColors(from: img) } }
                        } label: {
                            Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundStyle(colorCount < 8 ? Color(hex: "#2DD4BF") : Color("AppText").opacity(0.2))
                                .frame(width: 30, height: 30).background(Color("AppText").opacity(0.07)).clipShape(Circle())
                        }.disabled(colorCount >= 8)
                    }
                }
                .padding(.top, 4).transition(.opacity)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    // MARK: - Extracting Indicator

    private var extractingIndicator: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color("AppText").opacity(0.07), lineWidth: 3).frame(width: 64, height: 64)
                Circle().trim(from: 0, to: 0.7).stroke(Color(hex: "#2DD4BF"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 64, height: 64).rotationEffect(.degrees(-90))
                Image(systemName: "eyedropper").font(.system(size: 20, weight: .medium)).foregroundStyle(Color(hex: "#2DD4BF"))
            }
            .onAppear { withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) { } }

            Text("Sampling pixels…")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("AppText").opacity(0.5))
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("EXTRACTED").font(.system(size: 10, weight: .bold)).tracking(2.5).foregroundStyle(Color("AppText").opacity(0.28))
                    Text("Your Colors").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(Color("AppText"))
                }
                Spacer()
                Button {
                    if let img = selectedImage { extractColors(from: img) }
                } label: {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color("AppText").opacity(0.5))
                        .frame(width: 36, height: 36).background(Color("AppText").opacity(0.08)).clipShape(Circle())
                }
            }

            HStack(spacing: 3) {
                ForEach(extractedColors) { c in RoundedRectangle(cornerRadius: 8).fill(Color(hex: c.hex)) }
            }
            .frame(height: 52).clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 10) {
                ForEach(Array(extractedColors.enumerated()), id: \.element.id) { index, color in
                    ExtractedColorCard(color: binding(for: color), index: index).transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("PALETTE NAME").font(.system(size: 9, weight: .bold)).tracking(2.5).foregroundStyle(Color("AppText").opacity(0.28))
                HStack(spacing: 12) {
                    Image(systemName: "pencil").font(.system(size: 14, weight: .medium)).foregroundStyle(Color(hex: "#2DD4BF").opacity(0.8))
                    TextField("e.g. Golden Hour", text: $paletteName).font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("AppText")).tint(Color(hex: "#2DD4BF")).focused($nameFocused).submitLabel(.done)
                    if !paletteName.isEmpty {
                        Button { paletteName = "" } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 15)).foregroundStyle(Color("AppText").opacity(0.3)) }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)).overlay(RoundedRectangle(cornerRadius: 16).stroke(nameFocused ? Color(hex: "#2DD4BF").opacity(0.5) : Color("AppText").opacity(0.08), lineWidth: 1.2)))
                .animation(.easeInOut(duration: 0.2), value: nameFocused)
            }
            .padding(.top, 4)

            saveButton
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: savePalette) {
            HStack(spacing: 10) {
                Image(systemName: savedSuccessfully ? "checkmark.circle.fill" : "square.and.arrow.down").font(.system(size: 17, weight: .semibold))
                Text(savedSuccessfully ? "Saved!" : "Save Palette").font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundStyle(savedSuccessfully ? Color(hex: "#34C759") : (canSave ? Color("AppBackground") : Color("AppText").opacity(0.25)))
            .frame(maxWidth: .infinity).frame(height: 58)
            .background(
                Group {
                    if savedSuccessfully {
                        RoundedRectangle(cornerRadius: 18).fill(Color(hex: "#34C759").opacity(0.14)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "#34C759").opacity(0.4), lineWidth: 1.5))
                    } else if canSave {
                        RoundedRectangle(cornerRadius: 18).fill(Color("AppText"))
                    } else {
                        RoundedRectangle(cornerRadius: 18).fill(Color("AppText").opacity(0.07)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AppText").opacity(0.1), lineWidth: 1))
                    }
                }
            )
        }
        .disabled(!canSave || savedSuccessfully)
        .animation(.spring(response: 0.4), value: savedSuccessfully)
        .animation(.easeInOut(duration: 0.2), value: canSave)
    }

    // MARK: - Logic Tools

    private func binding(for color: ExtractedColor) -> Binding<ExtractedColor> {
        guard let index = extractedColors.firstIndex(where: { $0.id == color.id }) else { return .constant(color) }
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
        let savedColors = extractedColors.map { SavedColor(name: $0.name.isEmpty ? "Color" : $0.name, hex: $0.hex) }
        let newPalette = SavedPalette(title: paletteName.trimmingCharacters(in: .whitespaces), colors: savedColors)
        modelContext.insert(newPalette)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { savedSuccessfully = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
    }
    
    // MARK: - Accurate Coordinate Math
    
    private func calculateRenderRect(imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let viewRatio = viewSize.width / viewSize.height
        let imageRatio = imageSize.width / imageSize.height
        
        if imageRatio > viewRatio {
            let renderHeight = viewSize.width / imageRatio
            return CGRect(x: 0, y: (viewSize.height - renderHeight) / 2.0, width: viewSize.width, height: renderHeight)
        } else {
            let renderWidth = viewSize.height * imageRatio
            return CGRect(x: (viewSize.width - renderWidth) / 2.0, y: 0, width: renderWidth, height: viewSize.height)
        }
    }
    
    private func getColor(from image: UIImage, at location: CGPoint, in renderRect: CGRect) -> UIColor? {
        guard renderRect.contains(location) else { return nil }
        
        // Because the image is strictly normalized to 1:1 scale, size = cgImage bounds
        let scaleX = image.size.width / renderRect.width
        let scaleY = image.size.height / renderRect.height
        
        let pointX = (location.x - renderRect.minX) * scaleX
        let pointY = (location.y - renderRect.minY) * scaleY
        
        return image.pixelColor(at: CGPoint(x: pointX, y: pointY))
    }

    private func addManualColor(uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        let name = ColorNamer.name(r: Float(r), g: Float(g), b: Float(b))

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            extractedColors.insert(ExtractedColor(hex: hex, name: name), at: 0)
            if extractedColors.count > 12 { extractedColors.removeLast() }
        }
    }
}

// MARK: - Magnifying Zoom Loupe View (REBUILT)

struct ZoomLoupeView: View {
    let image: UIImage
    let location: CGPoint
    let renderRect: CGRect
    let color: Color
    
    let loupeSize: CGFloat = 100
    let zoomFactor: CGFloat = 2.5
    
    var body: some View {
        ZStack {
            // Drop Shadow
            Circle()
                .fill(Color.black.opacity(0.15))
                .frame(width: loupeSize, height: loupeSize)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
            
            // The Zoomed Photo Viewport
            ZStack {
                Color.white
                
                Image(uiImage: image)
                    .resizable()
                    .frame(width: renderRect.width, height: renderRect.height)
                    // 1. Shift the tapped pixel to exactly the center of this ZStack
                    .offset(
                        x: (renderRect.width / 2) - (location.x - renderRect.minX),
                        y: (renderRect.height / 2) - (location.y - renderRect.minY)
                    )
                    // 2. Scale the view outwardly from the center
                    .scaleEffect(zoomFactor)
            }
            .frame(width: loupeSize, height: loupeSize)
            .clipShape(Circle()) // Hide the massive overflow
            
            // Precision Crosshair
            ZStack {
                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 1, height: 12)
                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 12, height: 1)
                Rectangle().fill(Color.black.opacity(0.5)).frame(width: 1, height: 4)
                Rectangle().fill(Color.black.opacity(0.5)).frame(width: 4, height: 1)
            }
            
            // Color Ring Border
            Circle()
                .strokeBorder(color, lineWidth: 8)
                .frame(width: loupeSize, height: loupeSize)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1))
        }
    }
}

// MARK: - Bulletproof UIImage Extensions

extension UIImage {
    /// Completely strips Orientation and Retina scale mismatches.
    /// This ensures 1 point = 1 pixel, fixing coordinate mapping forever.
    func normalized() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // This locks the pixel extraction math 1:1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Flawless Pixel Extraction
    func pixelColor(at point: CGPoint) -> UIColor? {
        guard let cgImage = cgImage else { return nil }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        
        // Safety bound to avoid crashing on the exact edge of an image
        let safeX = max(0, min(point.x, width - 1))
        let safeY = max(0, min(point.y, height - 1))

        var pixelData: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: &pixelData,
            width: 1, height: 1, // Only need 1 pixel drawn
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return nil }

        context.setBlendMode(.copy)

        // Core Graphics draws from bottom-left up. Calculate Y from the bottom.
        let cgY = height - safeY - 1.0
        context.translateBy(x: -safeX, y: -cgY)

        // Draw image into the 1x1 context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return UIColor(
            red: CGFloat(pixelData[0]) / 255.0,
            green: CGFloat(pixelData[1]) / 255.0,
            blue: CGFloat(pixelData[2]) / 255.0,
            alpha: CGFloat(pixelData[3]) / 255.0
        )
    }
}

// MARK: - Extracted Color Card

struct ExtractedColorCard: View {
    @Binding var color: ExtractedColor
    let index: Int
    @State private var copied = false

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: color.hex))
                .frame(width: 52, height: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("AppText").opacity(0.1), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                TextField("Color name", text: $color.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppText")).tint(Color(hex: "#2DD4BF"))
                Text(color.hex.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.4))
            }
            Spacer()

            Button {
                UIPasteboard.general.string = color.hex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.3)) { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.45))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(copied ? Color(hex: "#34C759").opacity(0.14) : Color("AppText").opacity(0.08)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AppText").opacity(0.07), lineWidth: 1))
        )
    }
}

// MARK: - Models & Engine

struct ExtractedColor: Identifiable {
    let id = UUID()
    var hex: String
    var name: String
}

enum ColorExtractor {
    static func extract(from image: UIImage, count: Int) -> [ExtractedColor] {
        guard let cgImage = image.cgImage else { return [] }
        let sampleSize = CGSize(width: 100, height: 100)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * Int(sampleSize.width)
        var rawData = [UInt8](repeating: 0, count: Int(sampleSize.width) * Int(sampleSize.height) * bytesPerPixel)

        guard let context = CGContext(
            data: &rawData, width: Int(sampleSize.width), height: Int(sampleSize.height),
            bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(origin: .zero, size: sampleSize))

        var pixels: [(r: Float, g: Float, b: Float)] = []
        let total = Int(sampleSize.width) * Int(sampleSize.height)
        for i in 0..<total {
            let offset = i * bytesPerPixel
            let r = Float(rawData[offset])     / 255.0
            let g = Float(rawData[offset + 1]) / 255.0
            let b = Float(rawData[offset + 2]) / 255.0
            let a = Float(rawData[offset + 3]) / 255.0
            guard a > 0.3 else { continue }
            let brightness = (r + g + b) / 3.0
            guard brightness > 0.08, brightness < 0.97 else { continue }
            pixels.append((r, g, b))
        }

        guard !pixels.isEmpty else { return [] }
        let clusters = kMeans(pixels: pixels, k: count, iterations: 12)
        let sorted = clusters.sorted { $0.count > $1.count }

        return sorted.prefix(count).enumerated().map { index, cluster in
            let hex = String(format: "#%02X%02X%02X", Int(cluster.center.r * 255), Int(cluster.center.g * 255), Int(cluster.center.b * 255))
            let name = ColorNamer.name(r: cluster.center.r, g: cluster.center.g, b: cluster.center.b)
            return ExtractedColor(hex: hex, name: name)
        }
    }

    private struct Cluster { var center: (r: Float, g: Float, b: Float); var count: Int }

    private static func kMeans(pixels: [(r: Float, g: Float, b: Float)], k: Int, iterations: Int) -> [Cluster] {
        guard pixels.count >= k else { return [] }
        var centers: [(r: Float, g: Float, b: Float)] = []
        let step = pixels.count / k
        for i in 0..<k { centers.append(pixels[i * step]) }

        var assignments = [Int](repeating: 0, count: pixels.count)

        for _ in 0..<iterations {
            for (i, pixel) in pixels.enumerated() {
                var minDist: Float = .infinity; var nearest = 0
                for (j, center) in centers.enumerated() {
                    let d = distance(pixel, center)
                    if d < minDist { minDist = d; nearest = j }
                }
                assignments[i] = nearest
            }
            var sums = [(r: Float, g: Float, b: Float)](repeating: (0, 0, 0), count: k)
            var counts = [Int](repeating: 0, count: k)
            for (i, pixel) in pixels.enumerated() {
                let c = assignments[i]
                sums[c].r += pixel.r; sums[c].g += pixel.g; sums[c].b += pixel.b; counts[c] += 1
            }
            for j in 0..<k {
                let n = Float(max(counts[j], 1))
                centers[j] = (sums[j].r / n, sums[j].g / n, sums[j].b / n)
            }
        }
        return (0..<k).map { j in Cluster(center: centers[j], count: assignments.filter { $0 == j }.count) }
    }

    private static func distance(_ a: (r: Float, g: Float, b: Float), _ b: (r: Float, g: Float, b: Float)) -> Float {
        let dr = a.r - b.r; let dg = a.g - b.g; let db = a.b - b.b; return dr*dr + dg*dg + db*db
    }
}

enum ColorNamer {
    static func name(r: Float, g: Float, b: Float) -> String {
        let uiColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)

        let h = Double(hue) * 360.0; let s = Double(sat); let v = Double(bri)

        if v < 0.15 { return "Midnight Black" }
        if v > 0.92 && s < 0.08 { return "Ivory White" }
        if s < 0.12 {
            if v < 0.35 { return "Charcoal" }
            if v < 0.65 { return "Slate Gray" }
            return "Silver"
        }

        let prefix: String
        switch h {
        case 0..<15, 345..<360: prefix = "Crimson"
        case 15..<38: prefix = "Burnt Orange"
        case 38..<55: prefix = "Amber"
        case 55..<75: prefix = "Golden"
        case 75..<150: prefix = "Sage"
        case 150..<185: prefix = "Teal"
        case 185..<220: prefix = "Sky"
        case 220..<260: prefix = "Cobalt"
        case 260..<290: prefix = "Violet"
        case 290..<325: prefix = "Magenta"
        case 325..<345: prefix = "Rose"
        default: prefix = "Color"
        }

        let modifier: String
        if v > 0.80 && s > 0.5 { modifier = "Vivid" }
        else if v < 0.40 { modifier = "Deep" }
        else if s < 0.4 { modifier = "Muted" }
        else if v > 0.88 { modifier = "Soft" }
        else { modifier = "" }

        return modifier.isEmpty ? prefix : "\(modifier) \(prefix)"
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

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
        init(_ parent: CameraPickerView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
