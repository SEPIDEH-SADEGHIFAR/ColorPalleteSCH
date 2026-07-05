import SwiftUI
import SwiftData
import PhotosUI

// ═════════════════════════════════════════════════════════════
// MARK: - IMAGE COLOR EXTRACTOR VIEW
// ═════════════════════════════════════════════════════════════

struct ImageColorExtractorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // ── Image ────────────────────────────────────────────────
    @State private var selectedImage:    UIImage?
    @State private var photosItem:       PhotosPickerItem?
    @State private var showCamera:       Bool = false

    // ── Extraction ───────────────────────────────────────────
    @State private var mode:             ExtractMode = .auto
    @State private var colorCount:       Int         = 5
    @State private var excludeNeutrals:  Bool        = false
    @State private var isExtracting:     Bool        = false
    @State private var extractedColors:  [IEXColor]  = []

    // ── Tap-to-pick ──────────────────────────────────────────
    @State private var loupeActive:      Bool        = false
    @State private var loupePosition:    CGPoint     = .zero
    @State private var loupeHex:         String      = ""
    @State private var loupeColor:       Color       = .clear

    // ── Palette ──────────────────────────────────────────────
    @State private var paletteName:      String      = ""
    @State private var showSavedBanner:  Bool        = false
    @FocusState private var nameFieldFocused: Bool

    // ── UI ───────────────────────────────────────────────────
    @State private var animateIn:        Bool        = false
    @State private var imageFrameSize:   CGSize      = .zero

    enum ExtractMode: Hashable {
        case auto
        case tapPick
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("AppBackground").ignoresSafeArea()
                mainScrollView
                bottomOverlays
            }
            .navigationTitle("Extract Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.55)) { animateIn = true }
            }
            .fullScreenCover(isPresented: $showCamera) {
                cameraSheet
            }
            .onChange(of: photosItem) { _, newItem in
                handlePhotosItemChange(newItem)
            }
            .onChange(of: excludeNeutrals) { _, _ in
                reextractIfNeeded()
            }
            .onChange(of: colorCount) { _, _ in
                reextractIfNeeded()
            }
        }
    }

    // MARK: ── Top-level pieces (split out so the compiler doesn't choke) ──

    private var mainScrollView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                imageSection
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                if selectedImage != nil {
                    controlsSection
                        .padding(.top, 18)
                        .padding(.horizontal, 20)

                    if !extractedColors.isEmpty {
                        colorsSection
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                        paletteNameSection
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                    } else if mode == .auto && !isExtracting {
                        extractButton
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 80)
            }
        }
    }

    @ViewBuilder
    private var bottomOverlays: some View {
        if !extractedColors.isEmpty {
            saveButton
        }
        if showSavedBanner {
            savedBanner
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Done") { dismiss() }
                .foregroundStyle(Color("AppText"))
        }
    }

    private var cameraSheet: some View {
        IEXCameraView(image: $selectedImage, onPick: {
            resetExtraction()
            if mode == .auto { runExtraction() }
        })
        .ignoresSafeArea()
    }

    private func handlePhotosItemChange(_ item: PhotosPickerItem?) {
        Task {
            guard let item else { return }
            guard let data = try? await item.loadTransferable(type: Data.self) else { return }
            guard let img = UIImage(data: data) else { return }
            await MainActor.run {
                selectedImage = img
                resetExtraction()
                if mode == .auto { runExtraction() }
            }
        }
    }

    // MARK: ── Image Section ───────────────────────────────────

    @ViewBuilder
    private var imageSection: some View {
        if let img = selectedImage {
            imageCard(img)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
        } else {
            emptyImageCard
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.05), value: animateIn)
        }
    }

    private var emptyImageCard: some View {
        VStack(spacing: 20) {
            emptyImageIcon
            emptyImageText
            emptyImageButtons
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(emptyImageBackground)
    }

    private var emptyImageIcon: some View {
        ZStack {
            Circle()
                .fill(Color("AppText").opacity(0.05))
                .frame(width: 88, height: 88)
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color("AppText").opacity(0.22))
        }
    }

    private var emptyImageText: some View {
        VStack(spacing: 6) {
            Text("Choose an image")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppText"))
            Text("Pull colors from any photo")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.38))
        }
    }

    private var emptyImageButtons: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $photosItem, matching: .images) {
                Label("Photo Library", systemImage: "photo.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("AppBackground"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(photoLibraryButtonBackground)
            }

            Button {
                showCamera = true
            } label: {
                Label("Camera", systemImage: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("AppText"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(cameraButtonBackground)
            }
        }
    }

    private var photoLibraryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }

    private var cameraButtonBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("AppText").opacity(0.09), lineWidth: 1)
            )
    }

    private var emptyImageBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [6]))
                    .foregroundStyle(Color("AppText").opacity(0.12))
            )
    }

    private func imageCard(_ img: UIImage) -> some View {
        ZStack(alignment: .bottom) {
            imageCardPhoto(img)
            imageCardBottomBar
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color("AppText").opacity(0.12), radius: 16, y: 6)
        .overlay(alignment: .topLeading) {
            imageCardLoupeOverlay
        }
    }

    private func imageCardPhoto(_ img: UIImage) -> some View {
        GeometryReader { geo in
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .onAppear { imageFrameSize = geo.size }
                .onChange(of: geo.size) { _, newSize in
                    imageFrameSize = newSize
                }
                .contentShape(Rectangle())
                .overlay {
                    tapPickOverlayIfNeeded(img: img, size: geo.size)
                }
        }
        .frame(height: 240)
    }

    @ViewBuilder
    private func tapPickOverlayIfNeeded(img: UIImage, size: CGSize) -> some View {
        if mode == .tapPick {
            tapPickOverlay(img: img, size: size)
        }
    }

    private var imageCardBottomBar: some View {
        HStack(spacing: 10) {
            modeBadge
            Spacer()
            changeImageButton
        }
        .padding(12)
    }

    private var modeBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: mode == .auto ? "sparkles" : "hand.point.up.left.fill")
                .font(.system(size: 11))
            Text(mode == .auto ? "K-means Auto" : "Tap to Pick")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.5)))
    }

    private var changeImageButton: some View {
        PhotosPicker(selection: $photosItem, matching: .images) {
            Image(systemName: "photo.badge.arrow.down.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.black.opacity(0.4)))
        }
    }

    @ViewBuilder
    private var imageCardLoupeOverlay: some View {
        if loupeActive {
            IEXLoupeView(hex: loupeHex, color: loupeColor)
                .position(x: loupePosition.x, y: max(55, loupePosition.y - 68))
                .allowsHitTesting(false)
        }
    }

    // Tap-to-pick gesture on image
    private func tapPickOverlay(img: UIImage, size: CGSize) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(tapPickGesture(img: img, size: size))
    }

    private func tapPickGesture(img: UIImage, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { (val: DragGesture.Value) in
                handleTapPickChanged(val: val, img: img, size: size)
            }
            .onEnded { (_: DragGesture.Value) in
                handleTapPickEnded()
            }
    }

    private func handleTapPickChanged(val: DragGesture.Value, img: UIImage, size: CGSize) {
        let loc = val.location
        guard loc.x >= 0, loc.y >= 0, loc.x <= size.width, loc.y <= size.height else { return }

        guard let samplePoint = Self.imagePoint(forViewPoint: loc, viewSize: size, imageSize: img.size) else {
            return
        }

        guard let hex = IEXColorEngine.samplePixel(from: img, at: samplePoint) else { return }
        loupeHex = hex
        loupeColor = Color(hex: hex)
        loupePosition = loc
        loupeActive = true
    }

    /// Converts a point in the *displayed* view (which shows the image with
    /// `.scaledToFill()` + `.clipped()`) into the corresponding point in the
    /// original image's own coordinate space (in "points", matching
    /// `UIImage.size`, top-left origin — same convention `samplePixel` expects).
    ///
    /// `.scaledToFill()` scales the image by a single uniform factor
    /// (the larger of the width/height ratios) so it fully covers the view,
    /// then centers it and crops whatever overflows. This must be undone
    /// with the *same* uniform scale + centering offset, not independent
    /// X/Y ratios, or the sampled point drifts more the more the image's
    /// aspect ratio differs from the view's.
    private static func imagePoint(forViewPoint viewPoint: CGPoint, viewSize: CGSize, imageSize: CGSize) -> CGPoint? {
        guard viewSize.width > 0, viewSize.height > 0,
              imageSize.width > 0, imageSize.height > 0 else {
            return nil
        }

        let scale: CGFloat = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)

        let displayedWidth: CGFloat = imageSize.width * scale
        let displayedHeight: CGFloat = imageSize.height * scale

        // How much of the scaled image is cropped off on each side.
        let cropX: CGFloat = (displayedWidth - viewSize.width) / 2
        let cropY: CGFloat = (displayedHeight - viewSize.height) / 2

        // Point within the full scaled (pre-crop) image.
        let scaledX: CGFloat = viewPoint.x + cropX
        let scaledY: CGFloat = viewPoint.y + cropY

        // Back out the scale to land in the original image's own point space.
        let imageX: CGFloat = scaledX / scale
        let imageY: CGFloat = scaledY / scale

        guard imageX >= 0, imageY >= 0, imageX <= imageSize.width, imageY <= imageSize.height else {
            return nil
        }

        return CGPoint(x: imageX, y: imageY)
    }

    private func handleTapPickEnded() {
        if !loupeHex.isEmpty {
            let name = IEXColorNames.nearest(to: loupeHex)
            let newColor = IEXColor(hex: loupeHex, name: name, dominance: nil)
            let alreadyExists = extractedColors.contains { existing in
                existing.hex.uppercased() == loupeHex.uppercased()
            }
            if !alreadyExists {
                withAnimation(.spring(response: 0.4)) {
                    extractedColors.append(newColor)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        withAnimation(.easeOut(duration: 0.2)) { loupeActive = false }
    }

    // MARK: ── Controls Section ────────────────────────────────

    private var controlsSection: some View {
        VStack(spacing: 14) {
            modeToggle
            controlsBelowToggle
        }
        .opacity(animateIn ? 1.0 : 0.0)
        .animation(.spring(response: 0.5).delay(0.1), value: animateIn)
    }

    @ViewBuilder
    private var controlsBelowToggle: some View {
        if mode == .auto {
            autoControls
        } else {
            tapHint
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(.auto)
            modeButton(.tapPick)
        }
        .padding(4)
        .background(modeToggleBackground)
    }

    private var modeToggleBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
            )
    }

    private func modeButton(_ m: ExtractMode) -> some View {
        let isSelected = (mode == m)
        return Button {
            withAnimation(.spring(response: 0.35)) {
                mode = m
                resetExtraction()
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: m == .auto ? "sparkles" : "hand.point.up.left.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(m == .auto ? "Auto Extract" : "Tap to Pick")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(isSelected ? Color.white : Color("AppText").opacity(0.45))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                modeButtonBackground(isSelected: isSelected)
            }
        }
    }

    @ViewBuilder
    private func modeButtonBackground(isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }

    private var autoControls: some View {
        VStack(spacing: 10) {
            colorCountRow
            neutralsToggle
        }
    }

    private var colorCountRow: some View {
        HStack {
            Text("Colors to extract")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.55))
            Spacer()
            colorCountStepper
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
    }

    private var colorCountStepper: some View {
        HStack(spacing: 16) {
            Button {
                decrementColorCount()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(colorCount > 2 ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.2))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color("AppText").opacity(0.07)))
            }

            Text("\(colorCount)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color("AppText"))
                .frame(width: 24)

            Button {
                incrementColorCount()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(colorCount < 8 ? Color(hex: "#6C63FF") : Color("AppText").opacity(0.2))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color("AppText").opacity(0.07)))
            }
        }
    }

    private func decrementColorCount() {
        guard colorCount > 2 else { return }
        withAnimation(.spring(response: 0.3)) { colorCount -= 1 }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func incrementColorCount() {
        guard colorCount < 8 else { return }
        withAnimation(.spring(response: 0.3)) { colorCount += 1 }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
            )
    }

    private var neutralsToggle: some View {
        Toggle(isOn: $excludeNeutrals) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Exclude neutrals")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText"))
                Text("Skip whites, blacks, and grays")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.38))
            }
        }
        .tint(Color(hex: "#6C63FF"))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
    }

    private var tapHint: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.point.up.left")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "#6C63FF"))
            Text("Tap anywhere on the image to sample that exact color. A loupe shows a preview before you lift your finger.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.48))
                .lineSpacing(3)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "#6C63FF").opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#6C63FF").opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: ── Extract Button ──────────────────────────────────

    private var extractButton: some View {
        Button(action: runExtraction) {
            HStack(spacing: 10) {
                extractButtonIcon
                Text(isExtracting ? "Extracting colors…" : "Extract Colors")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(extractButtonBackground)
        }
        .disabled(isExtracting)
        .animation(.spring(response: 0.3), value: isExtracting)
    }

    @ViewBuilder
    private var extractButtonIcon: some View {
        if isExtracting {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(0.85)
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private var extractButtonBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color(hex: "#6C63FF").opacity(0.32), radius: 12, y: 5)
    }

    // MARK: ── Colors Section ──────────────────────────────────

    private var colorsSection: some View {
        VStack(spacing: 0) {
            colorsSectionHeader
            colorsSectionList
            colorsSectionLegend
        }
        .padding(16)
        .background(colorsSectionBackground)
    }

    private var colorsSectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(mode == .auto ? "DOMINANT COLORS" : "PICKED COLORS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.28))
                Text("\(extractedColors.count) color\(extractedColors.count == 1 ? "" : "s") found")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("AppText"))
            }
            Spacer()
            clearAllButtonIfNeeded
        }
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var clearAllButtonIfNeeded: some View {
        if mode == .tapPick {
            Button {
                withAnimation { extractedColors.removeAll() }
            } label: {
                Text("Clear all")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#FF453A"))
            }
        }
    }

    private var colorsSectionList: some View {
        let indexedColors: [(index: Int, color: IEXColor)] =
            Array(extractedColors.enumerated()).map { (index: $0.offset, color: $0.element) }

        return VStack(spacing: 10) {
            ForEach(indexedColors, id: \.color.id) { item in
                colorRow(for: item.color, at: item.index)
            }
        }
    }

    private func colorRow(for color: IEXColor, at index: Int) -> some View {
        IEXColorRow(
            color: color,
            showBar: mode == .auto,
            onRemove: {
                removeColor(at: index)
            }
        )
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }

    private func removeColor(at index: Int) {
        withAnimation(.spring(response: 0.35)) {
            guard extractedColors.indices.contains(index) else { return }
            extractedColors.remove(at: index)
        }
    }

    @ViewBuilder
    private var colorsSectionLegend: some View {
        let hasDominance = extractedColors.contains { $0.dominance != nil }
        if mode == .auto && hasDominance {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(Color("AppText").opacity(0.25))
                Text("Bar width shows % of the image this color covers")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.28))
            }
            .padding(.top, 10)
        }
    }

    private var colorsSectionBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .shadow(color: Color("AppText").opacity(0.06), radius: 14, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
            )
    }

    // MARK: ── Palette Name ────────────────────────────────────

    private var paletteNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PALETTE NAME")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundStyle(Color("AppText").opacity(0.28))
            paletteNameField
        }
        .padding(16)
        .background(paletteNameSectionBackground)
    }

    private var paletteNameField: some View {
        HStack(spacing: 10) {
            TextField("e.g. Autumn Forest, Ocean Mood…", text: $paletteName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("AppText"))
                .tint(Color(hex: "#6C63FF"))
                .focused($nameFieldFocused)
                .submitLabel(.done)

            clearPaletteNameButtonIfNeeded
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(paletteNameFieldBackground)
        .animation(.easeInOut(duration: 0.18), value: nameFieldFocused)
    }

    @ViewBuilder
    private var clearPaletteNameButtonIfNeeded: some View {
        if !paletteName.isEmpty {
            Button {
                paletteName = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color("AppText").opacity(0.22))
            }
        }
    }

    private var paletteNameFieldBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("AppBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        nameFieldFocused ? Color(hex: "#6C63FF").opacity(0.35) : Color("AppText").opacity(0.08),
                        lineWidth: 1.2
                    )
            )
    }

    private var paletteNameSectionBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .shadow(color: Color("AppText").opacity(0.05), radius: 10, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
            )
    }

    // MARK: ── Save Button ─────────────────────────────────────

    private var saveButton: some View {
        Button(action: savePalette) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                Text("Save Palette  ·  \(extractedColors.count) colors")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(saveButtonBackground)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .disabled(extractedColors.isEmpty)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var saveButtonBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color("AppText"))
            .shadow(color: Color("AppText").opacity(0.22), radius: 16, y: 6)
    }

    // MARK: ── Saved Banner ────────────────────────────────────

    private var savedBanner: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: "#34C759"))
            Text("Palette saved!")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppText"))
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 28, y: 10)
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: ── Logic ───────────────────────────────────────────

    private func reextractIfNeeded() {
        // Only auto re-run when we're in auto-extract mode and there's
        // already a result on screen — otherwise this would incorrectly
        // kick off an extraction while the user is still in tap-pick mode,
        // or before they've chosen an image at all.
        guard mode == .auto, selectedImage != nil, !extractedColors.isEmpty, !isExtracting else { return }
        runExtraction()
    }

    private func runExtraction() {
        guard let img = selectedImage else { return }
        isExtracting = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            let results = await IEXColorEngine.kMeansExtract(
                from: img,
                k: colorCount,
                excludeNeutrals: excludeNeutrals
            )
            await MainActor.run {
                applyExtractionResults(results)
            }
        }
    }

    private func applyExtractionResults(_ results: [(hex: String, dominance: Double)]) {
        withAnimation(.spring(response: 0.5)) {
            extractedColors = results.map { result in
                IEXColor(
                    hex: result.hex,
                    name: IEXColorNames.nearest(to: result.hex),
                    dominance: result.dominance
                )
            }
            if paletteName.isEmpty {
                paletteName = "Extracted Palette"
            }
        }
        isExtracting = false
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func resetExtraction() {
        withAnimation(.spring(response: 0.35)) {
            extractedColors = []
            paletteName = ""
        }
    }

    private func savePalette() {
        guard !extractedColors.isEmpty else { return }
        let name = paletteName.isEmpty ? "Extracted Palette" : paletteName
        let colors = extractedColors.map { SavedColor(name: $0.name, hex: $0.hex) }
        modelContext.insert(SavedPalette(title: name, colors: colors))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4)) { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showSavedBanner = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - LOUPE VIEW
// ═════════════════════════════════════════════════════════════

struct IEXLoupeView: View {
    let hex:   String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            loupeCircle
            loupeLabel
        }
    }

    private var loupeCircle: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 66, height: 66)
                .shadow(color: color.opacity(0.4), radius: 10, y: 3)
            Circle()
                .strokeBorder(.white, lineWidth: 3)
                .frame(width: 66, height: 66)
            Circle()
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                .frame(width: 68, height: 68)
        }
    }

    private var loupeLabel: some View {
        Text(hex.uppercased())
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(0.62)))
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR ROW  (native-feeling swipe to delete)
// ═════════════════════════════════════════════════════════════

