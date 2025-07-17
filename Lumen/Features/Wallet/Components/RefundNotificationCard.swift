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
            GlassmorphismCard {
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Icon
                    Image(systemName: style.icon)
                        .font(DesignSystem.Typography.title3(weight: .medium))
                        .foregroundColor(style.cardStyle.iconColor)

                    // Content
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(style.title)
                            .font(DesignSystem.Typography.subheadline(weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)

                        Text(refundMessage)
                            .font(DesignSystem.Typography.caption(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Action indicator
                    Image(systemName: "chevron.right")
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)

                    // Dismiss button (optional)
                    if isDismissible, let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(DesignSystem.Typography.caption(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
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
            GlassmorphismCard {
                VStack(spacing: DesignSystem.Spacing.md) {
                // Header
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: DesignSystem.Icons.warning)
                            .font(DesignSystem.Typography.subheadline(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.warning)
                        
                        Text("Refunds Available")
                            .font(DesignSystem.Typography.subheadline(weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    if let onDismiss = onDismiss {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(DesignSystem.Typography.caption(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("You have \(refundCount) \(refundCount == 1 ? "refund" : "refunds") waiting to be claimed.")
                        .font(DesignSystem.Typography.body(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if let totalAmount = totalAmount {
                        HStack {
                            Text("Total amount:")
                                .font(DesignSystem.Typography.subheadline(weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            AmountDisplayCard.fee(totalAmount)
                                .style(.minimal)
                                .size(.compact)
                        }
                    }
                }
                
                // Action button
                StandardButton(title: "Claim Refunds", action: onTap)
                    .style(.primary)
                    .size(.regular)
                    .icon(DesignSystem.Icons.receive)
                }
            }
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
                        .font(DesignSystem.Typography.caption(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("\(refundCount)")
                        .font(DesignSystem.Typography.caption(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.warning)
                    
                    Text("refund\(refundCount == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.caption(weight: .medium))
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
