import SwiftUI

// MARK: - Animation System

struct AnimationSystem {
    
    // MARK: - Basic Animations
    
    /// Standard spring animation for UI interactions
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Quick animation for immediate feedback
    static let quick = Animation.easeInOut(duration: 0.2)
    
    /// Smooth animation for transitions
    static let smooth = Animation.easeInOut(duration: 0.3)
    
    /// Slow animation for emphasis
    static let slow = Animation.easeInOut(duration: 0.6)
    
    // MARK: - Specialized Animations
    
    /// Success animation with bounce
    static let success = Animation.interpolatingSpring(stiffness: 300, damping: 10)
    
    /// Error animation with shake
    static let error = Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)
    
    /// Loading animation with continuous rotation
    static let loading = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
    
    /// Pulse animation for attention
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    
    /// Slide animation for sheets and modals
    static let slide = Animation.easeInOut(duration: 0.4)
    
    /// Fade animation for opacity changes
    static let fade = Animation.easeInOut(duration: 0.25)
    
    /// Bounce animation for buttons
    static let bounce = Animation.interpolatingSpring(stiffness: 400, damping: 15)
    
    // MARK: - Payment Animations
    
    /// Animation for successful payment
    static let paymentSuccess = Animation.interpolatingSpring(stiffness: 200, damping: 8)
    
    /// Animation for payment failure
    static let paymentFailure = Animation.easeInOut(duration: 0.15).repeatCount(2, autoreverses: true)
    
    /// Animation for payment processing
    static let paymentProcessing = Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
    
    // MARK: - Network Animations
    
    /// Animation for connection status changes
    static let connectionChange = Animation.easeInOut(duration: 0.5)
    
    /// Animation for network quality indicators
    static let networkQuality = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Notification Animations
    
    /// Animation for notification appearance
    static let notificationIn = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Animation for notification dismissal
    static let notificationOut = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Custom Animation Functions
    
    /// Create a delayed animation
    static func delayed(_ delay: TimeInterval, animation: Animation = .spring()) -> Animation {
        animation.delay(delay)
    }
    
    /// Create a repeating animation
    static func repeating(
        _ animation: Animation = .easeInOut(duration: 1.0),
        count: Int? = nil,
        autoreverses: Bool = true
    ) -> Animation {
        if let count = count {
            return animation.repeatCount(count, autoreverses: autoreverses)
        } else {
            return animation.repeatForever(autoreverses: autoreverses)
        }
    }
    
    /// Create a spring animation with custom parameters
    static func customSpring(
        response: Double = 0.5,
        dampingFraction: Double = 0.8,
        blendDuration: Double = 0
    ) -> Animation {
        Animation.spring(
            response: response,
            dampingFraction: dampingFraction,
            blendDuration: blendDuration
        )
    }
    
    /// Create an easing animation with custom duration
    static func easing(duration: TimeInterval = 0.3) -> Animation {
        Animation.easeInOut(duration: duration)
    }
}

// MARK: - Animation Modifiers

struct AnimatedModifier: ViewModifier {
    let animation: Animation
    let trigger: AnyHashable
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: trigger)
    }
}

struct ScaleEffectModifier: ViewModifier {
    let scale: CGFloat
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(animation, value: scale)
    }
}

struct RotationEffectModifier: ViewModifier {
    let angle: Angle
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(angle)
            .animation(animation, value: angle)
    }
}

struct OpacityEffectModifier: ViewModifier {
    let opacity: Double
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(animation, value: opacity)
    }
}

struct OffsetEffectModifier: ViewModifier {
    let offset: CGSize
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .animation(animation, value: offset)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply animation with trigger
    func animated(_ animation: Animation = AnimationSystem.spring, trigger: AnyHashable) -> some View {
        modifier(AnimatedModifier(animation: animation, trigger: trigger))
    }
    
    /// Apply scale effect with animation
    func animatedScale(_ scale: CGFloat, animation: Animation = AnimationSystem.bounce) -> some View {
        modifier(ScaleEffectModifier(scale: scale, animation: animation))
    }
    
    /// Apply rotation effect with animation
    func animatedRotation(_ angle: Angle, animation: Animation = AnimationSystem.smooth) -> some View {
        modifier(RotationEffectModifier(angle: angle, animation: animation))
    }
    
    /// Apply opacity effect with animation
    func animatedOpacity(_ opacity: Double, animation: Animation = AnimationSystem.fade) -> some View {
        modifier(OpacityEffectModifier(opacity: opacity, animation: animation))
    }
    
    /// Apply offset effect with animation
    func animatedOffset(_ offset: CGSize, animation: Animation = AnimationSystem.slide) -> some View {
        modifier(OffsetEffectModifier(offset: offset, animation: animation))
    }
    
    /// Success animation
    func successAnimation() -> some View {
        self.scaleEffect(1.1)
            .animation(AnimationSystem.success, value: true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Reset scale after animation
                }
            }
    }
    
    /// Error shake animation
    func errorShake(_ isShaking: Bool) -> some View {
        self.offset(x: isShaking ? 5 : 0)
            .animation(AnimationSystem.error, value: isShaking)
    }
    
    /// Loading pulse animation
    func loadingPulse(_ isLoading: Bool) -> some View {
        self.opacity(isLoading ? 0.6 : 1.0)
            .animation(AnimationSystem.pulse, value: isLoading)
    }
    
    /// Payment success animation
    func paymentSuccess(_ isSuccess: Bool) -> some View {
        self.scaleEffect(isSuccess ? 1.2 : 1.0)
            .animation(AnimationSystem.paymentSuccess, value: isSuccess)
    }
    
    /// Notification slide in animation
    func notificationSlideIn(_ isVisible: Bool) -> some View {
        self.offset(y: isVisible ? 0 : -100)
            .opacity(isVisible ? 1 : 0)
            .animation(AnimationSystem.notificationIn, value: isVisible)
    }
    
    /// Connection status animation
    func connectionStatusChange(_ status: String) -> some View {
        self.animation(AnimationSystem.connectionChange, value: status)
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Slide and fade transition
    static let slideAndFade = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )
    
    /// Scale and fade transition
    static let scaleAndFade = AnyTransition.scale.combined(with: .opacity)
    
    /// Notification transition
    static let notification = AnyTransition.asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity)
    )
    
    /// Payment transition
    static let payment = AnyTransition.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .opacity
    )
    
    /// Modal transition
    static let modal = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )
}

// MARK: - Animation Timing

struct AnimationTiming {
    static let instant: TimeInterval = 0.0
    static let veryFast: TimeInterval = 0.1
    static let fast: TimeInterval = 0.2
    static let normal: TimeInterval = 0.3
    static let slow: TimeInterval = 0.5
    static let verySlow: TimeInterval = 0.8
    static let loading: TimeInterval = 1.0
    static let longLoading: TimeInterval = 2.0
}

// MARK: - Animation Curves

struct AnimationCurves {
    static let linear = Animation.linear
    static let easeIn = Animation.easeIn
    static let easeOut = Animation.easeOut
    static let easeInOut = Animation.easeInOut
    static let spring = Animation.spring()
    static let interactiveSpring = Animation.interactiveSpring()
}

// MARK: - Haptic Feedback Integration

extension View {
    /// Add haptic feedback with animation
    func hapticAnimation(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Success haptic with animation
    func successHapticAnimation() -> some View {
        self.onAppear {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        .successAnimation()
    }
    
    /// Error haptic with animation
    func errorHapticAnimation(_ isError: Bool) -> some View {
        self.onChange(of: isError) { _, newValue in
            if newValue {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
        .errorShake(isError)
    }
}
