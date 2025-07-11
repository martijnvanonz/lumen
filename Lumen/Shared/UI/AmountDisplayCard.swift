import SwiftUI

/// Reusable amount display component for showing Bitcoin/Lightning amounts
/// Supports different display modes, currencies, and styling options
struct AmountDisplayCard: View {
    
    // MARK: - Configuration
    
    let amount: UInt64
    let title: String?
    let subtitle: String?
    
    // MARK: - Styling Options
    
    var displayMode: DisplayMode = .both
    var style: CardStyle = .standard
    var size: CardSize = .regular
    var isInteractive: Bool = false
    var onTap: (() -> Void)? = nil
    
    // MARK: - Display Modes
    
    enum DisplayMode {
        case satsOnly
        case currencyOnly
        case both
        case stacked
        
        var showsSats: Bool {
            switch self {
            case .satsOnly, .both, .stacked:
                return true
            case .currencyOnly:
                return false
            }
        }
        
        var showsCurrency: Bool {
            switch self {
            case .currencyOnly, .both, .stacked:
                return true
            case .satsOnly:
                return false
            }
        }
        
        var isStacked: Bool {
            return self == .stacked
        }
    }
    
    // MARK: - Card Styles
    
    enum CardStyle {
        case standard
        case prominent
        case minimal
        case success
        case warning
        case error
        
        var backgroundColor: Color {
            switch self {
            case .standard:
                return DesignSystem.Colors.backgroundPrimary
            case .prominent:
                return DesignSystem.Colors.primary.opacity(0.1)
            case .minimal:
                return Color.clear
            case .success:
                return DesignSystem.Colors.success.opacity(0.1)
            case .warning:
                return DesignSystem.Colors.warning.opacity(0.1)
            case .error:
                return DesignSystem.Colors.error.opacity(0.1)
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .standard:
                return DesignSystem.Colors.borderPrimary
            case .prominent:
                return DesignSystem.Colors.primary.opacity(0.3)
            case .minimal:
                return nil
            case .success:
                return DesignSystem.Colors.success.opacity(0.3)
            case .warning:
                return DesignSystem.Colors.warning.opacity(0.3)
            case .error:
                return DesignSystem.Colors.error.opacity(0.3)
            }
        }
        
        var accentColor: Color {
            switch self {
            case .standard, .minimal:
                return DesignSystem.Colors.textPrimary
            case .prominent:
                return DesignSystem.Colors.primary
            case .success:
                return DesignSystem.Colors.success
            case .warning:
                return DesignSystem.Colors.warning
            case .error:
                return DesignSystem.Colors.error
            }
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
        
        var amountFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.subheadline(.semibold)
            case .regular:
                return DesignSystem.Typography.title3(.semibold)
            case .large:
                return DesignSystem.Typography.title2(.bold)
            case .hero:
                return DesignSystem.Typography.largeTitle(.bold)
            }
        }
        
