import SwiftUI

/// Interactive bottom sheet with wave transition that can be pulled up to reveal transaction history
/// Features drag gesture, smooth animations, and haptic feedback
struct InteractiveWaveBottomSheet: View {
    
    // MARK: - State Management
    
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    
    // MARK: - Configuration
    
    private let collapsedHeight: CGFloat = 80  // How much wave sticks out when collapsed
    private let expandedHeight: CGFloat = 500  // Full height when expanded
    private let waveHeight: CGFloat = 200
    private let dragThreshold: CGFloat = 50    // Minimum drag distance to trigger state change
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let currentHeight = isExpanded ? expandedHeight : collapsedHeight
            let totalOffset = screenHeight - currentHeight + dragOffset
            
            VStack(spacing: 0) {
                // Interactive Wave Header
                waveHeader
                    .frame(height: waveHeight)
                    .gesture(dragGesture)

                // Transaction History Content (always present, moves with sheet)
                transactionHistoryContent

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear) // Remove white background
            .clipped() // Clip content to bounds
            .offset(y: totalOffset)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: dragOffset)
        }
        .onAppear {
            startWaveAnimation()
        }
    }
    
    // MARK: - Wave Header
    
    private var waveHeader: some View {
        ZStack {
            // Wave shape with white fill for the content area
            InteractiveWaveShape(
                amplitude: 30,
                frequency: 0.4,
                phase: wavePhase,
                position: 0.3
            )
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)

            // Content positioned within the wave
            VStack(spacing: 8) {
                Spacer()

                // Pull indicator line
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 100)

                // Status text
                Text(isExpanded ? "Swipe down to close" : "Swipe up for transaction history")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    // .padding(.top)

                Spacer()
                Spacer()
                Spacer()
            }
        }
    }
    
    // MARK: - Transaction History Content
    
    private var transactionHistoryContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Transaction history with negative top padding to close gap with wave
                EnhancedTransactionHistoryView()
                    .padding(.horizontal)
                    .padding(.top) // Negative padding to close 1px gap with wave
                    .padding(.bottom, 100) // Extra bottom padding for scrolling
            }
        }
        .background(Color.white)
    }
    
    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.height

                if isExpanded {
                    // When expanded, only allow downward drag
                    dragOffset = max(0, translation)
                } else {
                    // When collapsed, only allow upward drag
                    dragOffset = min(0, translation)
                }
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.velocity.height
                
                // Determine if we should change state based on drag distance and velocity
                let shouldToggle = abs(translation) > dragThreshold || abs(velocity) > 500
                
                if shouldToggle {
                    if isExpanded && translation > 0 {
                        // Collapse
                        collapseSheet()
                    } else if !isExpanded && translation < 0 {
                        // Expand
                        expandSheet()
                    }
                }
                
                // Reset drag offset
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    dragOffset = 0
                }
            }
    }
    
    // MARK: - Actions
    
    private func expandSheet() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
        }
    }
    
    private func collapseSheet() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    // MARK: - Wave Animation
    
    private func startWaveAnimation() {
        withAnimation(
            Animation.linear(duration: 4)
                .repeatForever(autoreverses: false)
        ) {
            wavePhase = 2 * .pi
        }
    }
}

// MARK: - Interactive Wave Shape for Bottom Sheet

struct InteractiveWaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    var position: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Create wave across the width
        for x in stride(from: 0, through: width, by: 2) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * 2 * .pi) + phase)
            let y = height * position + (sine * amplitude)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the shape by going to bottom corners
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // Animated gradient background
        UniversalAnimatedGradientBackground()

        // Interactive wave bottom sheet
        InteractiveWaveBottomSheet()
    }
}
