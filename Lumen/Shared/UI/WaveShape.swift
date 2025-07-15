import SwiftUI

/// Wave shape for the transition from gradient to white background
/// Creates a smooth wave transition with customizable properties
struct WaveShape: Shape {
    
    // MARK: - Properties
    
    /// The amplitude (height) of the wave
    var amplitude: CGFloat
    
    /// The frequency (number of waves) across the width
    var frequency: CGFloat
    
    /// Phase offset for animation
    var phase: CGFloat
    
    // MARK: - Initialization
    
    /// Initialize wave shape with default values
    /// - Parameters:
    ///   - amplitude: Wave height (default: 15)
    ///   - frequency: Number of waves across width (default: 2.0)
    ///   - phase: Phase offset for animation (default: 0)
    init(amplitude: CGFloat = 15, frequency: CGFloat = 2.0, phase: CGFloat = 0) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase
    }
    
    // MARK: - Shape Protocol
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Create wave across the width - positioned more towards bottom for better design
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * 2 * .pi) + phase)
            // Position wave closer to bottom with smoother curve
            let y = height * 0.7 + (sine * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Complete the shape by going to bottom corners
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

/// Wave transition view with white drop shadow
/// This creates the transition from gradient background to white content area
struct WaveTransition: View {

    // MARK: - Properties

    /// Wave animation state
    @State private var wavePhase: CGFloat = 0

    /// Whether to animate the wave
    private let animated: Bool

    /// Wave height
    private let waveHeight: CGFloat

    /// Wave amplitude
    private let amplitude: CGFloat

    /// Wave frequency
    private let frequency: CGFloat

    /// Wave position (0.0 = top, 1.0 = bottom)
    private let position: CGFloat

    // MARK: - Initialization

    /// Initialize wave transition
    /// - Parameters:
    ///   - animated: Whether to animate the wave (default: false)
    ///   - waveHeight: Height of the wave area (default: 60)
    ///   - amplitude: Wave amplitude (default: 15)
    ///   - frequency: Wave frequency (default: 2.0)
    ///   - position: Wave position (default: 0.7)
    init(
        animated: Bool = false,
        waveHeight: CGFloat = 60,
        amplitude: CGFloat = 15,
        frequency: CGFloat = 2.0,
        position: CGFloat = 0.7
    ) {
        self.animated = animated
        self.waveHeight = waveHeight
        self.amplitude = amplitude
        self.frequency = frequency
        self.position = position
    }

    // MARK: - Body

    var body: some View {
        // Wave shape that creates the transition and fills everything below
        CustomWaveShape(
            amplitude: amplitude,
            frequency: frequency,
            phase: wavePhase,
            position: position
        )
        .fill(Color.white)
        .frame(minHeight: waveHeight)
        .shadow(
            color: Color.black.opacity(0.1), // Dark shadow for better visibility
            radius: 8,
            x: 0,
            y: 2
        )
        .onAppear {
            if animated {
                startWaveAnimation()
            }
        }
    }
    
    // MARK: - Animation
    
    private func startWaveAnimation() {
        withAnimation(
            Animation.linear(duration: 3)
                .repeatForever(autoreverses: false)
        ) {
            wavePhase = 2 * .pi
        }
    }
}

// MARK: - Preview

#Preview("Static Wave") {
    VStack(spacing: 0) {
        // Gradient area
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.6),
                Color(red: 0.9, green: 0.6, blue: 0.8),
                Color(red: 0.7, green: 0.5, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 300)

        // Wave transition with content
        WaveTransition()
            .frame(height: 500)
            .overlay(
                VStack {
                    Text("White Content Area")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.top, 80)

                    Text("Transaction history goes here")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            )
    }
    .ignoresSafeArea()
}

#Preview("Animated Wave") {
    VStack(spacing: 0) {
        // Gradient area
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.8, blue: 0.6),
                Color(red: 0.9, green: 0.6, blue: 0.8),
                Color(red: 0.7, green: 0.5, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 300)

        // Animated wave transition with content
        WaveTransition(animated: true)
            .frame(height: 500)
            .overlay(
                VStack {
                    Text("White Content Area")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.top, 80)

                    Text("Transaction history goes here")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            )
            .overlay(
                VStack {
                    Text("White Content Area")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text("Animated wave transition")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            )
    }
    .ignoresSafeArea()
}

#Preview("Wave with Cards") {
    ZStack {
        VStack(spacing: 0) {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.8, blue: 0.6),
                    Color(red: 0.9, green: 0.6, blue: 0.8),
                    Color(red: 0.7, green: 0.5, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 400)
            
            // Wave transition
            WaveTransition()
            
            // White area
            Color.white
                .frame(height: 400)
        }
        .ignoresSafeArea()
        
        // Sample cards over the background
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .frame(height: 120)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.8))
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.8))
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 100)
    }
}

// MARK: - Custom Wave Shape

/// Custom wave shape that creates just the top curve with white fill below
private struct CustomWaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var position: CGFloat // 0.0 = top, 1.0 = bottom

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Create smooth wave curve across the width (convex/mountain shape)
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * 2 * .pi) + phase)
            let y = (sine * amplitude) + amplitude // Wave starts from top, curves down
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Draw straight line to bottom-right corner
        path.addLine(to: CGPoint(x: width, y: height))

        // Draw straight line to bottom-left corner
        path.addLine(to: CGPoint(x: 0, y: height))

        // Close the path
        path.closeSubpath()

        return path
    }
}
