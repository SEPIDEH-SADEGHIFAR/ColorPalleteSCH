import SwiftUI

// ═════════════════════════════════════════════════════════════
// MARK: - ONBOARDING  (5 pages)
//
// Hook into your App entry point:
//
//   @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
//   ...
//   if hasSeenOnboarding { MainTabView() } else { OnboardingView() }
// ═════════════════════════════════════════════════════════════

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0
    private let totalPages = 5

    var body: some View {
        ZStack(alignment: .bottom) {
            Color("AppBackground").ignoresSafeArea()

            TabView(selection: $page) {
                OBWelcomePage().tag(0)
                OBAIPage().tag(1)
                OBBuildPage().tag(2)
                OBToolsPage().tag(3)
                OBWidgetPage(onFinish: finish).tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            OBBottomNav(page: $page, total: totalPages, onSkip: finish)
        }
        .ignoresSafeArea()
    }

    private func finish() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.5)) { hasSeenOnboarding = true }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - BOTTOM NAVIGATION BAR
// ═════════════════════════════════════════════════════════════

private struct OBBottomNav: View {
    @Binding var page: Int
    let total: Int
    let onSkip: () -> Void

    var isLast: Bool { page == total - 1 }

    var body: some View {
        HStack(spacing: 0) {
            // Skip (hidden on last page)
            Button("Skip", action: onSkip)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color("AppText").opacity(0.32))
                .frame(width: 64, alignment: .leading)
                .opacity(isLast ? 0 : 1)

            Spacer()

            // Progress dots
            HStack(spacing: 7) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i == page
                              ? Color(hex: "#6C63FF")
                              : Color("AppText").opacity(0.14))
                        .frame(width: i == page ? 26 : 7, height: 7)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: page)
                }
            }

            Spacer()

            // Next (hidden on last page)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.45)) { page += 1 }
            } label: {
                HStack(spacing: 3) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "#6C63FF"))
            }
            .frame(width: 64, alignment: .trailing)
            .opacity(isLast ? 0 : 1)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 50)
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color("AppBackground").opacity(0), Color("AppBackground")],
                startPoint: .top, endPoint: .center
            )
            .ignoresSafeArea()
        )
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE 1 · WELCOME
// ═════════════════════════════════════════════════════════════

private struct OBWelcomePage: View {
    @State private var appeared = false
    private let palette = ["#FF6B6B", "#FFE66D", "#4ECDC4", "#45B7D1", "#A29BFE"]

    var body: some View {
        ZStack {
            Color("AppBackground")

            VStack(spacing: 0) {
                // ── Color strip header ───────────────────────
                ZStack(alignment: .bottom) {
                    HStack(spacing: 0) {
                        ForEach(palette, id: \.self) { Color(hex: $0) }
                    }
                    .frame(height: 260)

                    // Gradient fade to background
                    LinearGradient(
                        colors: [.clear, Color("AppBackground")],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 100)

                    // Floating title card
                    VStack(spacing: 6) {
                        Text("AWBY")
                            .font(.system(size: 76, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                        Text("آبی  ·  Blue in Persian")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding(.bottom, 20)
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.1), value: appeared)
                }

                // ── Text ────────────────────────────────────
                VStack(spacing: 18) {
                    Spacer().frame(height: 28)

                    Text("Your Personal\nColor Studio")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("Build, save, and live with beautiful\ncolor palettes — on every screen\nyou own.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)

                    // Feature pills
                    HStack(spacing: 8) {
                        ForEach(["✦ AI", "📷 Photo", "🎨 Manual"], id: \.self) { label in
                            Text(label)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color("AppText").opacity(0.45))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(Color("AppText").opacity(0.07)))
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(response: 0.5).delay(0.25), value: appeared)
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65).delay(0.1)) { appeared = true }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE 2 · AI GENERATOR
// ═════════════════════════════════════════════════════════════

private struct OBAIPage: View {
    @State private var appeared = false
    @State private var pulse    = false
    private let presets = ["Pastel", "Intense", "Fancy Dark", "Tarnish", "Pimp", "Sensible"]

    var body: some View {
        ZStack {
            Color("AppBackground")

            VStack(spacing: 0) {
                // ── Glowing sparkle orb ──────────────────────
                ZStack {
                    // Outer soft halo
                    Circle()
                        .fill(Color(hex: "#6C63FF").opacity(0.1))
                        .frame(width: 260, height: 260)
                        .scaleEffect(pulse ? 1.18 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.4)
                            .repeatForever(autoreverses: true), value: pulse)

                    // Main orb
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 160, height: 160)
                        .shadow(color: Color(hex: "#6C63FF").opacity(0.5), radius: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(height: 280)
                .scaleEffect(appeared ? 1 : 0.75)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.1), value: appeared)

                // ── Text ────────────────────────────────────
                VStack(spacing: 18) {
                    Spacer().frame(height: 20)

                    Text("Meet Your\nAI Designer")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("Describe a vibe. Set the mood.\nApple Intelligence crafts a harmonious\npalette in seconds — all on device.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)

                    // Preset chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                Text(preset)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "#6C63FF"))
                                    .padding(.horizontal, 13).padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "#6C63FF").opacity(0.1))
                                            .overlay(Capsule()
                                                .stroke(Color(hex: "#6C63FF").opacity(0.2), lineWidth: 1))
                                    )
                            }
                        }
                        .padding(.horizontal, 30)
                    }

                    // Requirement note
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                        Text("Requires iOS 26 + Apple Intelligence")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("AppText").opacity(0.25))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(.spring(response: 0.55).delay(0.22), value: appeared)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65).delay(0.1)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE 3 · THREE WAYS TO BUILD
// ═════════════════════════════════════════════════════════════

