import SwiftUI

/// Reusable payment method icon component with consistent styling
/// Supports different payment types, sizes, and visual states
struct PaymentMethodIcon: View {
    
    // MARK: - Configuration
    
    let paymentMethod: PaymentMethod
    
    // MARK: - Styling Options
    
    var size: IconSize = .regular
    var style: IconStyle = .standard
    var showBackground: Bool = true
    var isEnabled: Bool = true
    
    // MARK: - Payment Methods
    
    enum PaymentMethod: String, CaseIterable {
        case bolt11 = "bolt11"
        case lnUrlPay = "lnurl_pay"
        case bolt12Offer = "bolt12_offer"
        case bitcoinAddress = "bitcoin_address"
        case lnUrlWithdraw = "lnurl_withdraw"
        case lnUrlAuth = "lnurl_auth"
        case liquidAddress = "liquid_address"
        case onchainAddress = "onchain_address"
        case unsupported = "unsupported"
        
        var displayName: String {
            switch self {
            case .bolt11:
                return "Lightning Invoice"
            case .lnUrlPay:
                return "Lightning Address"
            case .bolt12Offer:
                return "Bolt12 Offer"
            case .bitcoinAddress:
                return "Bitcoin Address"
            case .lnUrlWithdraw:
                return "Lightning Withdraw"
            case .lnUrlAuth:
                return "Lightning Auth"
            case .liquidAddress:
                return "Liquid Address"
            case .onchainAddress:
                return "Onchain Address"
            case .unsupported:
                return "Unsupported"
            }
        }
        
        var iconName: String {
            switch self {
            case .bolt11:
                return DesignSystem.Icons.lightning
            case .lnUrlPay:
                return "at.circle.fill"
            case .bolt12Offer:
                return "gift.circle.fill"
            case .bitcoinAddress:
                return DesignSystem.Icons.bitcoin
            case .lnUrlWithdraw:
                return "arrow.down.circle.fill"
            case .lnUrlAuth:
                return "key.fill"
            case .liquidAddress:
                return "drop.circle.fill"
            case .onchainAddress:
                return "link.circle.fill"
            case .unsupported:
                return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bolt11:
                return AppConstants.Colors.bolt11
            case .lnUrlPay:
                return AppConstants.Colors.lnUrlPay
            case .bolt12Offer:
                return AppConstants.Colors.bolt12Offer
            case .bitcoinAddress:
                return AppConstants.Colors.bitcoinAddress
            case .lnUrlWithdraw:
                return AppConstants.Colors.lnUrlWithdraw
            case .lnUrlAuth:
                return AppConstants.Colors.lnUrlAuth
            case .liquidAddress:
                return AppConstants.Colors.liquid
            case .onchainAddress:
                return AppConstants.Colors.bitcoin
            case .unsupported:
                return AppConstants.Colors.unsupported
            }
        }
        
        var description: String {
            switch self {
            case .bolt11:
                return "Standard Lightning Network payment request"
            case .lnUrlPay:
                return "Lightning address for easy payments"
            case .bolt12Offer:
                return "Reusable Lightning payment offer"
            case .bitcoinAddress:
                return "Standard Bitcoin onchain address"
            case .lnUrlWithdraw:
                return "Lightning withdrawal request"
            case .lnUrlAuth:
                return "Lightning authentication request"
            case .liquidAddress:
                return "Liquid network address"
            case .onchainAddress:
                return "Bitcoin onchain address"
            case .unsupported:
                return "Unsupported payment method"
            }
        }
        
        var isLightning: Bool {
            switch self {
            case .bolt11, .lnUrlPay, .bolt12Offer, .lnUrlWithdraw, .lnUrlAuth:
                return true
            case .bitcoinAddress, .liquidAddress, .onchainAddress, .unsupported:
                return false
            }
        }
        
        var isOnchain: Bool {
            switch self {
            case .bitcoinAddress, .onchainAddress:
                return true
            case .bolt11, .lnUrlPay, .bolt12Offer, .lnUrlWithdraw, .lnUrlAuth, .liquidAddress, .unsupported:
                return false
            }
        }
        
