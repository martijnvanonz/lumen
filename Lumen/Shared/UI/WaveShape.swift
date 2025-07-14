import SwiftUI

/// Custom SwiftUI Shape that creates smooth wave curves for background elements
/// Follows the design system patterns and provides configurable wave parameters
struct WaveShape: Shape {
    
    // MARK: - Configuration
    
    /// Wave amplitude (height of the wave peaks)
    var amplitude: CGFloat = 0.3
    
    /// Wave frequency (number of waves across the width)
    var frequency: CGFloat = 1.5
    
    /// Phase offset for wave animation
    var phase: CGFloat = 0
    
    /// Animatable data for smooth transitions
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    // MARK: - Shape Implementation
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // Create organic wave with gentle hills instead of mathematical sine waves
        // Start from left edge, about 30% down from top
        path.move(to: CGPoint(x: 0, y: height * 0.3))

        // Create 2-3 organic hills with asymmetrical, natural curves
        // First gentle rise
        path.addCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.15),
            control1: CGPoint(x: width * 0.12, y: height * 0.25),
            control2: CGPoint(x: width * 0.25, y: height * 0.08)
        )

        // Gentle dip
        path.addCurve(
            to: CGPoint(x: width * 0.65, y: height * 0.28),
            control1: CGPoint(x: width * 0.45, y: height * 0.22),
            control2: CGPoint(x: width * 0.55, y: height * 0.35)
        )

        // Final gentle rise to right edge
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.18),
            control1: CGPoint(x: width * 0.75, y: height * 0.22),
            control2: CGPoint(x: width * 0.88, y: height * 0.12)
        )

        // Complete the shape by drawing to bottom corners
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Wave Shape Presets

extension WaveShape {
    
    /// Gentle wave for subtle backgrounds
    static var gentle: WaveShape {
        WaveShape(amplitude: 0.2, frequency: 1.0)
    }
    
    /// Standard wave for main backgrounds
    static var standard: WaveShape {
        WaveShape(amplitude: 0.3, frequency: 1.5)
    }
    
    /// Dynamic wave for animated backgrounds
    static var dynamic: WaveShape {
        WaveShape(amplitude: 0.4, frequency: 2.0)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Gentle wave
        ZStack {
            Rectangle()
                .fill(DesignSystem.Colors.pastelPink.opacity(0.3))
            
            WaveShape.gentle
                .fill(Color.white.opacity(0.8))
                .frame(height: 150)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        
        // Standard wave
        ZStack {
            Rectangle()
                .fill(DesignSystem.Colors.pastelPeach.opacity(0.3))
            
            WaveShape.standard
                .fill(Color.white.opacity(0.8))
                .frame(height: 150)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        
        // Dynamic wave
        ZStack {
            Rectangle()
                .fill(DesignSystem.Colors.pastelLavender.opacity(0.3))
            
            WaveShape.dynamic
                .fill(Color.white.opacity(0.8))
                .frame(height: 150)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
    .padding()
}