        var titleFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.caption(.medium)
            case .regular:
                return DesignSystem.Typography.subheadline(.medium)
            case .large:
                return DesignSystem.Typography.headline(.semibold)
            case .hero:
                return DesignSystem.Typography.title3(.semibold)
            }
        }
        
        var subtitleFont: Font {
            switch self {
            case .compact:
                return DesignSystem.Typography.caption(.regular)
            case .regular:
                return DesignSystem.Typography.caption(.medium)
            case .large:
                return DesignSystem.Typography.subheadline(.regular)
            case .hero:
                return DesignSystem.Typography.subheadline(.medium)
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        let content = VStack(spacing: size == .compact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.sm) {
            // Title
            if let title = title {
                Text(title)
                    .font(size.titleFont)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Amount display
            amountView
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(size.subtitleFont)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(size.padding)
        .background(cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(DesignSystem.Animation.fast, value: isPressed)
        .onTapGesture {
            if isInteractive, let onTap = onTap {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isInteractive {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var amountView: some View {
        if displayMode.isStacked {
            // Stacked layout
            VStack(spacing: DesignSystem.Spacing.xs / 2) {
                if displayMode.showsSats {
                    satsAmountView
                }
                if displayMode.showsCurrency {
                    currencyAmountView
                }
            }
        } else {
            // Inline layout
            HStack(spacing: DesignSystem.Spacing.sm) {
                if displayMode.showsSats {
                    satsAmountView
                }
                
                if displayMode.showsSats && displayMode.showsCurrency {
                    Text("•")
                        .font(size.amountFont)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if displayMode.showsCurrency {
                    currencyAmountView
                }
            }
        }
    }
    
    @ViewBuilder
    private var satsAmountView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text(formattedSatsAmount)
                .font(DesignSystem.Typography.numeric(size: size.amountFont.pointSize))
                .foregroundColor(style.accentColor)
            
            Text("sats")
                .font(size.amountFont)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    @ViewBuilder
    private var currencyAmountView: some View {
        if let currencyAmount = formattedCurrencyAmount {
            Text(currencyAmount)
                .font(DesignSystem.Typography.numeric(size: size.amountFont.pointSize))
                .foregroundColor(displayMode.showsSats ? DesignSystem.Colors.textSecondary : style.accentColor)
        }
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
    
    // MARK: - Computed Properties
    
    private var formattedSatsAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    private var formattedCurrencyAmount: String? {
        // This would integrate with CurrencyManager for real currency conversion
        // For now, return a placeholder
        let rate = 45000.0 // Placeholder BTC price
        let btcAmount = Double(amount) / 100_000_000
        let currencyAmount = btcAmount * rate
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // This would come from CurrencyManager
        
        return formatter.string(from: NSNumber(value: currencyAmount))
    }
    
    @State private var isPressed = false
}

// MARK: - Convenience Initializers

extension AmountDisplayCard {
    
    /// Balance display card
    static func balance(
        _ amount: UInt64,
        title: String = "Balance"
    ) -> AmountDisplayCard {
        AmountDisplayCard(amount: amount, title: title, subtitle: nil)
            .style(.prominent)
            .size(.hero)
            .displayMode(.stacked)
    }
    
    /// Transaction amount card
    static func transaction(
        _ amount: UInt64,
        title: String? = nil,
        subtitle: String? = nil
    ) -> AmountDisplayCard {
        AmountDisplayCard(amount: amount, title: title, subtitle: subtitle)
            .style(.standard)
            .size(.regular)
            .displayMode(.both)
    }
    
    /// Fee display card
    static func fee(
        _ amount: UInt64,
        title: String = "Fee"
    ) -> AmountDisplayCard {
        AmountDisplayCard(amount: amount, title: title, subtitle: nil)
            .style(.minimal)
            .size(.compact)
            .displayMode(.satsOnly)
    }
    
    /// Payment amount card
    static func payment(
        _ amount: UInt64,
        title: String? = nil,
        isReceived: Bool = false
    ) -> AmountDisplayCard {
        AmountDisplayCard(amount: amount, title: title, subtitle: nil)
            .style(isReceived ? .success : .standard)
            .size(.large)
            .displayMode(.stacked)
    }
}

// MARK: - Modifier Extensions

extension AmountDisplayCard {
    
    /// Set display mode
    func displayMode(_ mode: DisplayMode) -> AmountDisplayCard {
        var card = self
        card.displayMode = mode
        return card
    }
    
    /// Set card style
    func style(_ style: CardStyle) -> AmountDisplayCard {
        var card = self
        card.style = style
        return card
    }
    
    /// Set card size
    func size(_ size: CardSize) -> AmountDisplayCard {
        var card = self
        card.size = size
        return card
    }
    
    /// Make interactive
    func interactive(_ onTap: @escaping () -> Void) -> AmountDisplayCard {
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
            // Balance card
            AmountDisplayCard.balance(1_250_000, title: "Wallet Balance")
            
            // Transaction cards
            VStack(spacing: DesignSystem.Spacing.md) {
                AmountDisplayCard.transaction(50_000, title: "Sent", subtitle: "Lightning Payment")
                AmountDisplayCard.payment(75_000, title: "Received", isReceived: true)
                AmountDisplayCard.fee(250, title: "Network Fee")
            }
            
            // Different styles
            VStack(spacing: DesignSystem.Spacing.md) {
                AmountDisplayCard(amount: 100_000, title: "Standard", subtitle: nil).style(.standard)
                AmountDisplayCard(amount: 100_000, title: "Success", subtitle: nil).style(.success)
                AmountDisplayCard(amount: 100_000, title: "Warning", subtitle: nil).style(.warning)
                AmountDisplayCard(amount: 100_000, title: "Error", subtitle: nil).style(.error)
            }
        }
        .padding()
    }
}