        var isLiquid: Bool {
            return self == .liquidAddress
        }
    }
    
    // MARK: - Icon Sizes
    
    enum IconSize {
        case small
        case regular
        case large
        case huge
        
        var dimension: CGFloat {
            switch self {
            case .small:
                return AppConstants.UI.iconSizeSmall + 8
            case .regular:
                return AppConstants.UI.iconSizeStandard + 12
            case .large:
                return AppConstants.UI.iconSizeLarge + 16
            case .huge:
                return AppConstants.UI.iconSizeXLarge + 20
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:
                return AppConstants.UI.iconSizeSmall
            case .regular:
                return AppConstants.UI.iconSizeStandard
            case .large:
                return AppConstants.UI.iconSizeLarge
            case .huge:
                return AppConstants.UI.iconSizeXLarge
            }
        }
        
        var cornerRadius: CGFloat {
            return dimension / 4
        }
    }
    
    // MARK: - Icon Styles
    
    enum IconStyle {
        case standard
        case minimal
        case prominent
        case outline
        case badge
        
        var hasBackground: Bool {
            switch self {
            case .standard, .prominent, .badge:
                return true
            case .minimal, .outline:
                return false
            }
        }
        
        var hasBorder: Bool {
            return self == .outline
        }
        
        var backgroundOpacity: Double {
            switch self {
            case .standard:
                return 0.1
            case .prominent:
                return 0.2
            case .badge:
                return 1.0
            case .minimal, .outline:
                return 0.0
            }
        }
        
        func iconColor(for method: PaymentMethod, isEnabled: Bool) -> Color {
            if !isEnabled {
                return DesignSystem.Colors.textSecondary
            }
            
            switch self {
            case .standard, .minimal, .outline, .prominent:
                return method.color
            case .badge:
                return .white
            }
        }
        
        func backgroundColor(for method: PaymentMethod) -> Color {
            return method.color.opacity(backgroundOpacity)
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background
            if style.hasBackground && showBackground {
                Circle()
                    .fill(style.backgroundColor(for: paymentMethod))
                    .frame(width: size.dimension, height: size.dimension)
            }
            
            // Border
            if style.hasBorder {
                Circle()
                    .stroke(paymentMethod.color, lineWidth: AppConstants.UI.borderWidthStandard)
                    .frame(width: size.dimension, height: size.dimension)
            }
            
            // Icon
            Image(systemName: paymentMethod.iconName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(style.iconColor(for: paymentMethod, isEnabled: isEnabled))
        }
        .frame(width: size.dimension, height: size.dimension)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(DesignSystem.Animation.fast, value: isEnabled)
    }
}

// MARK: - Payment Method Badge

/// Badge showing payment method with label
struct PaymentMethodBadge: View {
    let paymentMethod: PaymentMethodIcon.PaymentMethod
    let showLabel: Bool
    
