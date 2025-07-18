import SwiftUI

/// Animated gradient background with noise overlay
/// Replaces the static Image("background") with a living, breathing animated background
/// Requires iOS 17+ for colorEffect and ShaderLibrary support
@available(iOS 17.0, *)
struct AnimatedGradientBackground: View {
    
    // MARK: - Properties
    
    /// Whether to ignore safe area
    private let ignoresSafeArea: Bool
    
    /// Animation speed multiplier (default: 1.0)
    private let animationSpeed: Double
    
    /// Noise opacity (default: 0.08)
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
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                let t = sin(time * 0.1 * animationSpeed)
                
                ZStack {
                    // 1. Animated gradient (replaces Image("background"))
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.6),  // Peach/orange top
                            Color(red: 0.9, green: 0.6, blue: 0.8),  // Pink middle
                            Color(red: 0.7, green: 0.5, blue: 1.0)   // Purple bottom
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.5 + t * 0.05),
                        endPoint: UnitPoint(x: 0.5, y: 1.0 - t * 0.05)
                    )
                    
                    // 2. Animated noise overlay
                    Rectangle()
                        .fill(.white)
                        .colorEffect(
                            ShaderLibrary.noiseShader(
                                .float2(Float(geometry.size.width), Float(geometry.size.height)),
                                .float(Float(time * animationSpeed))
                            )
                        )
                        .blendMode(.overlay)
                        .opacity(noiseOpacity)
                }
            }
        }
        .ignoresSafeArea(ignoresSafeArea ? .all : [])
    }
}

/// Fallback animated gradient for iOS versions < 17
/// Uses only the animated gradient without Metal shader noise
struct AnimatedGradientBackgroundFallback: View {
    
    // MARK: - Properties
    
    private let ignoresSafeArea: Bool
    private let animationSpeed: Double
    
    // MARK: - Initialization
    
    init(
        ignoresSafeArea: Bool = true,
        animationSpeed: Double = 1.0
    ) {
        self.ignoresSafeArea = ignoresSafeArea
        self.animationSpeed = animationSpeed
    }
    
    // MARK: - Body
    
    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let t = sin(time * 0.1 * animationSpeed)
            
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.6),  // Peach/orange top
                    Color(red: 0.9, green: 0.6, blue: 0.8),  // Pink middle
                    Color(red: 0.7, green: 0.5, blue: 1.0)   // Purple bottom
                ],
                startPoint: UnitPoint(x: 0.5, y: 0.5 + t * 0.05),
                endPoint: UnitPoint(x: 0.5, y: 1.0 - t * 0.05)
            )
        }
        .ignoresSafeArea(ignoresSafeArea ? .all : [])
    }
}

/// Universal animated gradient background that works on all iOS versions
/// Automatically uses the appropriate implementation based on iOS version
struct UniversalAnimatedGradientBackground: View {
    
    // MARK: - Properties
    
    private let ignoresSafeArea: Bool
    private let animationSpeed: Double
    private let noiseOpacity: Double
    
    // MARK: - Initialization
    
    init(
        ignoresSafeArea: Bool = true,
        animationSpeed: Double = 1.0,
        noiseOpacity: Double = 0.08
    ) {
        self.ignoresSafeArea = ignoresSafeArea
        self.animationSpeed = animationSpeed
        self.noiseOpacity = noiseOpacity
    }
    
    // MARK: - Body
    
    var body: some View {
        if #available(iOS 17.0, *) {
            AnimatedGradientBackground(
                ignoresSafeArea: ignoresSafeArea,
                animationSpeed: animationSpeed,
                noiseOpacity: noiseOpacity
            )
        } else {
            AnimatedGradientBackgroundFallback(
                ignoresSafeArea: ignoresSafeArea,
                animationSpeed: animationSpeed
            )
        }
    }
}

// MARK: - Preview

#Preview("iOS 17+ with Noise") {
    if #available(iOS 17.0, *) {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 20) {
                Text("Animated Gradient + Noise")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .frame(height: 120)
                    .padding(.horizontal)
                    .shadow(radius: 10)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    } else {
        Text("iOS 17+ Required")
    }
}

#Preview("Fallback Version") {
    ZStack {
        AnimatedGradientBackgroundFallback()
        
        VStack(spacing: 20) {
            Text("Animated Gradient Only")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .frame(height: 120)
                .padding(.horizontal)
                .shadow(radius: 10)
            
            Spacer()
        }
        .padding(.top, 50)
    }
}

#Preview("Universal Version") {
    ZStack {
        UniversalAnimatedGradientBackground()
        
        VStack(spacing: 20) {
            Text("Universal Animated Background")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .frame(height: 120)
                .padding(.horizontal)
                .shadow(radius: 10)
            
            Spacer()
        }
        .padding(.top, 50)
    }
}