struct IEXColorRow: View {
    let color:    IEXColor
    let showBar:  Bool
    let onRemove: () -> Void

    @State private var swipeOffset: CGFloat = 0
    @State private var copied: Bool = false

    private let deleteZoneWidth: CGFloat = 82

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteZoneBackground
            rowContent
        }
        .onTapGesture {
            if swipeOffset != 0 {
                withAnimation(.spring(response: 0.35)) { swipeOffset = 0 }
            }
        }
    }

    private var deleteZoneBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(hex: "#FF3B30"))
            .overlay(deleteZoneLabel, alignment: .trailing)
            .opacity(swipeOffset < -6 ? 1 : 0)
    }

    private var deleteZoneLabel: some View {
        VStack(spacing: 4) {
            Image(systemName: "trash.fill")
                .font(.system(size: 17, weight: .semibold))
            Text("Delete")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.trailing, 18)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            swatch
            infoBlock
            Spacer()
            copyButton
        }
        .padding(10)
        .background(rowContentBackground)
        .offset(x: swipeOffset)
        .gesture(swipeGesture)
    }

    private var swatch: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: color.hex))
            .frame(width: 46, height: 46)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("AppText").opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color(hex: color.hex).opacity(0.28), radius: 5, y: 2)
    }

    @ViewBuilder
    private var infoBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(color.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppText"))

            if showBar, let dom = color.dominance {
                dominanceBar(dom)
            } else {
                Text(color.hex.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color("AppText").opacity(0.35))
            }
        }
    }

    private func dominanceBar(_ dom: Double) -> some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("AppText").opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: color.hex).opacity(0.75))
                        .frame(width: geo.size.width * dom)
                }
            }
            .frame(height: 5)

            Text("\(Int(dom * 100))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("AppText").opacity(0.38))
                .frame(width: 28, alignment: .trailing)
        }
    }

    private var copyButton: some View {
        Button {
            copyHexToClipboard()
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(copied ? Color(hex: "#34C759") : Color("AppText").opacity(0.32))
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color("AppText").opacity(0.06)))
        }
    }

    private func copyHexToClipboard() {
        UIPasteboard.general.string = color.hex
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3)) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { copied = false }
        }
    }

    private var rowContentBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("AppBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("AppText").opacity(0.06), lineWidth: 1)
            )
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { (val: DragGesture.Value) in
                handleSwipeChanged(val)
            }
            .onEnded { (val: DragGesture.Value) in
                handleSwipeEnded(val)
            }
    }

    private func handleSwipeChanged(_ val: DragGesture.Value) {
        let dx: CGFloat = val.translation.width
        let dy: CGFloat = val.translation.height
        guard abs(dx) > abs(dy) * 1.1 else { return }
        if dx < 0 {
            swipeOffset = max(-deleteZoneWidth, dx * 0.88)
        } else if swipeOffset < 0 {
            swipeOffset = min(0, swipeOffset + dx * 0.5)
        }
    }

    private func handleSwipeEnded(_ val: DragGesture.Value) {
        let dx: CGFloat = val.translation.width
        let vel: CGFloat = val.predictedEndTranslation.width
        withAnimation(.spring(response: 0.4, dampingFraction: 0.76)) {
            if dx < -(deleteZoneWidth * 0.85) || vel < -320 {
                swipeOffset = -UIScreen.main.bounds.width
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    onRemove()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            } else if dx < -(deleteZoneWidth * 0.38) {
                swipeOffset = -deleteZoneWidth
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                swipeOffset = 0
            }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - MODEL
// ═════════════════════════════════════════════════════════════

struct IEXColor: Identifiable {
    let id: UUID = UUID()
    let hex: String
    let name: String
    let dominance: Double?   // nil for manual picks
}


// ═════════════════════════════════════════════════════════════
// MARK: - K-MEANS COLOR ENGINE
// ═════════════════════════════════════════════════════════════

enum IEXColorEngine {

    /// A single RGB sample, kept as a named struct instead of a tuple
    /// so the type-checker never has to infer tuple shapes inside closures.
    struct RGBSample {
        let r: Double
        let g: Double
        let b: Double
    }

    struct ClusterSum {
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        var count: Int = 0
    }

    struct RawResult {
        let r: Double
        let g: Double
        let b: Double
        let dominance: Double

        var hex: String {
            let ri = Int(max(0, min(255, r)))
            let gi = Int(max(0, min(255, g)))
            let bi = Int(max(0, min(255, b)))
            return String(format: "#%02X%02X%02X", ri, gi, bi)
        }
    }

    private static func perceptualDistanceSquared(_ a: RGBSample, _ b: RGBSample) -> Double {
        let dr = a.r - b.r
        let dg = a.g - b.g
        let db = a.b - b.b
        return 0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db
    }

    /// K-means color clustering.  Runs off the main thread on a 150×150 downsampled image.
    static func kMeansExtract(
        from image: UIImage,
        k: Int,
        excludeNeutrals: Bool
    ) async -> [(hex: String, dominance: Double)] {

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let pixels = extractPixelSamples(from: image, excludeNeutrals: excludeNeutrals)

                guard pixels.count >= k, k > 0 else {
                    continuation.resume(returning: [])
                    return
                }

                var centers = initializeCenters(pixels: pixels, k: k)
                let assignments = runLloydIterations(pixels: pixels, centers: &centers, k: k)
                let raw = buildRawResults(pixels: pixels, assignments: assignments, centers: centers, k: k)
                let merged = mergeSimilarClusters(raw)
                let final = normalizeAndSort(merged)

                continuation.resume(returning: Array(final.prefix(k)))
            }
        }
    }

    private static func extractPixelSamples(from image: UIImage, excludeNeutrals: Bool) -> [RGBSample] {
        guard let sourceCGImage = image.cgImage else { return [] }

        let width = 150
        let height = 150
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // Build our own bitmap context with an EXPLICIT, known byte order
        // (.noneSkipLast => opaque R,G,B,[ignored] in that exact memory
        // order) instead of relying on UIGraphicsBeginImageContextWithOptions.
        // That implicit context does not guarantee RGBA byte order — on
        // many devices/OS versions it actually returns BGRA — and reading
        // it as if it were always RGBA silently swaps red and blue for
        // every single pixel. That mismatch is what was producing
        // completely unrelated colors (e.g. a solid yellow photo reporting
        // a blue dominant color, since red/blue are swapped channels of
        // each other). Explicitly specifying the bitmap layout here
        // guarantees the byte order matches exactly what we read below.
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return []
        }

        context.interpolationQuality = .high
        // Neutral gray backdrop as a safety net in case the source has any
        // transparent regions (shouldn't matter now that alpha is ignored,
        // but keeps behavior predictable either way).
        context.setFillColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        // Skip a 1px border: resizing can blend in fringe colors right at
        // the image edge that aren't representative of the photo.
        let inset = 1

        var pixels: [RGBSample] = []
        pixels.reserveCapacity(width * height)

        for y in inset..<(height - inset) {
            for x in inset..<(width - inset) {
                let off: Int = y * bytesPerRow + x * bytesPerPixel
                let r: Double = Double(rawData[off])
                let g: Double = Double(rawData[off + 1])
                let b: Double = Double(rawData[off + 2])

                if excludeNeutrals {
                    let mx: Double = max(r, g, b)
                    let mn: Double = min(r, g, b)
                    if mx - mn < 30 { continue }
                    if mx > 230 { continue }
                    if mx < 25 { continue }
                }
                pixels.append(RGBSample(r: r, g: g, b: b))
            }
        }
        return pixels
    }

    /// K-means++ initialisation — spreads centers across the color space.
    private static func initializeCenters(pixels: [RGBSample], k: Int) -> [RGBSample] {
        var centers: [RGBSample] = []
        centers.append(pixels[Int.random(in: 0..<pixels.count)])

        for _ in 1..<k {
            var dists: [Double] = []
            dists.reserveCapacity(pixels.count)

            for p in pixels {
                var best: Double = Double.infinity
                for c in centers {
                    let d = perceptualDistanceSquared(p, c)
                    if d < best { best = d }
                }
                dists.append(best)
            }

            let totalDist: Double = dists.reduce(0, +)
            guard totalDist > 0 else { break }

            var rand: Double = Double.random(in: 0..<totalDist)
            var chosenIndex: Int = pixels.count - 1
            for (i, d) in dists.enumerated() {
                rand -= d
                if rand <= 0 {
                    chosenIndex = i
                    break
                }
            }
            centers.append(pixels[chosenIndex])
        }

        while centers.count < k {
            centers.append(pixels[Int.random(in: 0..<pixels.count)])
        }
        return centers
    }

    /// Lloyd's algorithm with early stopping (up to 50 iterations).
    private static func runLloydIterations(pixels: [RGBSample], centers: inout [RGBSample], k: Int) -> [Int] {
        var assignments: [Int] = Array(repeating: 0, count: pixels.count)

        for _ in 0..<50 {
            var changed = false

            for (i, p) in pixels.enumerated() {
                var best = 0
                var bestDist = Double.infinity
                for (j, c) in centers.enumerated() {
                    let d = perceptualDistanceSquared(p, c)
                    if d < bestDist {
                        bestDist = d
                        best = j
                    }
                }
                if assignments[i] != best {
                    assignments[i] = best
                    changed = true
                }
            }

            if !changed { break }

            var sums: [ClusterSum] = Array(repeating: ClusterSum(), count: k)
            for (i, p) in pixels.enumerated() {
                let a = assignments[i]
                sums[a].r += p.r
                sums[a].g += p.g
                sums[a].b += p.b
                sums[a].count += 1
            }

            for i in 0..<k where sums[i].count > 0 {
                let n = Double(sums[i].count)
                centers[i] = RGBSample(r: sums[i].r / n, g: sums[i].g / n, b: sums[i].b / n)
            }
        }

        return assignments
    }

    private static func buildRawResults(
        pixels: [RGBSample],
        assignments: [Int],
        centers: [RGBSample],
        k: Int
    ) -> [RawResult] {
        var counts: [Int] = Array(repeating: 0, count: k)
        for a in assignments { counts[a] += 1 }
        let total: Double = Double(pixels.count)

        var raw: [RawResult] = []
        for i in 0..<k {
            guard counts[i] > 0 else { continue }
            let c = centers[i]
            raw.append(RawResult(r: c.r, g: c.g, b: c.b, dominance: Double(counts[i]) / total))
        }
        raw.sort { $0.dominance > $1.dominance }
        return raw
    }

    /// Merge perceptually similar clusters (< 22 perceptual distance).
    private static func mergeSimilarClusters(_ raw: [RawResult]) -> [(hex: String, dominance: Double)] {
        var used: [Bool] = Array(repeating: false, count: raw.count)
        var merged: [(hex: String, dominance: Double)] = []

        for i in 0..<raw.count {
            guard !used[i] else { continue }
            var dom = raw[i].dominance
            used[i] = true

            if i + 1 < raw.count {
                for j in (i + 1)..<raw.count {
                    guard !used[j] else { continue }
                    let dr = raw[i].r - raw[j].r
                    let dg = raw[i].g - raw[j].g
                    let db = raw[i].b - raw[j].b
                    let dist = sqrt(0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db)
                    if dist < 22 {
                        dom += raw[j].dominance
                        used[j] = true
                    }
                }
            }
            merged.append((hex: raw[i].hex, dominance: dom))
        }
        return merged
    }

    private static func normalizeAndSort(_ merged: [(hex: String, dominance: Double)]) -> [(hex: String, dominance: Double)] {
        let sumDom: Double = merged.reduce(0) { $0 + $1.dominance }
        let divisor: Double = max(sumDom, 1)
        var normalized: [(hex: String, dominance: Double)] = merged.map { item in
            (hex: item.hex, dominance: item.dominance / divisor)
        }
        normalized.sort { $0.dominance > $1.dominance }

        // Fold any leftover cluster covering under 1.5% of the image into
        // its most similar remaining cluster instead of listing it as a
        // separate "found" color. Clusters this small are almost always
        // JPEG compression noise, faint shadows, or resize artifacts —
        // not colors a person would recognize as present in the photo.
        let minDominance: Double = 0.015
        guard normalized.count > 1 else { return normalized }

        var kept: [(hex: String, dominance: Double)] = []
        for item in normalized {
            if item.dominance >= minDominance || kept.isEmpty {
                kept.append(item)
            } else {
                // Merge into the perceptually closest already-kept color.
                var bestIndex = 0
                var bestDist = Double.infinity
                let itemRGB = hexComponentsForMerge(item.hex)
                for (i, k) in kept.enumerated() {
                    let kRGB = hexComponentsForMerge(k.hex)
                    let dr = itemRGB.r - kRGB.r
                    let dg = itemRGB.g - kRGB.g
                    let db = itemRGB.b - kRGB.b
                    let d = 0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db
                    if d < bestDist {
                        bestDist = d
                        bestIndex = i
                    }
                }
                kept[bestIndex].dominance += item.dominance
            }
        }

        kept.sort { $0.dominance > $1.dominance }
        return kept
    }

    private static func hexComponentsForMerge(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r: Double = Double((v >> 16) & 0xFF)
        let g: Double = Double((v >> 8) & 0xFF)
        let b: Double = Double(v & 0xFF)
        return (r, g, b)
    }

    /// Sample the pixel color at a point in image coordinates (top-left origin,
    /// in "points" matching UIImage.size — same convention as SwiftUI views).
    ///
    /// Strategy: crop the CGImage down to the exact 1x1 pixel we want, then
    /// draw *that* single pixel into a 1x1 bitmap context. Because the crop
    /// already selects the correct pixel using the image's own native pixel
    /// indexing, there is no separate flip/orientation transform to get
    /// wrong when reading it back out.
    static func samplePixel(from image: UIImage, at point: CGPoint) -> String? {
        // Normalize orientation first so pixel indexing matches what's
        // visually displayed (camera photos often have non-.up EXIF
        // orientation, which would otherwise sample the wrong raw pixel).
        let normalized = image.iexNormalizedOrientation()
        guard let cgImage = normalized.cgImage else { return nil }

        let scale: CGFloat = normalized.scale
        let iw: Int = cgImage.width
        let ih: Int = cgImage.height

        let px: Int = Int((point.x * scale).rounded(.down))
        let py: Int = Int((point.y * scale).rounded(.down))

        guard px >= 0, py >= 0, px < iw, py < ih else { return nil }

        let cropRect = CGRect(x: px, y: py, width: 1, height: 1)
        guard let pixelImage = cgImage.cropping(to: cropRect) else { return nil }

        var pixelData: [UInt8] = [0, 0, 0, 0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(pixelImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        let a: UInt8 = pixelData[3]
        let r: Int
        let g: Int
        let b: Int
        if a > 0 {
            r = Int((Double(pixelData[0]) / Double(a) * 255).rounded())
            g = Int((Double(pixelData[1]) / Double(a) * 255).rounded())
            b = Int((Double(pixelData[2]) / Double(a) * 255).rounded())
        } else {
            r = Int(pixelData[0])
            g = Int(pixelData[1])
            b = Int(pixelData[2])
        }

        return String(
            format: "#%02X%02X%02X",
            max(0, min(255, r)),
            max(0, min(255, g)),
            max(0, min(255, b))
        )
    }
}

extension UIImage {
    /// Returns a copy of this image redrawn with `.up` orientation, so its
    /// `cgImage`'s raw pixel buffer matches what's visually displayed.
    /// Camera captures are frequently stored with a rotated/mirrored EXIF
    /// orientation tag rather than pre-rotated pixel data; skipping this
    /// step is a common cause of "sampled the wrong pixel" bugs.
    func iexNormalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - COLOR NAMES  (200+ names, perceptual RGB distance)
// ═════════════════════════════════════════════════════════════

enum IEXColorNames {

    private struct NamedColor {
        let name: String
        let hex: String
    }

    private static let palette: [NamedColor] = [
        // Reds
        NamedColor(name: "Red", hex: "#FF0000"),
        NamedColor(name: "Dark Red", hex: "#8B0000"),
        NamedColor(name: "Crimson", hex: "#DC143C"),
        NamedColor(name: "Scarlet", hex: "#FF2400"),
        NamedColor(name: "Ruby", hex: "#9B111E"),
        NamedColor(name: "Firebrick", hex: "#B22222"),
        NamedColor(name: "Tomato", hex: "#FF6347"),
        NamedColor(name: "Indian Red", hex: "#CD5C5C"),
        NamedColor(name: "Maroon", hex: "#800000"),
        NamedColor(name: "Burgundy", hex: "#800020"),
        NamedColor(name: "Coral", hex: "#FF6B6B"),
        NamedColor(name: "Brick Red", hex: "#CB4154"),
        NamedColor(name: "Carmine", hex: "#960018"),
        NamedColor(name: "Vermillion", hex: "#E34234"),
        NamedColor(name: "Rose Red", hex: "#C21E56"),
        // Pinks
        NamedColor(name: "Pink", hex: "#FF69B4"),
        NamedColor(name: "Hot Pink", hex: "#FF1493"),
        NamedColor(name: "Deep Pink", hex: "#FF1493"),
        NamedColor(name: "Light Pink", hex: "#FFB6C1"),
        NamedColor(name: "Blush", hex: "#DE5D83"),
        NamedColor(name: "Rose", hex: "#FF007F"),
        NamedColor(name: "Flamingo", hex: "#FC8EAC"),
        NamedColor(name: "Fuchsia", hex: "#FF00FF"),
        NamedColor(name: "Magenta", hex: "#FF00FF"),
        NamedColor(name: "Orchid", hex: "#DA70D6"),
        NamedColor(name: "Mauve", hex: "#E0B0FF"),
        NamedColor(name: "Carnation", hex: "#FFA6C9"),
        NamedColor(name: "Cerise", hex: "#DE3163"),
        NamedColor(name: "Amaranth", hex: "#E52B50"),
        NamedColor(name: "Punch", hex: "#FF4D79"),
        // Oranges
        NamedColor(name: "Orange", hex: "#FF8C00"),
        NamedColor(name: "Dark Orange", hex: "#FF6D00"),
        NamedColor(name: "Amber", hex: "#FFBF00"),
        NamedColor(name: "Tangerine", hex: "#F28500"),
        NamedColor(name: "Apricot", hex: "#FBCEB1"),
        NamedColor(name: "Peach", hex: "#FFCBA4"),
        NamedColor(name: "Pumpkin", hex: "#FF7518"),
        NamedColor(name: "Burnt Orange", hex: "#CC5500"),
        NamedColor(name: "Coral Orange", hex: "#FF7F50"),
        NamedColor(name: "Melon", hex: "#FEBAAD"),
        NamedColor(name: "Bronze Orange", hex: "#B4540A"),
        // Yellows
        NamedColor(name: "Yellow", hex: "#FFFF00"),
        NamedColor(name: "Gold", hex: "#FFD700"),
        NamedColor(name: "Lemon", hex: "#FFF44F"),
        NamedColor(name: "Canary", hex: "#FFEF00"),
        NamedColor(name: "Cream", hex: "#FFFDD0"),
        NamedColor(name: "Butter", hex: "#FFFD74"),
        NamedColor(name: "Mustard", hex: "#FFDB58"),
        NamedColor(name: "Khaki", hex: "#C3B091"),
        NamedColor(name: "Dark Khaki", hex: "#BDB76B"),
        NamedColor(name: "Saffron", hex: "#F4C430"),
        NamedColor(name: "Honey", hex: "#EC9706"),
        NamedColor(name: "Champagne", hex: "#F7E7CE"),
        // Greens
        NamedColor(name: "Green", hex: "#008000"),
        NamedColor(name: "Lime Green", hex: "#32CD32"),
        NamedColor(name: "Dark Green", hex: "#006400"),
        NamedColor(name: "Forest Green", hex: "#228B22"),
        NamedColor(name: "Sage", hex: "#8FBC8F"),
        NamedColor(name: "Olive", hex: "#808000"),
        NamedColor(name: "Dark Olive", hex: "#556B2F"),
        NamedColor(name: "Emerald", hex: "#50C878"),
        NamedColor(name: "Mint", hex: "#98FF98"),
        NamedColor(name: "Seafoam", hex: "#93E9BE"),
        NamedColor(name: "Jade", hex: "#00A86B"),
        NamedColor(name: "Hunter Green", hex: "#355E3B"),
        NamedColor(name: "Moss", hex: "#8A9A5B"),
        NamedColor(name: "Fern", hex: "#4F7942"),
        NamedColor(name: "Pistachio", hex: "#93C572"),
        NamedColor(name: "Avocado", hex: "#568203"),
        NamedColor(name: "Chartreuse", hex: "#7FFF00"),
        NamedColor(name: "Spring Green", hex: "#00FF7F"),
        NamedColor(name: "Bottle Green", hex: "#006A4E"),
        NamedColor(name: "Army Green", hex: "#4B5320"),
        NamedColor(name: "Viridian", hex: "#40826D"),
        NamedColor(name: "Malachite", hex: "#0BDA51"),
        NamedColor(name: "Lime", hex: "#00FF00"),
        // Teals & Cyans
        NamedColor(name: "Teal", hex: "#008080"),
        NamedColor(name: "Dark Teal", hex: "#003333"),
        NamedColor(name: "Cyan", hex: "#00FFFF"),
        NamedColor(name: "Aqua", hex: "#00FFFF"),
        NamedColor(name: "Turquoise", hex: "#40E0D0"),
        NamedColor(name: "Dark Turquoise", hex: "#00CED1"),
        NamedColor(name: "Cadet Blue", hex: "#5F9EA0"),
        NamedColor(name: "Cerulean", hex: "#007BA7"),
        NamedColor(name: "Aquamarine", hex: "#7FFFD4"),
        NamedColor(name: "Tiffany Blue", hex: "#0ABAB5"),
        NamedColor(name: "Verdigris", hex: "#43B3AE"),
        NamedColor(name: "Sky Blue", hex: "#87CEEB"),
        NamedColor(name: "Light Sky Blue", hex: "#87CEFA"),
        NamedColor(name: "Baby Blue", hex: "#89CFF0"),
        // Blues
        NamedColor(name: "Blue", hex: "#0000FF"),
        NamedColor(name: "Light Blue", hex: "#ADD8E6"),
        NamedColor(name: "Dark Blue", hex: "#00008B"),
        NamedColor(name: "Royal Blue", hex: "#4169E1"),
        NamedColor(name: "Navy", hex: "#000080"),
        NamedColor(name: "Midnight Blue", hex: "#191970"),
        NamedColor(name: "Cobalt Blue", hex: "#0047AB"),
        NamedColor(name: "Cornflower Blue", hex: "#6495ED"),
        NamedColor(name: "Periwinkle", hex: "#CCCCFF"),
        NamedColor(name: "Steel Blue", hex: "#4682B4"),
        NamedColor(name: "Powder Blue", hex: "#B0E0E6"),
        NamedColor(name: "Dodger Blue", hex: "#1E90FF"),
        NamedColor(name: "Ocean Blue", hex: "#4F42B5"),
        NamedColor(name: "Electric Blue", hex: "#7DF9FF"),
        NamedColor(name: "Denim", hex: "#1560BD"),
        NamedColor(name: "Sapphire", hex: "#0F52BA"),
        NamedColor(name: "Azure", hex: "#007FFF"),
        NamedColor(name: "Deep Sky Blue", hex: "#00BFFF"),
        NamedColor(name: "Ice Blue", hex: "#99C5C4"),
        // Purples & Violets
        NamedColor(name: "Purple", hex: "#800080"),
        NamedColor(name: "Light Purple", hex: "#B39DDB"),
        NamedColor(name: "Dark Purple", hex: "#4A0072"),
        NamedColor(name: "Violet", hex: "#EE82EE"),
        NamedColor(name: "Lavender", hex: "#E6E6FA"),
        NamedColor(name: "Indigo", hex: "#4B0082"),
        NamedColor(name: "Plum", hex: "#DDA0DD"),
        NamedColor(name: "Thistle", hex: "#D8BFD8"),
        NamedColor(name: "Grape", hex: "#6F2DA8"),
        NamedColor(name: "Eggplant", hex: "#614051"),
        NamedColor(name: "Amethyst", hex: "#9966CC"),
        NamedColor(name: "Lilac", hex: "#C8A2C8"),
        NamedColor(name: "Wisteria", hex: "#C9A0DC"),
        NamedColor(name: "Heliotrope", hex: "#DF73FF"),
        NamedColor(name: "Mulberry", hex: "#C54B8C"),
        NamedColor(name: "Royal Purple", hex: "#7851A9"),
        NamedColor(name: "Iris", hex: "#5A4FCF"),
        NamedColor(name: "Byzantium", hex: "#702963"),
        NamedColor(name: "Mauve Purple", hex: "#7F4A7F"),
        // Browns & Neutrals
        NamedColor(name: "Brown", hex: "#A52A2A"),
        NamedColor(name: "Light Brown", hex: "#C4A882"),
        NamedColor(name: "Dark Brown", hex: "#5C4033"),
        NamedColor(name: "Tan", hex: "#D2B48C"),
        NamedColor(name: "Beige", hex: "#F5F5DC"),
        NamedColor(name: "Sand", hex: "#C2B280"),
        NamedColor(name: "Caramel", hex: "#C68642"),
        NamedColor(name: "Coffee", hex: "#6F4E37"),
        NamedColor(name: "Chocolate", hex: "#7B3F00"),
        NamedColor(name: "Mahogany", hex: "#C04000"),
        NamedColor(name: "Sienna", hex: "#A0522D"),
        NamedColor(name: "Umber", hex: "#635147"),
        NamedColor(name: "Chestnut", hex: "#954535"),
        NamedColor(name: "Russet", hex: "#80461B"),
        NamedColor(name: "Sepia", hex: "#704214"),
        NamedColor(name: "Terracotta", hex: "#E2725B"),
        NamedColor(name: "Clay", hex: "#B66A50"),
        NamedColor(name: "Copper", hex: "#B87333"),
        NamedColor(name: "Bronze", hex: "#CD7F32"),
        NamedColor(name: "Ochre", hex: "#CC7722"),
        NamedColor(name: "Rust", hex: "#B7410E"),
        NamedColor(name: "Walnut", hex: "#773F1A"),
        NamedColor(name: "Taupe", hex: "#483C32"),
        NamedColor(name: "Burnt Sienna", hex: "#E97451"),
        NamedColor(name: "Raw Sienna", hex: "#D2691E"),
        NamedColor(name: "Cinnamon", hex: "#D2691E"),
        // Grays & Blacks
        NamedColor(name: "Gray", hex: "#808080"),
        NamedColor(name: "Light Gray", hex: "#D3D3D3"),
        NamedColor(name: "Dark Gray", hex: "#404040"),
        NamedColor(name: "Silver", hex: "#C0C0C0"),
        NamedColor(name: "Charcoal", hex: "#36454F"),
        NamedColor(name: "Slate Gray", hex: "#708090"),
        NamedColor(name: "Dim Gray", hex: "#696969"),
        NamedColor(name: "Gainsboro", hex: "#DCDCDC"),
        NamedColor(name: "Ash Gray", hex: "#B2BEB5"),
        NamedColor(name: "Smoke", hex: "#738276"),
        NamedColor(name: "Gunmetal", hex: "#2A3439"),
        NamedColor(name: "Iron", hex: "#4C4C4C"),
        NamedColor(name: "Pewter", hex: "#96A8A1"),
        NamedColor(name: "Cool Gray", hex: "#8C92AC"),
        NamedColor(name: "Warm Gray", hex: "#808069"),
        NamedColor(name: "Jet Black", hex: "#0A0A0A"),
        NamedColor(name: "Onyx", hex: "#353839"),
        NamedColor(name: "Graphite", hex: "#474B4E"),
        NamedColor(name: "Obsidian", hex: "#1B1B1B"),
        NamedColor(name: "Black", hex: "#000000"),
        // Whites & Off-Whites
        NamedColor(name: "White", hex: "#FFFFFF"),
        NamedColor(name: "Off White", hex: "#FAF9F6"),
        NamedColor(name: "Ivory", hex: "#FFFFF0"),
        NamedColor(name: "Snow", hex: "#FFFAFA"),
        NamedColor(name: "Linen", hex: "#FAF0E6"),
        NamedColor(name: "Ghost White", hex: "#F8F8FF"),
        NamedColor(name: "Seashell", hex: "#FFF5EE"),
        NamedColor(name: "Pearl", hex: "#F0EAD6"),
        NamedColor(name: "Alabaster", hex: "#F2F0EB"),
        NamedColor(name: "Eggshell", hex: "#F0EAD6"),
        NamedColor(name: "Vanilla", hex: "#F3E5AB"),
        NamedColor(name: "Cream White", hex: "#FFFDD0"),
        NamedColor(name: "Antique White", hex: "#FAEBD7"),
        NamedColor(name: "Old Lace", hex: "#FDF5E6"),
        // Trendy
        NamedColor(name: "Millennial Pink", hex: "#F4A7B9"),
        NamedColor(name: "Rose Gold", hex: "#B76E79"),
        NamedColor(name: "Viva Magenta", hex: "#BB2649"),
        NamedColor(name: "Peach Fuzz", hex: "#FFBE98"),
        NamedColor(name: "Neon Green", hex: "#39FF14"),
        NamedColor(name: "Neon Pink", hex: "#FF6EC7"),
        NamedColor(name: "Pastel Blue", hex: "#AEC6CF"),
        NamedColor(name: "Pastel Green", hex: "#77DD77"),
        NamedColor(name: "Pastel Purple", hex: "#B39EB5"),
        NamedColor(name: "Pastel Yellow", hex: "#FDFD96"),
        NamedColor(name: "Electric Purple", hex: "#BF00FF"),
    ]

    private static func hexComponents(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let s = hex.replacingOccurrences(of: "#", with: "")
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r: Double = Double((v >> 16) & 0xFF)
        let g: Double = Double((v >> 8) & 0xFF)
        let b: Double = Double(v & 0xFF)
        return (r, g, b)
    }

    /// Nearest name using perceptual (luminance-weighted) RGB distance.
    static func nearest(to hex: String) -> String {
        let target = hexComponents(hex)

        var best: String = "Color"
        var bestDist: Double = Double.infinity

        for entry in palette {
            let ref = hexComponents(entry.hex)
            let dr = target.r - ref.r
            let dg = target.g - ref.g
            let db = target.b - ref.b
            let d = 0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db
            if d < bestDist {
                bestDist = d
                best = entry.name
            }
        }
        return best
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - CAMERA PICKER WRAPPER
// ═════════════════════════════════════════════════════════════

struct IEXCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onPick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiVC: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: IEXCameraView

        init(_ parent: IEXCameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.onPick()
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