    init(_ paymentMethod: PaymentMethodIcon.PaymentMethod, showLabel: Bool = true) {
        self.paymentMethod = paymentMethod
        self.showLabel = showLabel
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            PaymentMethodIcon(paymentMethod: paymentMethod)
                .size(.small)
                .style(.minimal)
            
            if showLabel {
                Text(paymentMethod.displayName)
                    .font(DesignSystem.Typography.caption(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .fill(paymentMethod.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(paymentMethod.color.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                )
        )
    }
}

/// Grid of supported payment methods
struct PaymentMethodGrid: View {
    let supportedMethods: [PaymentMethodIcon.PaymentMethod]
    let columns: Int
    let onMethodTap: ((PaymentMethodIcon.PaymentMethod) -> Void)?
    
    init(
        supportedMethods: [PaymentMethodIcon.PaymentMethod],
        columns: Int = 3,
        onMethodTap: ((PaymentMethodIcon.PaymentMethod) -> Void)? = nil
    ) {
        self.supportedMethods = supportedMethods
        self.columns = columns
        self.onMethodTap = onMethodTap
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.md) {
            ForEach(supportedMethods, id: \.rawValue) { method in
                VStack(spacing: DesignSystem.Spacing.xs) {
                    PaymentMethodIcon(paymentMethod: method)
                        .size(.large)
                        .style(.standard)
                    
                    Text(method.displayName)
                        .font(DesignSystem.Typography.caption(.medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .onTapGesture {
                    onMethodTap?(method)
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension PaymentMethodIcon {
    
    /// Lightning payment icon
    static func lightning(size: IconSize = .regular) -> PaymentMethodIcon {
        PaymentMethodIcon(paymentMethod: .bolt11)
            .size(size)
            .style(.standard)
    }
    
    /// Bitcoin payment icon
    static func bitcoin(size: IconSize = .regular) -> PaymentMethodIcon {
        PaymentMethodIcon(paymentMethod: .bitcoinAddress)
            .size(size)
            .style(.standard)
    }
    
    /// Liquid payment icon
    static func liquid(size: IconSize = .regular) -> PaymentMethodIcon {
        PaymentMethodIcon(paymentMethod: .liquidAddress)
            .size(size)
            .style(.standard)
    }
    
    /// Create icon from string identifier
    static func from(string: String, size: IconSize = .regular) -> PaymentMethodIcon {
        let method = PaymentMethod(rawValue: string.lowercased()) ?? .unsupported
        return PaymentMethodIcon(paymentMethod: method)
            .size(size)
            .style(.standard)
    }
}

// MARK: - Modifier Extensions

extension PaymentMethodIcon {
    
    /// Set icon size
    func size(_ size: IconSize) -> PaymentMethodIcon {
        var icon = self
        icon.size = size
        return icon
    }
    
    /// Set icon style
    func style(_ style: IconStyle) -> PaymentMethodIcon {
        var icon = self
        icon.style = style
        return icon
    }
    
    /// Show/hide background
    func background(_ show: Bool) -> PaymentMethodIcon {
        var icon = self
        icon.showBackground = show
        return icon
    }
    
    /// Set enabled state
    func enabled(_ isEnabled: Bool) -> PaymentMethodIcon {
        var icon = self
        icon.isEnabled = isEnabled
        return icon
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Different payment methods
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Payment Methods")
                    .font(DesignSystem.Typography.headline())
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    PaymentMethodIcon.lightning()
                    PaymentMethodIcon.bitcoin()
                    PaymentMethodIcon.liquid()
                    PaymentMethodIcon(paymentMethod: .lnUrlPay)
                    PaymentMethodIcon(paymentMethod: .bolt12Offer)
                }
            }
            
            // Different sizes
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Icon Sizes")
                    .font(DesignSystem.Typography.headline())
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    PaymentMethodIcon.lightning(size: .small)
                    PaymentMethodIcon.lightning(size: .regular)
                    PaymentMethodIcon.lightning(size: .large)
                    PaymentMethodIcon.lightning(size: .huge)
                }
            }
            
            // Different styles
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Icon Styles")
                    .font(DesignSystem.Typography.headline())
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    PaymentMethodIcon.lightning().style(.standard)
                    PaymentMethodIcon.lightning().style(.minimal)
                    PaymentMethodIcon.lightning().style(.prominent)
                    PaymentMethodIcon.lightning().style(.outline)
                    PaymentMethodIcon.lightning().style(.badge)
                }
            }
            
            // Badges
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Payment Method Badges")
                    .font(DesignSystem.Typography.headline())
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    PaymentMethodBadge(.bolt11)
                    PaymentMethodBadge(.bitcoinAddress)
                    PaymentMethodBadge(.lnUrlPay)
                }
            }
            
            // Grid
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Payment Method Grid")
                    .font(DesignSystem.Typography.headline())
                
                PaymentMethodGrid(
                    supportedMethods: [.bolt11, .bitcoinAddress, .lnUrlPay, .bolt12Offer, .liquidAddress, .lnUrlWithdraw],
                    columns: 3
                )
            }
        }
        .padding()
    }
}