private struct OBBuildPage: View {
    @State private var appeared = false

    private struct Method: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let desc:  String
        let color: String
    }

    private let methods = [
        Method(icon: "sparkles",        label: "AI",     desc: "Describe a mood,\nget a palette",    color: "#6C63FF"),
        Method(icon: "camera.fill",     label: "Photo",  desc: "Extract colors\nfrom any image",     color: "#F59E0B"),
        Method(icon: "paintpalette.fill",label: "Manual", desc: "Build color by\ncolor, your way", color: "#10B981"),
    ]

    var body: some View {
        ZStack {
            Color("AppBackground")

            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // ── Three method cards ───────────────────────
                HStack(spacing: 12) {
                    ForEach(Array(methods.enumerated()), id: \.element.id) { i, m in
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: m.color).opacity(0.12))
                                    .frame(width: 72, height: 72)
                                Image(systemName: m.icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(Color(hex: m.color))
                            }
                            Text(m.label)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(Color("AppText"))
                            Text(m.desc)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color("AppText").opacity(0.42))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.vertical, 22).padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                .shadow(color: Color("AppText").opacity(0.06), radius: 14, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color(hex: m.color).opacity(0.14), lineWidth: 1.5)
                                )
                        )
                        .scaleEffect(appeared ? 1 : 0.88)
                        .opacity(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.72)
                            .delay(0.1 + Double(i) * 0.09),
                            value: appeared)
                    }
                }
                .padding(.horizontal, 22)

                // ── Text ────────────────────────────────────
                VStack(spacing: 18) {
                    Spacer().frame(height: 36)

                    Text("Three Ways\nto Create")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("No matter your mood or workflow,\nAWBY has the right tool.\nSwitch between them anytime.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)

                    // Tip chip
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color(hex: "#F59E0B"))
                        Text("Tap the ＋ button on the home screen to start")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("AppText").opacity(0.4))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#F59E0B").opacity(0.08))
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.38), value: appeared)
                }
                .padding(.horizontal, 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.28), value: appeared)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65)) { appeared = true }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE 4 · COLOR TOOLS & HARMONY
// ═════════════════════════════════════════════════════════════

private struct OBToolsPage: View {
    @State private var appeared = false
    private let harmonyHexes = ["#E63946", "#FF9F0A", "#FFD60A", "#34C759", "#0A84FF", "#BF5AF2"]
    private let spaces = ["HEX", "RGB", "CMYK", "HSL", "HSB", "LAB"]

