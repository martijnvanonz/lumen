import SwiftUI

/// Wavy pastel background component that provides a soft, organic background
/// Uses the design system colors and follows established component patterns
struct WavyBackgroundView: View {
    
    // MARK: - Configuration
    
    /// Wave animation state
    @State private var wavePhase: CGFloat = 0
    
    /// Whether to animate the wave
    var isAnimated: Bool = false
    
    /// Wave style to use
    var waveStyle: WaveShape = .standard
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Pastel gradient background
            DesignSystem.Gradients.pastelBackground
                .ignoresSafeArea()
            
            // White wave overlay
            waveStyle
                .fill(Color.white)
                .frame(height: 220)
                .offset(y: 120)
                .shadow(
                    color: DesignSystem.Shadow.light.color,
                    radius: DesignSystem.Shadow.light.radius,
                    x: DesignSystem.Shadow.light.x,
                    y: DesignSystem.Shadow.light.y - 1
                )
                .animation(
                    isAnimated ? 
                        Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true) : 
                        nil,
                    value: wavePhase
                )
        }
        .onAppear {
            if isAnimated {
                wavePhase = .pi * 2
            }
        }
    }
}

// MARK: - Convenience Initializers

extension WavyBackgroundView {
    
    /// Static wavy background
    static var `static`: WavyBackgroundView {
        WavyBackgroundView(isAnimated: false, waveStyle: .standard)
    }
    
    /// Gently animated wavy background
    static var gentle: WavyBackgroundView {
        WavyBackgroundView(isAnimated: true, waveStyle: .gentle)
    }
    
    /// Dynamically animated wavy background
    static var dynamic: WavyBackgroundView {
        WavyBackgroundView(isAnimated: true, waveStyle: .dynamic)
    }
}

// MARK: - Preview

#Preview {
    WavyBackgroundView.static
}
