import SwiftUI

/// Reusable loading state component for consistent loading indicators
/// Supports different styles, sizes, and messaging options
struct LoadingStateView: View {
    
    // MARK: - Configuration
    
    let message: String?
    
    // MARK: - Styling Options
    
    var style: LoadingStyle = .standard
    var size: LoadingSize = .regular
    var showBackground: Bool = false
    
    // MARK: - Loading Styles
    
    enum LoadingStyle {
        case standard
        case minimal
        case prominent
        case overlay
        case inline
        
        var backgroundColor: Color? {
            switch self {
            case .standard:
                return DesignSystem.Colors.backgroundPrimary
            case .minimal, .inline:
                return nil
            case .prominent:
                return DesignSystem.Colors.backgroundSecondary
            case .overlay:
                return Color.black.opacity(0.3)
            }
        }
        
        var indicatorColor: Color {
            switch self {
            case .standard, .prominent:
                return DesignSystem.Colors.primary
            case .minimal, .inline:
                return DesignSystem.Colors.textSecondary
            case .overlay:
                return .white
            }
        }
        
        var textColor: Color {
            switch self {
            case .standard, .prominent, .minimal, .inline:
                return DesignSystem.Colors.textSecondary
            case .overlay:
                return .white
            }
        }
        
        var hasBlur: Bool {
            return self == .overlay
        }
    }
    
    // MARK: - Loading Sizes
    
    enum LoadingSize {
        case small
        case regular
        case large
        case huge
        
        var indicatorScale: CGFloat {
            switch self {
            case .small:
                return 0.7
            case .regular:
                return 1.0
            case .large:
                return 1.3
            case .huge:
                return 1.6
            }
        }
        
        var font: Font {
            switch self {
            case .small:
                return DesignSystem.Typography.caption()
            case .regular:
                return DesignSystem.Typography.subheadline()
            case .large:
                return DesignSystem.Typography.headline()
            case .huge:
                return DesignSystem.Typography.title3()
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small:
                return DesignSystem.Spacing.xs
            case .regular:
                return DesignSystem.Spacing.sm
            case .large:
                return DesignSystem.Spacing.md
            case .huge:
                return DesignSystem.Spacing.lg
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(
                    top: DesignSystem.Spacing.sm,
                    leading: DesignSystem.Spacing.md,
                    bottom: DesignSystem.Spacing.sm,
                    trailing: DesignSystem.Spacing.md
                )
            case .regular:
                return EdgeInsets(
                    top: DesignSystem.Spacing.md,
                    leading: DesignSystem.Spacing.lg,
                    bottom: DesignSystem.Spacing.md,
                    trailing: DesignSystem.Spacing.lg
                )
            case .large:
                return EdgeInsets(
                    top: DesignSystem.Spacing.lg,
                    leading: DesignSystem.Spacing.xl,
                    bottom: DesignSystem.Spacing.lg,
                    trailing: DesignSystem.Spacing.xl
                )
            case .huge:
                return EdgeInsets(
                    top: DesignSystem.Spacing.xl,
                    leading: DesignSystem.Spacing.xl,
                    bottom: DesignSystem.Spacing.xl,
                    trailing: DesignSystem.Spacing.xl
                )
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: size.spacing) {
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: style.indicatorColor))
                .scaleEffect(size.indicatorScale)
            
            // Loading message
            if let message = message {
                Text(message)
                    .font(size.font)
                    .foregroundColor(style.textColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(size.padding)
        .background(backgroundView)
        .cornerRadius(style == .overlay ? 0 : DesignSystem.CornerRadius.md)
        .animation(DesignSystem.Animation.standard, value: message)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var backgroundView: some View {
        if let backgroundColor = style.backgroundColor {
            if style.hasBlur {
                backgroundColor
                    .background(.ultraThinMaterial)
            } else {
                backgroundColor
            }
        }
    }
}

// MARK: - Specialized Loading Views

/// Full screen loading overlay
struct LoadingOverlay: View {
    let message: String?
    let isVisible: Bool
    
    init(_ message: String? = nil, isVisible: Bool = true) {
        self.message = message
        self.isVisible = isVisible
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                LoadingStateView(message: message)
                    .style(.overlay)
                    .size(.large)
            }
            .transition(.opacity)
            .animation(DesignSystem.Animation.standard, value: isVisible)
        }
    }
}

/// Inline loading indicator for buttons and small spaces
struct InlineLoader: View {
    let tint: Color
    