    var body: some View {
        ZStack {
            Color("AppBackground")

            VStack(spacing: 0) {
                // ── Harmony wheel ────────────────────────────
                ZStack {
                    // Center eyedropper hub
                    Circle()
                        .fill(Color(hex: "#6C63FF"))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "#6C63FF").opacity(0.45), radius: 14)
                        .overlay(
                            Image(systemName: "eyedropper")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .scaleEffect(appeared ? 1 : 0.5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.55).delay(0.35), value: appeared)

                    // Orbiting color dots
                    ForEach(Array(harmonyHexes.enumerated()), id: \.offset) { i, hex in
                        let deg = Double(i) * 60.0 - 90.0
                        let rad = deg * .pi / 180.0
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 50, height: 50)
                            .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1.5))
                            .shadow(color: Color(hex: hex).opacity(0.45), radius: 8, y: 3)
                            .offset(x: CGFloat(92 * cos(rad)), y: CGFloat(92 * sin(rad)))
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.62)
                                .delay(0.08 + Double(i) * 0.07),
                                value: appeared)
                    }
                }
                .frame(width: 260, height: 260)
                .padding(.top, 52)

                // Color space pills
                HStack(spacing: 6) {
                    ForEach(spaces, id: \.self) { s in
                        Text(s)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color("AppText").opacity(0.38))
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("AppText").opacity(0.07))
                            )
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.5), value: appeared)
                .padding(.top, 18)

                // ── Text ────────────────────────────────────
                VStack(spacing: 18) {
                    Spacer().frame(height: 24)

                    Text("Every Color,\nFully Understood")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("Tap any color for its full data — HEX,\nRGB, CMYK, HSL, LAB and more.\nPlus 6 harmony types, one tap to copy.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.3), value: appeared)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65)) { appeared = true }
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE 5 · WIDGETS & GO
// ═════════════════════════════════════════════════════════════

private struct OBWidgetPage: View {
    let onFinish: () -> Void
    @State private var appeared = false

    private let stripesColors = ["#2A9D8F", "#264653", "#E9C46A", "#F4A261", "#E76F51"]
    private let neonColors    = ["#6C63FF", "#FF6584", "#43CBFF", "#F9B234", "#A29BFE"]

    var body: some View {
        ZStack {
            Color("AppBackground")

            VStack(spacing: 0) {
                // ── Two mini widget previews ─────────────────
                HStack(spacing: 16) {

                    // Stripes
                    ZStack(alignment: .bottom) {
                        HStack(spacing: 0) {
                            ForEach(stripesColors, id: \.self) { Color(hex: $0) }
                        }
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.55)],
                            startPoint: .center, endPoint: .bottom)
                        Text("Ocean Tones")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.bottom, 11)
                    }
                    .frame(width: 152, height: 152)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color("AppText").opacity(0.18), radius: 18, y: 8)

                    // Neon
                    ZStack {
                        Color(red: 0.03, green: 0.03, blue: 0.09)
                        VStack(spacing: 14) {
                            Text("NEON")
                                .font(.system(size: 8, weight: .bold)).tracking(2)
                                .foregroundStyle(.white.opacity(0.28))
                            VStack(spacing: 10) {
                                HStack(spacing: 12) {
                                    ForEach(Array(neonColors.prefix(3).enumerated()), id: \.offset) { _, hex in
                                        neonOrb(hex)
                                    }
                                }
                                HStack(spacing: 12) {
                                    ForEach(Array(neonColors.dropFirst(3).enumerated()), id: \.offset) { _, hex in
                                        neonOrb(hex)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: 152, height: 152)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color("AppText").opacity(0.18), radius: 18, y: 8)
                }
                .scaleEffect(appeared ? 1 : 0.82)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1), value: appeared)
                .padding(.top, 60)

                Text("8 WIDGET STYLES · EDGE TO EDGE")
                    .font(.system(size: 9, weight: .bold)).tracking(2)
                    .foregroundStyle(Color("AppText").opacity(0.22))
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.28), value: appeared)

                // ── Text ────────────────────────────────────
                VStack(spacing: 18) {
                    Spacer().frame(height: 24)

                    Text("Lives on Your\nHome Screen")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color("AppText"))
                        .multilineTextAlignment(.center)

                    Text("Pin any palette as a widget in 8 styles —\nStripes, Neon, Arch, Spectrum and more.\nExport stickers to share anywhere.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color("AppText").opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 30)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5).delay(0.2), value: appeared)

                Spacer()

                // ── Let's Go! ────────────────────────────────
                Button(action: onFinish) {
                    HStack(spacing: 12) {
                        Text("Let's Go!")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#6C63FF"), Color(hex: "#A78BFA")],
                                startPoint: .leading, endPoint: .trailing))
                            .shadow(color: Color(hex: "#6C63FF").opacity(0.38), radius: 18, y: 7)
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 130)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.55).delay(0.4), value: appeared)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65).delay(0.1)) { appeared = true }
        }
    }

    private func neonOrb(_ hex: String) -> some View {
        let col = Color(hex: hex)
        return Circle()
            .fill(col)
            .frame(width: 24, height: 24)
            .shadow(color: col.opacity(0.9), radius: 7)
            .shadow(color: col.opacity(0.4), radius: 14)
    }
}
