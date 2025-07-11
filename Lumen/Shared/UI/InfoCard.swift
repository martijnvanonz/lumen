import SwiftUI

/// Reusable information card component for displaying content consistently
/// Supports different styles, layouts, and interactive states
struct InfoCard: View {
    
    // MARK: - Configuration
    
    let title: String?
    let subtitle: String?
    let content: String?
    let icon: String?
    
    // MARK: - Styling Options
    
    var style: CardStyle = .standard
    var layout: CardLayout = .vertical
    var size: CardSize = .regular
    var isInteractive: Bool = false
    var onTap: (() -> Void)? = nil
    
    // MARK: - Card Styles
    
    enum CardStyle {
        case standard
        case prominent
        case minimal
        case success
        case warning
        case error
        case info
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .standard:
                return DesignSystem.Colors.backgroundPrimary
            case .prominent:
                return DesignSystem.Colors.backgroundSecondary
            case .minimal:
                return Color.clear
            case .success:
                return DesignSystem.Colors.success.opacity(0.1)
            case .warning:
                return DesignSystem.Colors.warning.opacity(0.1)
            case .error:
                return DesignSystem.Colors.error.opacity(0.1)
            case .info:
                return DesignSystem.Colors.info.opacity(0.1)
            case .outline:
                return Color.clear
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .standard:
                return DesignSystem.Colors.borderPrimary
            case .prominent:
                return DesignSystem.Colors.borderSecondary
            case .minimal:
                return nil
            case .success:
                return DesignSystem.Colors.success.opacity(0.3)
            case .warning:
                return DesignSystem.Colors.warning.opacity(0.3)
            case .error:
                return DesignSystem.Colors.error.opacity(0.3)
            case .info:
                return DesignSystem.Colors.info.opacity(0.3)
            case .outline:
                return DesignSystem.Colors.borderPrimary
            }
        }
        
        var iconColor: Color {
            switch self {
            case .standard, .prominent, .minimal, .outline:
                return DesignSystem.Colors.textSecondary
            case .success:
                return DesignSystem.Colors.success
            case .warning:
                return DesignSystem.Colors.warning
            case .error:
                return DesignSystem.Colors.error
            case .info:
                return DesignSystem.Colors.info
            }
        }
        
        var titleColor: Color {
            switch self {
            case .standard, .prominent, .minimal, .outline:
                return DesignSystem.Colors.textPrimary
            case .success:
                return DesignSystem.Colors.success
            case .warning:
                return DesignSystem.Colors.warning
            case .error:
                return DesignSystem.Colors.error
            case .info:
                return DesignSystem.Colors.info
            }
        }
    }
    
    // MARK: - Card Layouts
    
    enum CardLayout {
        case vertical
        case horizontal
        case iconOnly
        case textOnly
        
        var hasIcon: Bool {
            switch self {
            case .vertical, .horizontal, .iconOnly:
                return true
            case .textOnly:
                return false
            }
        }
        
        var hasText: Bool {
            switch self {
            case .vertical, .horizontal, .textOnly:
                return true
            case .iconOnly:
                return false
            }
        }
        
        var isHorizontal: Bool {
            return self == .horizontal
        }
    }
    
    // MARK: - Card Sizes
    
    enum CardSize {
        case compact
        case regular
        case large
        case hero
        
        var padding: EdgeInsets {
            switch self {
            case .compact:
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
            case .hero:
                return EdgeInsets(
                    top: DesignSystem.Spacing.xl,
                    leading: DesignSystem.Spacing.xl,
                    bottom: DesignSystem.Spacing.xl,
                    trailing: DesignSystem.Spacing.xl
                )
            }
        }
        
        var titleFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.subheadline(weight: .medium)
            case .regular:
                return DesignSystem.Typography.headline(weight: .semibold)
            case .large:
                return DesignSystem.Typography.title3(weight: .semibold)
            case .hero:
                return DesignSystem.Typography.title2(weight: .bold)
            }
        }
        
        var subtitleFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.caption(weight: .regular)
            case .regular:
                return DesignSystem.Typography.subheadline(weight: .regular)
            case .large:
                return DesignSystem.Typography.subheadline(weight: .medium)
            case .hero:
                return DesignSystem.Typography.headline(weight: .medium)
            }
        }
        
        var contentFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.caption(weight: .regular)
            case .regular:
                return DesignSystem.Typography.body(weight: .regular)
            case .large:
                return DesignSystem.Typography.body(weight: .medium)
            case .hero:
                return DesignSystem.Typography.headline(weight: .regular)
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .compact:
                return AppConstants.UI.iconSizeStandard
            case .regular:
                return AppConstants.UI.iconSizeLarge
            case .large:
                return AppConstants.UI.iconSizeXLarge
            case .hero:
                return AppConstants.UI.iconSizeXLarge + 8
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .compact:
                return DesignSystem.Spacing.xs
            case .regular:
                return DesignSystem.Spacing.sm
            case .large:
                return DesignSystem.Spacing.md
            case .hero:
                return DesignSystem.Spacing.lg
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        let content = Group {
            if layout.isHorizontal {
                horizontalLayout
            } else {
                verticalLayout
            }
        }
        .padding(size.padding)
        .background(cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(DesignSystem.Animation.fast, value: isPressed)
        
        if isInteractive {
            Button(action: { onTap?() }) {
                content
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
        } else {
            content
        }
    }
    
    // MARK: - Layout Views
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: size.spacing) {
            if layout.hasIcon, let icon = icon {
                iconView(icon)
            }
            
            if layout.hasText {
                textContent
            }
        }
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.spacing) {
            if layout.hasIcon, let icon = icon {
                iconView(icon)
            }
            
            if layout.hasText {
                textContent
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: layout.isHorizontal ? .leading : .center, spacing: size.spacing / 2) {
            if let title = title {
                Text(title)
                    .font(size.titleFont)
                    .foregroundColor(style.titleColor)
                    .multilineTextAlignment(layout.isHorizontal ? .leading : .center)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(size.subtitleFont)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(layout.isHorizontal ? .leading : .center)
            }
            
            if let content = content {
                Text(content)
                    .font(size.contentFont)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(layout.isHorizontal ? .leading : .center)
            }
        }
    }
    
    @ViewBuilder
    private func iconView(_ iconName: String) -> some View {
        Image(systemName: iconName)
            .font(.system(size: size.iconSize, weight: .medium))
            .foregroundColor(style.iconColor)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if style != .minimal {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(style.backgroundColor)
                .overlay(
                    Group {
                        if let borderColor = style.borderColor {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(borderColor, lineWidth: AppConstants.UI.borderWidthThin)
                        }
                    }
                )
        }
    }
    
    @State private var isPressed = false
}

