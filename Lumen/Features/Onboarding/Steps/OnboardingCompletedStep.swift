import SwiftUI

/// Completion step component for onboarding flow
/// Features success animation, wallet ready confirmation, and smooth transition to main app
struct OnboardingCompletedStep: View {
    
    // MARK: - Configuration
    
    let onComplete: () -> Void
    
    // MARK: - Animation State
    
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var pulseAnimation = false
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Success animation
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Animated checkmark
                ZStack {
                    // Background circle
                    Circle()
                        .fill(DesignSystem.Colors.success)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(showCheckmark ? 1.0 : 0.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                    
                    // Checkmark icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0),
                            value: showCheckmark
                        )
                }
                
                // Success message
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Welcome to Lumen!")
                        .font(DesignSystem.Typography.largeTitle(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.5),
                            value: showContent
                        )
                    
                    Text("Your Lightning wallet is ready to use")
                        .font(DesignSystem.Typography.title3(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.7),
                            value: showContent
                        )
                }
            }
            
            Spacer()
            
            // Wallet ready features
            VStack(spacing: DesignSystem.Spacing.md) {
                OnboardingCompletionFeature(
                    icon: DesignSystem.Icons.lightning,
                    title: "Lightning Ready",
                    description: "Send and receive instant payments"
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.8).delay(0.9),
                    value: showContent
                )
                
                OnboardingCompletionFeature(
                    icon: "shield.checkered",
                    title: "Securely Protected",
                    description: "Your wallet is encrypted and backed up"
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.8).delay(1.1),
                    value: showContent
                )
                
                OnboardingCompletionFeature(
                    icon: "icloud.and.arrow.up",
                    title: "Auto Recovery",
                    description: "Restore on any device with your Apple ID"
                )
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.8).delay(1.3),
                    value: showContent
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            Spacer()
            
            // Get started button
            StandardButton(title: "Start Using Lumen", action: onComplete)
                .style(.primary)
                .size(.large)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(
                    .easeOut(duration: 0.8).delay(1.5),
                    value: showContent
                )
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - Animation Methods
    
    private func startAnimationSequence() {
        // Start checkmark animation immediately
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCheckmark = true
        }
        
        // Start pulse animation after checkmark appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pulseAnimation = true
        }
        
        // Show content after checkmark animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showContent = true
        }
    }
}

// MARK: - Completion Feature Component

/// Feature component for completion step
struct OnboardingCompletionFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            Image(systemName: icon)
                .font(DesignSystem.Typography.title2(weight: .medium))
                .foregroundColor(DesignSystem.Colors.success)
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

// MARK: - Enhanced Completion Step

/// Enhanced completion step with additional wallet status information
struct EnhancedOnboardingCompletedStep: View {
    
    // MARK: - Configuration
    
    let onComplete: () -> Void
    
    // MARK: - Dependencies
    
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @StateObject private var walletViewModel = WalletViewModel.create()
    
    // MARK: - Animation State
    
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var showWalletInfo = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Success animation (same as basic version)
            successAnimationView
            
            Spacer()
            
            // Wallet configuration summary
            if showWalletInfo {
                walletConfigurationCard
            }
            
            // Ready features
            readyFeaturesView
            
            Spacer()
            
            // Get started button
            getStartedButton
        }
        .onAppear {
            startEnhancedAnimationSequence()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var successAnimationView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Animated checkmark (same as basic version)
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.success)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0),
                        value: showCheckmark
                    )
            }
            
            // Success message
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Wallet Created Successfully!")
                    .font(DesignSystem.Typography.largeTitle(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.8).delay(0.5),
                        value: showContent
                    )
                
                Text("Your Lightning wallet is ready for instant payments")
                    .font(DesignSystem.Typography.title3(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.8).delay(0.7),
                        value: showContent
                    )
            }
        }
    }
    
    @ViewBuilder
    private var walletConfigurationCard: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Wallet Configuration")
                .font(DesignSystem.Typography.headline(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack {
                Text("Currency:")
                    .font(DesignSystem.Typography.body(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if let currency = currencyManager.selectedCurrency {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: currency.icon)
                            .foregroundColor(currency.iconColor)
                        Text(currency.displayCode)
                            .font(DesignSystem.Typography.body(weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                } else {
                    Text("USD")
                        .font(DesignSystem.Typography.body(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .standardPadding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.backgroundSecondary)
                .lightShadow()
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
        .opacity(showWalletInfo ? 1.0 : 0.0)
        .offset(y: showWalletInfo ? 0 : 20)
        .animation(
            .easeOut(duration: 0.8).delay(0.9),
            value: showWalletInfo
        )
    }
    
    @ViewBuilder
    private var readyFeaturesView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            OnboardingCompletionFeature(
                icon: DesignSystem.Icons.lightning,
                title: "Lightning Ready",
                description: "Send and receive instant Bitcoin payments"
            )
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(
                .easeOut(duration: 0.8).delay(1.1),
                value: showContent
            )
            
            OnboardingCompletionFeature(
                icon: "lock.shield.fill",
                title: "Securely Protected",
                description: "Biometric authentication and iCloud backup"
            )
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(
                .easeOut(duration: 0.8).delay(1.3),
                value: showContent
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    @ViewBuilder
    private var getStartedButton: some View {
        StandardButton(title: "Start Using Lumen", action: onComplete)
            .style(.primary)
            .size(.large)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            .animation(
                .easeOut(duration: 0.8).delay(1.5),
                value: showContent
            )
    }
    
    // MARK: - Animation Methods
    
    private func startEnhancedAnimationSequence() {
        // Start checkmark animation immediately
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCheckmark = true
        }
        
        // Start pulse animation after checkmark appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pulseAnimation = true
        }
        
        // Show content after checkmark animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showContent = true
        }
        
        // Show wallet info after content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showWalletInfo = true
        }
    }
}

// MARK: - Preview

#Preview("Basic Completion") {
    OnboardingCompletedStep {
        print("Onboarding completed")
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

#Preview("Enhanced Completion") {
    EnhancedOnboardingCompletedStep {
        print("Enhanced onboarding completed")
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
