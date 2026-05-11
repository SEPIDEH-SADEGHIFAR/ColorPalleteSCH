//
//  OnBoarding.swift
//  Awby
//
//  Created by seyedeh sepideh sadeghi far on 11/05/26.
//

import SwiftUI



// MARK: - Onboarding Root View

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var animateIn: Bool = false

    private let totalPages = 5

    // Page backgrounds alternate dark ↔ light to match the app's own screens
    private func bgColor(for page: Int) -> Color {
        switch page {
        case 0: return Color(hex: "#F5F2EE")   // Warm off-white — Welcome
        case 1: return Color(hex: "#0D0D0D")   // Dark — AI Studio
        case 2: return Color(hex: "#F5F2EE")   // Warm off-white — Discover
        case 3: return Color(hex: "#0D0D0D")   // Dark — Build & Extract
        case 4: return Color(hex: "#F5F2EE")   // Warm off-white — Get Started
        default: return Color(hex: "#F5F2EE")
        }
    }

    private var isDark: Bool { currentPage == 1 || currentPage == 3 }

    var body: some View {
        ZStack {
            // ── Animated background colour ──────────────────────
            bgColor(for: currentPage)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: currentPage)

            VStack(spacing: 0) {

                // ── Skip button ────────────────────────────────
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            complete()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isDark ? Color.white.opacity(0.4) : Color(hex: "#1A1A1A").opacity(0.35))
                        .padding(.horizontal, 22)
                        .padding(.top, 16)
                    }
                }
                .frame(height: 52)

                // ── Illustration area ──────────────────────────
                ZStack {
                    switch currentPage {
                    case 0: WelcomeIllustration(animate: animateIn)
                    case 1: AIIllustration(animate: animateIn)
                    case 2: DiscoverIllustration(animate: animateIn)
                    case 3: BuildExtractIllustration(animate: animateIn)
                    case 4: GetStartedIllustration(animate: animateIn)
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipped()

                // ── Text content ───────────────────────────────
                VStack(spacing: 12) {
                    Text(pages[currentPage].headline)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color.white : Color(hex: "#1A1A1A"))
                        .multilineTextAlignment(.center)
                        .kerning(-0.5)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(pages[currentPage].body)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isDark ? Color.white.opacity(0.55) : Color(hex: "#1A1A1A").opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Apple Intelligence disclaimer on AI page
                    if currentPage == 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Requires Apple Intelligence · iPhone 15 Pro or later · iOS 18.1+")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "#A78BFA"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#6C63FF").opacity(0.14))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "#6C63FF").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 36)
                .padding(.top, 32)
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                Spacer(minLength: 0)

                // ── Progress dots ──────────────────────────────
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(
                                i == currentPage
                                    ? (isDark ? Color.white : Color(hex: "#1A1A1A"))
                                    : (isDark ? Color.white.opacity(0.2) : Color(hex: "#1A1A1A").opacity(0.15))
                            )
                            .frame(width: i == currentPage ? 24 : 7, height: 7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // ── CTA Button ─────────────────────────────────
                Button(action: advance) {
                    Text(currentPage == totalPages - 1 ? "Start Exploring" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(isDark ? Color(hex: "#0D0D0D") : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isDark ? Color.white : Color(hex: "#1A1A1A"))
                        )
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 48)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50, currentPage < totalPages - 1 {
                        withAnimation(.spring(response: 0.45)) { currentPage += 1 }
                        triggerPageAnimation()
                    } else if value.translation.width > 50, currentPage > 0 {
                        withAnimation(.spring(response: 0.45)) { currentPage -= 1 }
                        triggerPageAnimation()
                    }
                }
        )
        .onAppear { triggerPageAnimation() }
    }

    // MARK: - Actions

    private func advance() {
        if currentPage < totalPages - 1 {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                currentPage += 1
            }
            triggerPageAnimation()
        } else {
            complete()
        }
    }

    private func complete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
    }

    private func triggerPageAnimation() {
        animateIn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
                animateIn = true
            }
        }
    }

    // MARK: - Page Content

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            headline: "Your Color Studio",
            body: "Create, explore, and save beautiful color palettes. Everything you need, all in one place."
        ),
        OnboardingPage(
            headline: "Generate with AI",
            body: "Pick any color. The AI builds three completely different palettes instantly. Lock what you love, regenerate the rest."
        ),
        OnboardingPage(
            headline: "Discover Any Color",
            body: "Search any color by name or hex code. Explore tints, shades, and six types of color harmony."
        ),
        OnboardingPage(
            headline: "Build or Extract",
            body: "Design a palette from scratch with full control — or extract colors from any photo with one tap."
        ),
        OnboardingPage(
            headline: "You're Ready",
            body: "Your palettes are saved privately on your device. No account. No ads. No tracking. Just color."
        ),
    ]
}

// MARK: - Page Model

struct OnboardingPage {
    let headline: String
    let body: String
}