// MARK: - Convenience Initializers

extension InfoCard {
    
    /// Information card with icon and text
    static func info(
        title: String,
        subtitle: String? = nil,
        icon: String
    ) -> InfoCard {
        InfoCard(title: title, subtitle: subtitle, content: nil, icon: icon)
            .style(.info)
            .layout(.vertical)
            .size(.regular)
    }
    
    /// Success card
    static func success(
        title: String,
        subtitle: String? = nil,
        icon: String = "checkmark.circle.fill"
    ) -> InfoCard {
        InfoCard(title: title, subtitle: subtitle, content: nil, icon: icon)
            .style(.success)
            .layout(.horizontal)
            .size(.regular)
    }
    
    /// Warning card
    static func warning(
        title: String,
        subtitle: String? = nil,
        icon: String = "exclamationmark.triangle.fill"
    ) -> InfoCard {
        InfoCard(title: title, subtitle: subtitle, content: nil, icon: icon)
            .style(.warning)
            .layout(.horizontal)
            .size(.regular)
    }
    
    /// Error card
    static func error(
        title: String,
        subtitle: String? = nil,
        icon: String = "xmark.circle.fill"
    ) -> InfoCard {
        InfoCard(title: title, subtitle: subtitle, content: nil, icon: icon)
            .style(.error)
            .layout(.horizontal)
            .size(.regular)
    }
    
    /// Feature card for showcasing features
    static func feature(
        title: String,
        description: String,
        icon: String
    ) -> InfoCard {
        InfoCard(title: title, subtitle: nil, content: description, icon: icon)
            .style(.prominent)
            .layout(.vertical)
            .size(.large)
    }
    
    /// Simple text card
    static func text(
        title: String,
        content: String? = nil
    ) -> InfoCard {
        InfoCard(title: title, subtitle: nil, content: content, icon: nil)
            .style(.standard)
            .layout(.textOnly)
            .size(.regular)
    }
}

// MARK: - Modifier Extensions

extension InfoCard {
    
    /// Set card style
    func style(_ style: CardStyle) -> InfoCard {
        var card = self
        card.style = style
        return card
    }
    
    /// Set card layout
    func layout(_ layout: CardLayout) -> InfoCard {
        var card = self
        card.layout = layout
        return card
    }
    
    /// Set card size
    func size(_ size: CardSize) -> InfoCard {
        var card = self
        card.size = size
        return card
    }
    
    /// Make interactive
    func interactive(_ onTap: @escaping () -> Void) -> InfoCard {
        var card = self
        card.isInteractive = true
        card.onTap = onTap
        return card
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Status cards
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Status Cards")
                    .font(DesignSystem.Typography.headline())
                
                InfoCard.success(title: "Payment Sent", subtitle: "Transaction confirmed")
                InfoCard.warning(title: "Low Balance", subtitle: "Consider adding funds")
                InfoCard.error(title: "Connection Failed", subtitle: "Check your internet")
                InfoCard.info(title: "New Feature", subtitle: "Tap to learn more", icon: DesignSystem.Icons.info)
            }
            
            // Feature cards
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Feature Cards")
                    .font(DesignSystem.Typography.headline())
                
                InfoCard.feature(
                    title: "Lightning Fast",
                    description: "Send payments instantly with minimal fees",
                    icon: DesignSystem.Icons.lightning
                )
                
                InfoCard.feature(
                    title: "Secure Wallet",
                    description: "Your keys, your Bitcoin. Full control and privacy",
                    icon: DesignSystem.Icons.wallet
                )
            }
            
            // Different styles
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Card Styles")
                    .font(DesignSystem.Typography.headline())
                
                InfoCard.text(title: "Standard Card", content: "Default styling")
                InfoCard(title: "Prominent Card", subtitle: "Enhanced visibility", content: nil, icon: nil)
                    .style(.prominent)
                InfoCard(title: "Outline Card", subtitle: "Minimal border", content: nil, icon: nil)
                    .style(.outline)
            }
        }
        .padding()
    }
}
