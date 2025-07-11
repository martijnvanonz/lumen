import SwiftUI

/// Notification card for refundable swaps
/// Uses the new InfoCard component with enhanced functionality
struct RefundNotificationCard: View {
    
    // MARK: - Configuration
    
    let refundCount: Int
    let onTap: () -> Void
    let onDismiss: (() -> Void)?
    
    // MARK: - Styling Options
    
    var style: NotificationStyle = .warning
    var isDismissible: Bool = true
    
    // MARK: - Notification Styles
    
    enum NotificationStyle {
        case info
        case warning
        case urgent
        
        var cardStyle: InfoCard.CardStyle {
            switch self {
            case .info:
                return .info
            case .warning:
                return .warning
            case .urgent:
                return .error
            }
        }
        
        var icon: String {
            switch self {
            case .info:
                return DesignSystem.Icons.info
            case .warning:
                return DesignSystem.Icons.warning
            case .urgent:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var title: String {
            switch self {
            case .info:
                return "Refunds Available"
            case .warning:
                return "Refunds Pending"
            case .urgent:
                return "Action Required"
            }
        }
    }
    
    // MARK: - View Body
    
    var body: some View {
        if refundCount > 0 {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: style.icon)
                    .font(DesignSystem.Typography.title3(.medium))
                    .foregroundColor(style.cardStyle.iconColor)
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(style.title)
                        .font(DesignSystem.Typography.subheadline(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(refundMessage)
                        .font(DesignSystem.Typography.caption(.regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action indicator
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.caption(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                // Dismiss button (optional)
                if isDismissible, let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Typography.caption(.medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .standardPadding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(style.cardStyle.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(style.cardStyle.borderColor ?? Color.clear, lineWidth: AppConstants.UI.borderWidthThin)
                    )
            )
            .onTapGesture {
                onTap()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    // MARK: - Computed Properties
    
    private var refundMessage: String {
        if refundCount == 1 {
            return "You have 1 refund available. Tap to claim it."
        } else {
            return "You have \(refundCount) refunds available. Tap to claim them."
        }
    }
}

// MARK: - Enhanced Refund Card

/// Enhanced refund notification with more details
struct EnhancedRefundNotificationCard: View {
    
    // MARK: - Configuration
    
    let refundCount: Int
    let totalAmount: UInt64?
    let onTap: () -> Void
    let onDismiss: (() -> Void)?
    
    // MARK: - View Body
    
    var body: some View {
        if refundCount > 0 {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: DesignSystem.Icons.warning)
                            .font(DesignSystem.Typography.subheadline(.medium))
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("Refunds Available")
                            .font(DesignSystem.Typography.subheadline(.semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(DesignSystem.Typography.caption(.medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("You have \(refundCount) \(refundCount == 1 ? "refund" : "refunds") waiting to be claimed.")
                        .font(DesignSystem.Typography.body(.regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if let totalAmount = totalAmount {
                        HStack {
                            Text("Total amount:")
                                .font(DesignSystem.Typography.subheadline(.medium))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            AmountDisplayCard.fee(totalAmount)
                                .style(.minimal)
                                .size(.compact)
                        }
                    }
                }
                
                // Action button
                StandardButton("Claim Refunds", action: onTap)
                    .style(.warning)
                    .size(.regular)
                    .icon(DesignSystem.Icons.receive)
            }
            .standardPadding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.warning.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                    )
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Compact Refund Badge

/// Compact refund notification badge
struct CompactRefundBadge: View {
    
    // MARK: - Configuration
    
    let refundCount: Int
    let onTap: () -> Void
    
    // MARK: - View Body
    
    var body: some View {
        if refundCount > 0 {
            Button(action: onTap) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: DesignSystem.Icons.warning)
                        .font(DesignSystem.Typography.caption(.medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("\(refundCount)")
                        .font(DesignSystem.Typography.caption(.semibold))
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("refund\(refundCount == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.caption(.medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.warning.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: AppConstants.UI.borderWidthThin)
                        )
                )
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
}

// MARK: - Modifier Extensions

extension RefundNotificationCard {
    
    /// Set notification style
    func style(_ style: NotificationStyle) -> RefundNotificationCard {
        var card = self
        card.style = style
        return card
    }
    
    /// Set dismissible state
    func dismissible(_ isDismissible: Bool) -> RefundNotificationCard {
        var card = self
        card.isDismissible = isDismissible
        return card
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Standard notification
        RefundNotificationCard(
            refundCount: 2,
            onTap: { print("Refund tapped") },
            onDismiss: { print("Dismissed") }
        )
        
        // Enhanced notification with amount
        EnhancedRefundNotificationCard(
            refundCount: 1,
            totalAmount: 50_000,
            onTap: { print("Refund tapped") },
            onDismiss: { print("Dismissed") }
        )
        
        // Compact badge
        HStack {
            Text("Toolbar:")
            Spacer()
            CompactRefundBadge(
                refundCount: 3,
                onTap: { print("Badge tapped") }
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        
        // Different styles
        VStack(spacing: DesignSystem.Spacing.md) {
            RefundNotificationCard(
                refundCount: 1,
                onTap: { print("Info tapped") },
                onDismiss: nil
            )
            .style(.info)
            .dismissible(false)
            
            RefundNotificationCard(
                refundCount: 5,
                onTap: { print("Urgent tapped") },
                onDismiss: { print("Dismissed") }
            )
            .style(.urgent)
        }
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}
