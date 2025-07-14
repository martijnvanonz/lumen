import SwiftUI

/// Enhanced wallet balance card component using the new design system
/// Replaces the old BalanceCard with better styling and functionality
struct WalletBalanceCard: View {
    
    // MARK: - Configuration
    
    let balance: UInt64
    let isLoading: Bool
    let onInfoTap: (() -> Void)?
    
    // MARK: - Styling Options
    
    var showNetworkIndicator: Bool = true
    var showInfoButton: Bool = true
    
    // MARK: - Initialization
    
    init(
        balance: UInt64,
        isLoading: Bool = false,
        onInfoTap: (() -> Void)? = nil
    ) {
        self.balance = balance
        self.isLoading = isLoading
        self.onInfoTap = onInfoTap
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with title and info button
            HStack {
                Text("Balance")
                    .font(DesignSystem.Typography.headline(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if showInfoButton {
                    Button(action: { onInfoTap?() }) {
                        Image(systemName: DesignSystem.Icons.info)
                            .font(DesignSystem.Typography.subheadline(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            // Balance display
            if isLoading {
                LoadingStateView.minimal("Loading balance...")
                    .frame(height: 60)
            } else {
                AmountDisplayCard.balance(balance)
                    .style(.prominent)
                    .size(.hero)
            }
            
            // Network indicator
            if showNetworkIndicator {
                networkIndicator
            }
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.backgroundPrimary)
                .mediumShadow()
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var networkIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            PaymentMethodIcon.lightning(size: .small)
                .style(.minimal)
            
            Text("Lightning Network")
                .font(DesignSystem.Typography.caption(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Modifier Extensions

extension WalletBalanceCard {
    
    /// Show/hide network indicator
    func networkIndicator(_ show: Bool) -> WalletBalanceCard {
        var card = self
        card.showNetworkIndicator = show
        return card
    }
    
    /// Show/hide info button
    func infoButton(_ show: Bool) -> WalletBalanceCard {
        var card = self
        card.showInfoButton = show
        return card
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        // Normal state
        WalletBalanceCard(
            balance: 1_250_000,
            onInfoTap: { print("Info tapped") }
        )
        
        // Loading state
        WalletBalanceCard(
            balance: 0,
            isLoading: true
        )
        
        // Minimal version
        WalletBalanceCard(
            balance: 500_000
        )
        .networkIndicator(false)
        .infoButton(false)
    }
    .padding()
    .background(DesignSystem.Colors.backgroundSecondary)
}
