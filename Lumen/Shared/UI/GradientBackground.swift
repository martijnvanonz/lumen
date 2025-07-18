import SwiftUI

/// Gradient background component for the wallet homepage
/// Now uses animated gradient with noise overlay instead of static image
struct GradientBackground: View {

    // MARK: - Properties

    /// Whether to ignore safe area
    private let ignoresSafeArea: Bool

    /// Animation speed multiplier
    private let animationSpeed: Double

    /// Noise opacity
    private let noiseOpacity: Double

    // MARK: - Initialization

    /// Initialize animated gradient background
    /// - Parameters:
    ///   - ignoresSafeArea: Whether to ignore safe area (default: true)
    ///   - animationSpeed: Animation speed multiplier (default: 1.0)
    ///   - noiseOpacity: Noise overlay opacity (default: 0.08)
    init(
        ignoresSafeArea: Bool = true,
        animationSpeed: Double = 1.0,
        noiseOpacity: Double = 0.08
    ) {
        self.ignoresSafeArea = ignoresSafeArea
        self.animationSpeed = animationSpeed
        self.noiseOpacity = noiseOpacity
    }

    // MARK: - Legacy initializer for backward compatibility

    /// Legacy initializer that ignores imageName parameter
    /// - Parameters:
    ///   - imageName: Ignored - kept for backward compatibility
    ///   - ignoresSafeArea: Whether to ignore safe area (default: true)
    init(imageName: String = "background", ignoresSafeArea: Bool = true) {
        self.ignoresSafeArea = ignoresSafeArea
        self.animationSpeed = 1.0
        self.noiseOpacity = 0.08
    }

    // MARK: - Body

    var body: some View {
        UniversalAnimatedGradientBackground(
            ignoresSafeArea: ignoresSafeArea,
            animationSpeed: animationSpeed,
            noiseOpacity: noiseOpacity
        )
    }
}

/// Alternative gradient background using SwiftUI gradients
/// Now uses animated gradient for consistency with main background
struct SwiftUIGradientBackground: View {

    // MARK: - Properties

    /// Whether to ignore safe area
    private let ignoresSafeArea: Bool

    /// Animation speed multiplier
    private let animationSpeed: Double

    // MARK: - Initialization

    init(ignoresSafeArea: Bool = true, animationSpeed: Double = 1.0) {
        self.ignoresSafeArea = ignoresSafeArea
        self.animationSpeed = animationSpeed
    }

    // MARK: - Body

    var body: some View {
        // Use fallback version (no noise) for broader compatibility
        AnimatedGradientBackgroundFallback(
            ignoresSafeArea: ignoresSafeArea,
            animationSpeed: animationSpeed
        )
    }
}

/// Fixed gradient background container for wallet homepage
/// The animated gradient stays fixed while content scrolls over it
struct FixedGradientContainer<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let useAnimatedGradient: Bool

    // MARK: - Initialization

    /// Initialize with scrollable content over fixed animated gradient
    /// - Parameters:
    ///   - useAnimatedGradient: Whether to use animated gradient or fallback (default: true)
    ///   - content: The scrollable content to display over the fixed gradient
    init(useAnimatedGradient: Bool = true, @ViewBuilder content: () -> Content) {
        self.useAnimatedGradient = useAnimatedGradient
        self.content = content()
    }

    /// Legacy initializer for backward compatibility
    /// - Parameters:
    ///   - useImageGradient: Mapped to useAnimatedGradient for compatibility
    ///   - content: The scrollable content to display over the fixed gradient
    @available(*, deprecated, message: "Use init(useAnimatedGradient:content:) instead")
    init(useImageGradient: Bool, @ViewBuilder content: () -> Content) {
        self.useAnimatedGradient = useImageGradient
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // FIXED animated gradient background - doesn't scroll
            if useAnimatedGradient {
                GradientBackground()
            } else {
                SwiftUIGradientBackground()
            }

            // SCROLLABLE content overlay
            content
        }
    }
}

/// Container view that provides animated gradient background with content overlay
/// This makes it easy to add the animated gradient background to any view
struct GradientBackgroundContainer<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let useAnimatedGradient: Bool

    // MARK: - Initialization

    /// Initialize with content
    /// - Parameters:
    ///   - useAnimatedGradient: Whether to use animated gradient or fallback (default: true)
    ///   - content: The content to display over the gradient
    init(useAnimatedGradient: Bool = true, @ViewBuilder content: () -> Content) {
        self.useAnimatedGradient = useAnimatedGradient
        self.content = content()
    }

    /// Legacy initializer for backward compatibility
    /// - Parameters:
    ///   - useImageGradient: Mapped to useAnimatedGradient for compatibility
    ///   - content: The content to display over the gradient
    @available(*, deprecated, message: "Use init(useAnimatedGradient:content:) instead")
    init(useImageGradient: Bool, @ViewBuilder content: () -> Content) {
        self.useAnimatedGradient = useImageGradient
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Animated background gradient
            if useAnimatedGradient {
                GradientBackground()
            } else {
                SwiftUIGradientBackground()
            }

            // Content overlay
            content
        }
    }
}

// MARK: - Preview

#Preview("Animated Gradient") {
    GradientBackgroundContainer {
        VStack(spacing: 20) {
            Text("Animated Wallet Background")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .frame(height: 120)
                .padding(.horizontal)
                .shadow(radius: 10)

            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 80)
                    .shadow(radius: 8)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 80)
                    .shadow(radius: 8)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 50)
    }
}

#Preview("Fixed Gradient Container") {
    FixedGradientContainer {
        ScrollView {
            VStack(spacing: 20) {
                // Cards that scroll over fixed gradient
                ForEach(0..<8) { index in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.8))
                        .frame(height: 100)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        .overlay(
                            Text("Card \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.black)
                        )
                }
            }
            .padding(.top, 100)
        }
    }
}

#Preview("Fallback Gradient") {
    GradientBackgroundContainer(useImageGradient: false) {
        VStack(spacing: 20) {
            Text("Fallback Animated Background")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .frame(height: 120)
                .padding(.horizontal)
                .shadow(radius: 10)

            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 80)
                    .shadow(radius: 8)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 80)
                    .shadow(radius: 8)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 50)
    }
}
