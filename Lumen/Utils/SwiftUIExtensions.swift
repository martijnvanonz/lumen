import SwiftUI

// MARK: - Color Extensions

extension Color {
    /// App-specific color palette
    struct App {
        static let primary = AppTheme.Colors.primary
        static let secondary = AppTheme.Colors.secondary
        static let accent = AppTheme.Colors.accent
        static let success = AppTheme.Colors.success
        static let warning = AppTheme.Colors.warning
        static let error = AppTheme.Colors.error
        static let info = AppTheme.Colors.info
        static let lightning = AppTheme.Colors.lightning
        static let incoming = AppTheme.Colors.incoming
        static let outgoing = AppTheme.Colors.outgoing
        static let cardBackground = AppTheme.Colors.cardBackground
        static let secondaryBackground = AppTheme.Colors.secondaryBackground
        static let overlayBackground = AppTheme.Colors.overlayBackground
        static let border = AppTheme.Colors.border
        static let focusedBorder = AppTheme.Colors.focusedBorder
    }
    
    /// Create color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font Extensions

extension Font {
    /// App-specific typography
    struct App {
        static let largeTitle = AppTheme.Typography.largeTitle
        static let title = AppTheme.Typography.title
        static let title2 = AppTheme.Typography.title2
        static let title3 = AppTheme.Typography.title3
        static let headline = AppTheme.Typography.headline
        static let subheadline = AppTheme.Typography.subheadline
        static let body = AppTheme.Typography.body
        static let callout = AppTheme.Typography.callout
        static let caption = AppTheme.Typography.caption
        static let caption2 = AppTheme.Typography.caption2
        static let monospaced = AppTheme.Typography.monospaced
        static let balance = AppTheme.Typography.balanceFont
    }
}

// MARK: - Animation Extensions

extension Animation {
    /// App-specific animations
    struct App {
        static let spring = AppTheme.Animations.spring
        static let easeInOut = AppTheme.Animations.easeInOut
        static let quick = AppTheme.Animations.quick
        
        /// Bounce animation for success states
        static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 10)
        
        /// Smooth slide animation for sheets
        static let slide = Animation.easeInOut(duration: 0.4)
        
        /// Quick fade animation
        static let fade = Animation.easeInOut(duration: 0.2)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply conditional modifier with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Hide view conditionally
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Apply corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    /// Add haptic feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Add success haptic feedback
    func successHaptic() -> some View {
        self.onAppear {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }
    
    /// Add error haptic feedback
    func errorHaptic() -> some View {
        self.onAppear {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    /// Add warning haptic feedback
    func warningHaptic() -> some View {
        self.onAppear {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
    
    /// Shake animation for errors
    func shake(_ isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(shakes: isShaking ? 3 : 0))
    }
    
    /// Pulse animation
    func pulse(_ isPulsing: Bool) -> some View {
        self.scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                isPulsing ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
    }
    
    /// Glow effect
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        self.shadow(color: color, radius: radius)
    }
    
    /// Shimmer effect for loading states
    func shimmer(_ isActive: Bool = true) -> some View {
        self.modifier(ShimmerEffect(isActive: isActive))
    }
}

// MARK: - Custom Shapes

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

// MARK: - Custom Effects

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    init(shakes: Int) {
        animatableData = CGFloat(shakes)
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
                y: 0
            )
        )
    }
}

struct ShimmerEffect: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                if isActive {
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 300
                    }
                }
            }
    }
}

// MARK: - Binding Extensions

extension Binding {
    /// Create a binding that ignores changes
    func ignoreChanges() -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { _ in }
        )
    }
    
    /// Map a binding to a different type
    func map<T>(
        get: @escaping (Value) -> T,
        set: @escaping (T) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { get(self.wrappedValue) },
            set: { self.wrappedValue = set($0) }
        )
    }
}

// MARK: - String Extensions

extension String {
    /// Truncate string to specified length
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    /// Format as Bitcoin address (show first and last few characters)
    func formatAsBitcoinAddress() -> String {
        guard self.count > 10 else { return self }
        let start = String(self.prefix(6))
        let end = String(self.suffix(4))
        return "\(start)...\(end)"
    }
    
    /// Format as Lightning invoice (show first few characters)
    func formatAsLightningInvoice() -> String {
        guard self.count > 20 else { return self }
        return String(self.prefix(20)) + "..."
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format as relative time (e.g., "2 minutes ago")
    func relativeFormatted() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Format as short date and time
    func shortFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
