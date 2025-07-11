import SwiftUI

/// Wallet choice step for onboarding flow
/// Allows users to create new wallet or import existing one
struct OnboardingWalletChoiceStep: View {
    
    // MARK: - Configuration
    
    let onCreateNew: () -> Void
    let onImportExisting: () -> Void
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: DesignSystem.Icons.wallet)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Set Up Your Wallet")
                        .font(DesignSystem.Typography.largeTitle(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose how you'd like to get started")
                        .font(DesignSystem.Typography.title3(.regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Choice options
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Create new wallet option
                OnboardingChoiceCard(
                    icon: "plus.circle.fill",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Create New Wallet",
                    subtitle: "Generate a new 24-word recovery phrase",
                    isRecommended: true,
                    action: onCreateNew
                )
                
                // Import existing wallet option
                OnboardingChoiceCard(
                    icon: "arrow.down.circle.fill",
                    iconColor: DesignSystem.Colors.secondary,
                    title: "Import Existing Wallet",
                    subtitle: "Restore from your 24-word recovery phrase",
                    isRecommended: false,
                    action: onImportExisting
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            Spacer()
        }
    }
}

// MARK: - Choice Card Component

/// Choice card component for wallet setup options
struct OnboardingChoiceCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(DesignSystem.Typography.title2(.medium))
                    .foregroundColor(iconColor)
                    .frame(width: AppConstants.UI.iconSizeXLarge, height: AppConstants.UI.iconSizeXLarge)
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(title)
                            .font(DesignSystem.Typography.headline(.semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(DesignSystem.Typography.caption(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.xs + 2)
                                .padding(.vertical, DesignSystem.Spacing.xs / 2)
                                .background(DesignSystem.Colors.success)
                                .cornerRadius(DesignSystem.CornerRadius.sm / 2)
                        }
                        
                        Spacer()
                    }
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.subheadline(.regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(DesignSystem.Typography.subheadline(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .standardPadding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(
                                isRecommended ? iconColor.opacity(0.3) : DesignSystem.Colors.borderPrimary,
                                lineWidth: AppConstants.UI.borderWidthThin
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(DesignSystem.Animation.fast, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    @State private var isPressed = false
}

// MARK: - Enhanced Choice Step

/// Enhanced wallet choice step with additional information
struct EnhancedOnboardingWalletChoiceStep: View {
    
    // MARK: - Configuration
    
    let onCreateNew: () -> Void
    let onImportExisting: () -> Void
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: DesignSystem.Icons.wallet)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Set Up Your Wallet")
                        .font(DesignSystem.Typography.largeTitle(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose how you'd like to get started with Lumen")
                        .font(DesignSystem.Typography.title3(.regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            
            Spacer()
            
            // Choice options with detailed info
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Create new wallet
                VStack(spacing: DesignSystem.Spacing.md) {
                    OnboardingChoiceCard(
                        icon: "plus.circle.fill",
                        iconColor: DesignSystem.Colors.primary,
                        title: "Create New Wallet",
                        subtitle: "Perfect for first-time users",
                        isRecommended: true,
                        action: onCreateNew
                    )
                    
                    InfoCard.info(
                        title: "What happens next?",
                        subtitle: "We'll generate a secure 24-word recovery phrase and set up biometric authentication",
                        icon: DesignSystem.Icons.info
                    )
                    .style(.info)
                    .size(.compact)
                }
                
                // Import existing wallet
                VStack(spacing: DesignSystem.Spacing.md) {
                    OnboardingChoiceCard(
                        icon: "arrow.down.circle.fill",
                        iconColor: DesignSystem.Colors.secondary,
                        title: "Import Existing Wallet",
                        subtitle: "Already have a recovery phrase?",
                        isRecommended: false,
                        action: onImportExisting
                    )
                    
                    InfoCard.info(
                        title: "Have your recovery phrase ready",
                        subtitle: "You'll need your 24-word recovery phrase to restore your wallet",
                        icon: DesignSystem.Icons.warning
                    )
                    .style(.warning)
                    .size(.compact)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.xl) {
        // Standard version
        OnboardingWalletChoiceStep(
            onCreateNew: { print("Create new tapped") },
            onImportExisting: { print("Import existing tapped") }
        )
        
        Divider()
        
        // Enhanced version
        EnhancedOnboardingWalletChoiceStep(
            onCreateNew: { print("Create new tapped") },
            onImportExisting: { print("Import existing tapped") }
        )
    }
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.primary.opacity(0.1),
                DesignSystem.Colors.secondary.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