// ═════════════════════════════════════════════════════════════
// MARK: - PAGE ILLUSTRATIONS
// Each illustration mirrors the actual app UI it's describing.
// ═════════════════════════════════════════════════════════════


// ── PAGE 0: Welcome ──────────────────────────────────────────

struct WelcomeIllustration: View {
    let animate: Bool

    private let swatches: [(color: String, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double)] = [
        ("#6C63FF", 72, -80, -60, 0.00),
        ("#FF6B6B", 56, 70, -90, 0.06),
        ("#2DD4BF", 64, 90, 20, 0.12),
        ("#F59E0B", 48, -30, 80, 0.18),
        ("#F43F5E", 40, -110, 30, 0.24),
        ("#0EA5E9", 52, 20, -30, 0.30),
        ("#6DBF8A", 44, 110, -50, 0.10),
        ("#FF8C42", 36, -60, -110, 0.20),
        ("#A78BFA", 60, -10, 110, 0.08),
        ("#EC4899", 38, 50, 95, 0.16),
    ]

    var body: some View {
        ZStack {
            // Radiating swatches
            ForEach(Array(swatches.enumerated()), id: \.offset) { i, swatch in
                RoundedRectangle(cornerRadius: swatch.size * 0.28)
                    .fill(Color(hex: swatch.color))
                    .frame(width: swatch.size, height: swatch.size)
                    .shadow(color: Color(hex: swatch.color).opacity(0.3), radius: 12, y: 4)
                    .offset(
                        x: animate ? swatch.x : 0,
                        y: animate ? swatch.y : 0
                    )
                    .scaleEffect(animate ? 1.0 : 0.2)
                    .opacity(animate ? 1.0 : 0)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.72)
                            .delay(swatch.delay),
                        value: animate
                    )
            }

            // Centre wordmark
            VStack(spacing: 4) {
                Text("AWBY")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#1A1A1A"))
                    .kerning(-1)
                Text("Color Studio")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
            }
            .scaleEffect(animate ? 1.0 : 0.7)
            .opacity(animate ? 1.0 : 0)
            .animation(.spring(response: 0.6).delay(0.25), value: animate)
        }
    }
}


// ── PAGE 1: AI Generator ─────────────────────────────────────

struct AIIllustration: View {
    let animate: Bool

    private let variations: [[String]] = [
        ["#0D0A1A", "#6C63FF", "#F43F5E", "#F5F2EE", "#4A3580"],   // Bold Contrast
        ["#FF6B6B", "#0EA5E9", "#B5A090", "#39FF14", "#1A0808"],    // Unexpected Mix
        ["#1A0D2E", "#6C63FF", "#C4B8F0", "#FF8C42", "#888888"],    // Tonal Depth
    ]

    private let labels = ["Bold\nContrast", "Unexpected\nMix", "Tonal\nDepth"]

    var body: some View {
        VStack(spacing: 16) {
            // Sparkle header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#A78BFA"))
                Text("3 VARIATIONS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color(hex: "#A78BFA"))
            }
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.05), value: animate)

            // Three variation strips
            HStack(spacing: 10) {
                ForEach(Array(variations.enumerated()), id: \.offset) { vIndex, colors in
                    VStack(spacing: 6) {
                        // Color strip
                        HStack(spacing: 2) {
                            ForEach(Array(colors.enumerated()), id: \.offset) { _, hex in
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(hex: hex))
                            }
                        }
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    vIndex == 0 ? Color.white.opacity(0.3) : Color.white.opacity(0.08),
                                    lineWidth: vIndex == 0 ? 2 : 1
                                )
                        )
                        .scaleEffect(vIndex == 0 ? 1.0 : 0.94)
                        .opacity(vIndex == 0 ? 1.0 : 0.5)

                        // Label
                        Text(labels[vIndex])
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.3)
                            .foregroundStyle(
                                vIndex == 0
                                    ? Color.white.opacity(0.9)
                                    : Color.white.opacity(0.3)
                            )
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 30)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.78)
                            .delay(0.1 + Double(vIndex) * 0.08),
                        value: animate
                    )
                }
            }
            .padding(.horizontal, 28)

            // Swipe indicator
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 11))
                Text("Swipe to compare")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
            }
            .foregroundStyle(Color.white.opacity(0.28))
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.4), value: animate)

            // Lock indicator
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Lock colors you love")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "#A78BFA"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: "#6C63FF").opacity(0.16))
                        .overlay(
                            Capsule().stroke(Color(hex: "#6C63FF").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.5), value: animate)
        }
    }
}


// ── PAGE 2: Discover ─────────────────────────────────────────

struct DiscoverIllustration: View {
    let animate: Bool

    private let sections: [(label: String, colors: [String])] = [
        ("Tints",         ["#EDE9FE", "#DDD6FE", "#C4B5FD", "#A78BFA", "#8B5CF6", "#7C3AED"]),
        ("Shades",        ["#5B21B6", "#4C1D95", "#3B0764", "#2E1065", "#1E0A40", "#0D061F"]),
        ("Analogous",     ["#6EE7B7", "#34D399", "#6C63FF", "#F59E0B", "#EC4899", "#EF4444"]),
        ("Complementary", ["#6C63FF", "#7C3AED", "#F59E0B", "#FBBF24", "#FCD34D"]),
    ]

