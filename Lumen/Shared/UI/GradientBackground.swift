import SwiftUI

/// Gradient background component for the wallet homepage
/// Displays a beautiful gradient background image that matches the design
struct GradientBackground: View {
    
    // MARK: - Properties
    
    /// The name of the gradient image in Assets.xcassets
    private let imageName: String
    
    /// Whether to ignore safe area
    private let ignoresSafeArea: Bool
    
    // MARK: - Initialization
    
    /// Initialize with custom image name
    /// - Parameters:
    ///   - imageName: Name of the gradient image in Assets.xcassets
    ///   - ignoresSafeArea: Whether to ignore safe area (default: true)
    init(imageName: String = "background", ignoresSafeArea: Bool = true) {
        self.imageName = imageName
        self.ignoresSafeArea = ignoresSafeArea
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea(ignoresSafeArea ? .all : [])
    }
}

/// Alternative gradient background using SwiftUI gradients
/// This can be used as a fallback if the PNG is not available
struct SwiftUIGradientBackground: View {
    
    // MARK: - Properties
    
    /// Whether to ignore safe area
    private let ignoresSafeArea: Bool
    
    // MARK: - Initialization
    
    init(ignoresSafeArea: Bool = true) {
        self.ignoresSafeArea = ignoresSafeArea
    }
    
    // MARK: - Body
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.6),  // Peach/orange top
                Color(red: 0.9, green: 0.6, blue: 0.8),  // Pink middle
                Color(red: 0.7, green: 0.5, blue: 1.0)   // Purple bottom
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(ignoresSafeArea ? .all : [])
    }
}

/// Fixed gradient background container for wallet homepage
/// The gradient stays fixed while content scrolls over it
struct FixedGradientContainer<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let useImageGradient: Bool

    // MARK: - Initialization

    /// Initialize with scrollable content over fixed gradient
    /// - Parameters:
    ///   - useImageGradient: Whether to use PNG image or SwiftUI gradient (default: true)
    ///   - content: The scrollable content to display over the fixed gradient
    init(useImageGradient: Bool = true, @ViewBuilder content: () -> Content) {
        self.useImageGradient = useImageGradient
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // FIXED gradient background - doesn't scroll
            if useImageGradient {
                GradientBackground()
            } else {
                SwiftUIGradientBackground()
            }

            // SCROLLABLE content overlay
            content
        }
    }
}

/// Container view that provides gradient background with content overlay
/// This makes it easy to add the gradient background to any view
struct GradientBackgroundContainer<Content: View>: View {

    // MARK: - Properties

    private let content: Content
    private let useImageGradient: Bool

    // MARK: - Initialization

    /// Initialize with content
    /// - Parameters:
    ///   - useImageGradient: Whether to use PNG image or SwiftUI gradient (default: true)
    ///   - content: The content to display over the gradient
    init(useImageGradient: Bool = true, @ViewBuilder content: () -> Content) {
        self.useImageGradient = useImageGradient
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            if useImageGradient {
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

#Preview("Image Gradient") {
    GradientBackgroundContainer {
        VStack(spacing: 20) {
            Text("Wallet Homepage")
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

#Preview("SwiftUI Gradient") {
    GradientBackgroundContainer(useImageGradient: false) {
        VStack(spacing: 20) {
            Text("Wallet Homepage")
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
