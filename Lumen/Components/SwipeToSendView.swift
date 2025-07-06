import SwiftUI

struct SwipeToSendView: View {
    let totalAmount: UInt64
    let onSend: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted = false
    @State private var buttonWidth: CGFloat = 60
    
    private let trackHeight: CGFloat = 60
    private let cornerRadius: CGFloat = 30
    
    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let maxDragDistance = trackWidth - buttonWidth
            let dragProgress = min(max(dragOffset / maxDragDistance, 0), 1)
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.orange.opacity(0.2))
                    .frame(height: trackHeight)
                
                // Progress fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: dragOffset + buttonWidth, height: trackHeight)
                    .animation(.easeOut(duration: 0.2), value: dragOffset)
                
                // Text overlay
                HStack {
                    Spacer()
                    
                    if !isCompleted {
                        HStack(spacing: 8) {
                            Text("Swipe to Send")
                                .foregroundStyle(.orange)
                                .opacity(1.0 - Double(dragProgress) * 1.5) // Fade out as we swipe

                            SatsAmountView(
                                amount: totalAmount,
                                displayMode: .satsOnly,
                                size: .compact,
                                style: .primary
                            )
                            .opacity(1.0 - Double(dragProgress) * 1.5)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                            Text("Sending...")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                }
                .frame(height: trackHeight)
                
                // Draggable button
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.orange)
                    .frame(width: buttonWidth, height: trackHeight)
                    .overlay(
                        Image(systemName: isCompleted ? "checkmark" : "arrow.right")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    )
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isCompleted {
                                    let newOffset = max(0, min(value.translation.width, maxDragDistance))
                                    dragOffset = newOffset
                                }
                            }
                            .onEnded { value in
                                if !isCompleted {
                                    if dragOffset > maxDragDistance * 0.8 {
                                        // Complete the swipe
                                        completeSwipe(maxDragDistance: maxDragDistance)
                                    } else {
                                        // Snap back
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                            }
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dragOffset)
            }
        }
        .frame(height: trackHeight)
    }
    
    private func completeSwipe(maxDragDistance: CGFloat) {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Complete animation
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = maxDragDistance
            isCompleted = true
        }
        
        // Trigger send action after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSend()
        }
    }
    
    // Reset function for external use
    func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            dragOffset = 0
            isCompleted = false
        }
    }
}

// Preview
struct SwipeToSendView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SwipeToSendView(totalAmount: 10063) {
                // Payment sent
            }
            .padding()

            SwipeToSendView(totalAmount: 50000) {
                // Large payment sent
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}