    init(tint: Color = DesignSystem.Colors.textSecondary) {
        self.tint = tint
    }
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: tint))
            .scaleEffect(0.8)
    }
}

/// Loading placeholder for content areas
struct LoadingPlaceholder: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = DesignSystem.CornerRadius.sm) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(DesignSystem.Colors.backgroundSecondary)
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                DesignSystem.Colors.backgroundTertiary.opacity(0.5),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            )
            .onAppear {
                shimmerOffset = 200
            }
    }
    
    @State private var shimmerOffset: CGFloat = -200
}

/// Skeleton loading view for complex layouts
struct SkeletonView: View {
    let lines: Int
    let spacing: CGFloat
    
    init(lines: Int = 3, spacing: CGFloat = DesignSystem.Spacing.sm) {
        self.lines = lines
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                LoadingPlaceholder(
                    height: index == 0 ? 24 : 16,
                    cornerRadius: DesignSystem.CornerRadius.sm
                )
                .frame(maxWidth: index == lines - 1 ? .infinity * 0.7 : .infinity)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension LoadingStateView {
    
    /// Standard loading view
    static func standard(_ message: String? = nil) -> LoadingStateView {
        LoadingStateView(message: message)
            .style(.standard)
            .size(.regular)
    }
    
    /// Minimal loading indicator
    static func minimal(_ message: String? = nil) -> LoadingStateView {
        LoadingStateView(message: message)
            .style(.minimal)
            .size(.small)
    }
    
    /// Prominent loading view for important operations
    static func prominent(_ message: String) -> LoadingStateView {
        LoadingStateView(message: message)
            .style(.prominent)
            .size(.large)
    }
    
    /// Inline loading for buttons and compact spaces
    static func inline(_ message: String? = nil) -> LoadingStateView {
        LoadingStateView(message: message)
            .style(.inline)
            .size(.small)
    }
}

// MARK: - Modifier Extensions

extension LoadingStateView {
    
    /// Set loading style
    func style(_ style: LoadingStyle) -> LoadingStateView {
        var view = self
        view.style = style
        return view
    }
    
    /// Set loading size
    func size(_ size: LoadingSize) -> LoadingStateView {
        var view = self
        view.size = size
        return view
    }
    
    /// Show background
    func withBackground(_ show: Bool = true) -> LoadingStateView {
        var view = self
        view.showBackground = show
        return view
    }
}

// MARK: - View Extensions

extension View {
    
    /// Add loading overlay to any view
    func loadingOverlay(_ message: String? = nil, isVisible: Bool) -> some View {
        self.overlay(
            LoadingOverlay(message, isVisible: isVisible)
        )
    }
    
    /// Replace content with loading state
    func loading(_ isLoading: Bool, message: String? = nil) -> some View {
        Group {
            if isLoading {
                LoadingStateView.standard(message)
            } else {
                self
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Different styles
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Loading Styles")
                    .font(DesignSystem.Typography.headline())
                
                LoadingStateView.standard("Loading wallet...")
                LoadingStateView.minimal("Syncing...")
                LoadingStateView.prominent("Connecting to Lightning Network")
                LoadingStateView.inline("Processing")
            }
            
            // Different sizes
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Loading Sizes")
                    .font(DesignSystem.Typography.headline())
                
                LoadingStateView(message: "Small").size(.small)
                LoadingStateView(message: "Regular").size(.regular)
                LoadingStateView(message: "Large").size(.large)
                LoadingStateView(message: "Huge").size(.huge)
            }
            
            // Specialized components
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Specialized Components")
                    .font(DesignSystem.Typography.headline())
                
                InlineLoader()
                LoadingPlaceholder(height: 40)
                SkeletonView(lines: 3)
            }
        }
        .padding()
    }
}
