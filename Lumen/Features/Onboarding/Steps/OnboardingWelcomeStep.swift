import SwiftUI

/// Welcome step component for onboarding flow
/// Uses new design system and InfoCard components for consistent styling
struct OnboardingWelcomeStep: View {
    
    // MARK: - Configuration
    
    let onContinue: () -> Void
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // App branding
            VStack(spacing: DesignSystem.Spacing.lg) {
                // App icon placeholder
                Image(systemName: DesignSystem.Icons.lightning)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Welcome to Lumen")
                        .font(DesignSystem.Typography.largeTitle(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Your Lightning Bitcoin Wallet")
                        .font(DesignSystem.Typography.title3(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Features
            VStack(spacing: DesignSystem.Spacing.lg) {
                OnboardingFeatureCard(
                    icon: "lock.shield.fill",
                    title: "Secure by Design",
                    description: "Your wallet is protected by biometric authentication and iCloud Keychain"
                )
                
                OnboardingFeatureCard(
                    icon: DesignSystem.Icons.lightning,
                    title: "Lightning Fast",
                    description: "Send and receive Bitcoin payments instantly with Lightning Network"
                )
                
                OnboardingFeatureCard(
                    icon: "icloud.fill",
                    title: "Auto Recovery",
                    description: "Seamlessly restore your wallet on any device with your Apple ID"
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            Spacer()
            
            // Continue button
            StandardButton(title: "Get Started", action: onContinue)
                .style(.primary)
                .size(.large)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Feature Card Component

/// Feature card component for onboarding features
struct OnboardingFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(DesignSystem.Typography.title2(weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: AppConstants.UI.iconSizeXLarge, height: AppConstants.UI.iconSizeXLarge)
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.headline(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.subheadline(weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .lightShadow()
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingWelcomeStep {
        print("Continue tapped")
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