    var body: some View {
        VStack(spacing: 14) {
            // Search bar mockup
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.35))
                Text("dusty rose, #6C63FF...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.3))
                Spacer()
                Image(systemName: "eyedropper.halffull")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "#1A1A1A"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "#1A1A1A").opacity(0.07), radius: 8, y: 3)
            )
            .padding(.horizontal, 22)
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : -10)
            .animation(.spring(response: 0.5).delay(0.05), value: animate)

            // Harmony rows
            VStack(spacing: 8) {
                ForEach(Array(sections.enumerated()), id: \.offset) { i, section in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(section.label.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.3))
                            .padding(.leading, 22)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(section.colors.enumerated()), id: \.offset) { j, hex in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: hex))
                                        .frame(width: 44, height: 44)
                                        .opacity(animate ? 1 : 0)
                                        .scaleEffect(animate ? 1 : 0.7)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.75)
                                                .delay(0.15 + Double(i) * 0.07 + Double(j) * 0.04),
                                            value: animate
                                        )
                                }
                            }
                            .padding(.horizontal, 22)
                        }
                    }
                }
            }
        }
    }
}


// ── PAGE 3: Build & Extract ───────────────────────────────────

struct BuildExtractIllustration: View {
    let animate: Bool

    private let manualColors: [(hex: String, name: String)] = [
        ("#E63946", "Crimson"),
        ("#F4A261", "Amber"),
        ("#2A9D8F", "Teal"),
        ("#6C63FF", "Violet"),
    ]

    private let photoColors = ["#8B4513", "#D2691E", "#F4A460", "#228B22", "#87CEEB"]

    var body: some View {
        HStack(spacing: 14) {

            // ── Left: Manual Studio ────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FF8C42"))
                    Text("MANUAL")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#FF8C42"))
                }

                VStack(spacing: 6) {
                    ForEach(Array(manualColors.enumerated()), id: \.offset) { i, color in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: color.hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            Text(color.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.75))
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07))
                        )
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : -20)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.8)
                                .delay(0.1 + Double(i) * 0.07),
                            value: animate
                        )
                    }

                    // Add button
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Color")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "#FF8C42"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                            .foregroundStyle(Color(hex: "#FF8C42").opacity(0.35))
                    )
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.42), value: animate)
                }
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 10)

            // ── Right: Image Extract ───────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#2DD4BF"))
                    Text("EXTRACT")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "#2DD4BF"))
                }

                // Photo frame mockup
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#228B22"),
                                    Color(hex: "#8B4513"),
                                    Color(hex: "#87CEEB"),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    // Photo icon
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Your Photo")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1 : 0.85)
                .animation(.spring(response: 0.55).delay(0.15), value: animate)

                // Extracted colors
                HStack(spacing: 5) {
                    ForEach(Array(photoColors.enumerated()), id: \.offset) { i, hex in
                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            Text(hex.dropFirst())
                                .font(.system(size: 6, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))
                        }
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 15)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.78)
                                .delay(0.25 + Double(i) * 0.06),
                            value: animate
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 22)
    }
}


// ── PAGE 4: Get Started ───────────────────────────────────────

struct GetStartedIllustration: View {
    let animate: Bool

    private let paletteColors = [
        "#6C63FF", "#FF6B6B", "#2DD4BF", "#F59E0B", "#FF8C42",
        "#F43F5E", "#0EA5E9", "#6DBF8A",
    ]

    private let badges = [
        (icon: "lock.fill",          label: "Private"),
        (icon: "xmark.circle",       label: "No Ads"),
        (icon: "person.slash",       label: "No Account"),
        (icon: "wifi.slash",         label: "Works Offline"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Big colour strip
            HStack(spacing: 3) {
                ForEach(Array(paletteColors.enumerated()), id: \.offset) { i, hex in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: hex))
                        .frame(height: 110)
                        .opacity(animate ? 1 : 0)
                        .scaleEffect(y: animate ? 1 : 0, anchor: .bottom)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.72)
                                .delay(Double(i) * 0.06),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 28)

            // Trust badges
            HStack(spacing: 10) {
                ForEach(Array(badges.enumerated()), id: \.offset) { i, badge in
                    VStack(spacing: 5) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.6))
                        Text(badge.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color(hex: "#1A1A1A").opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .shadow(color: Color(hex: "#1A1A1A").opacity(0.05), radius: 8, y: 3)
                    )
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.8)
                            .delay(0.3 + Double(i) * 0.07),
                        value: animate
                    )
                }
            }
            .padding(.horizontal, 22)
        }
    }
}


// ═════════════════════════════════════════════════════════════
// MARK: - PREVIEW
// ═════════════════════════════════════════════════════════════

#Preview {
    OnboardingView()
}
