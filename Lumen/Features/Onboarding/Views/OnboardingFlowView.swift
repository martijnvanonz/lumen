import SwiftUI

/// Refactored onboarding flow using new step components and service architecture
/// This replaces the monolithic OnboardingView with a clean, focused implementation
struct OnboardingFlowView: View {
    
    // MARK: - State Management
    
    @StateObject private var onboardingState = OnboardingFlowState()
    @StateObject private var walletViewModel = WalletViewModel.create()
    @StateObject private var errorHandler = ErrorHandler.shared
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                onboardingBackground
                
                // Current step content
                VStack(spacing: 0) {
                    currentStepView
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .errorAlert(errorHandler: errorHandler)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var onboardingBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.primary.opacity(0.1),
                DesignSystem.Colors.secondary.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch onboardingState.currentStep {
        case .welcome:
            OnboardingWelcomeStep {
                onboardingState.advance(to: .walletChoice)
            }
            
        case .walletChoice:
            OnboardingWalletChoiceStep(
                onCreateNew: {
                    onboardingState.isImportFlow = false
                    onboardingState.advance(to: .biometricSetup)
                },
                onImportExisting: {
                    onboardingState.isImportFlow = true
                    onboardingState.advance(to: .walletInitialization)
                }
            )
            
        case .biometricSetup:
            // TODO: Implement OnboardingBiometricSetupStep
            VStack {
                Text("Biometric Setup")
                    .font(.title)
                Button("Continue") {
                    onboardingState.advance(to: .walletInitialization)
                }
            }
            
        case .walletInitialization:
            // TODO: Implement OnboardingWalletInitializationStep
            VStack {
                Text("Wallet Initialization")
                    .font(.title)
                if onboardingState.isImportFlow {
                    Text("Importing wallet...")
                } else {
                    Text("Creating new wallet...")
                }
                Button("Continue") {
                    // Check if currency is already selected
                    if CurrencyManager.shared.selectedCurrency != nil {
                        onboardingState.advance(to: .completed)
                    } else {
                        onboardingState.advance(to: .currencySelection)
                    }
                }
            }
            
        case .currencySelection:
            OnboardingCurrencySelectionStep {
                onboardingState.advance(to: .completed)
            }
            
        case .completed:
            OnboardingCompletedStep {
                completeOnboarding()
            }
        }
    }
    
    // MARK: - Onboarding Completion
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        // Mark onboarding as completed via WalletViewModel
        walletViewModel.markOnboardingCompleted()
        
        // Post notification to signal onboarding completion
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

// MARK: - Onboarding Flow State

/// State management for onboarding flow
class OnboardingFlowState: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isImportFlow: Bool = false
    
    enum OnboardingStep: CaseIterable {
        case welcome
        case walletChoice
        case biometricSetup
        case walletInitialization
        case currencySelection
        case completed
        
        var title: String {
            switch self {
            case .welcome:
                return "Welcome"
            case .walletChoice:
                return "Wallet Setup"
            case .biometricSetup:
                return "Security"
            case .walletInitialization:
                return "Initialization"
            case .currencySelection:
                return "Currency"
            case .completed:
                return "Complete"
            }
        }
        
        var stepNumber: Int {
            switch self {
            case .welcome:
                return 1
            case .walletChoice:
                return 2
            case .biometricSetup:
                return 3
            case .walletInitialization:
                return 4
            case .currencySelection:
                return 5
            case .completed:
                return 6
            }
        }
    }
    
    func advance(to step: OnboardingStep) {
        withAnimation(DesignSystem.Animation.spring) {
            currentStep = step
        }
    }
    
    func goBack() {
        let allSteps = OnboardingStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            withAnimation(DesignSystem.Animation.spring) {
                currentStep = allSteps[currentIndex - 1]
            }
        }
    }
}

// MARK: - Enhanced Onboarding Flow

/// Enhanced onboarding flow with progress indicator and navigation
struct EnhancedOnboardingFlowView: View {
    
    // MARK: - State Management
    
    @StateObject private var onboardingState = OnboardingFlowState()
    @StateObject private var walletViewModel = WalletViewModel.create()
    @StateObject private var errorHandler = ErrorHandler.shared
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                onboardingBackground
                
                VStack(spacing: 0) {
                    // Progress indicator
                    if onboardingState.currentStep != .welcome && onboardingState.currentStep != .completed {
                        OnboardingProgressIndicator(
                            currentStep: onboardingState.currentStep,
                            totalSteps: OnboardingFlowState.OnboardingStep.allCases.count
                        )
                        .padding(.top, DesignSystem.Spacing.md)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    // Current step content
                    currentStepView
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .errorAlert(errorHandler: errorHandler)
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var onboardingBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                DesignSystem.Colors.primary.opacity(0.1),
                DesignSystem.Colors.secondary.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Current Step View
    
    @ViewBuilder
    private var currentStepView: some View {
        switch onboardingState.currentStep {
        case .welcome:
            OnboardingWelcomeStep {
                onboardingState.advance(to: .walletChoice)
            }
            
        case .walletChoice:
            OnboardingWalletChoiceStep(
                onCreateNew: {
                    onboardingState.isImportFlow = false
                    onboardingState.advance(to: .biometricSetup)
                },
                onImportExisting: {
                    onboardingState.isImportFlow = true
                    onboardingState.advance(to: .walletInitialization)
                }
            )
            
        case .biometricSetup:
            // TODO: Implement OnboardingBiometricSetupStep
            VStack {
                Text("Biometric Setup")
                    .font(.title)
                Button("Continue") {
                    onboardingState.advance(to: .walletInitialization)
                }
            }
            
        case .walletInitialization:
            // TODO: Implement OnboardingWalletInitializationStep
            VStack {
                Text("Wallet Initialization")
                    .font(.title)
                if onboardingState.isImportFlow {
                    Text("Importing wallet...")
                } else {
                    Text("Creating new wallet...")
                }
                Button("Continue") {
                    if CurrencyManager.shared.selectedCurrency != nil {
                        onboardingState.advance(to: .completed)
                    } else {
                        onboardingState.advance(to: .currencySelection)
                    }
                }
            }
            
        case .currencySelection:
            EnhancedOnboardingCurrencySelectionStep {
                onboardingState.advance(to: .completed)
            }
            
        case .completed:
            EnhancedOnboardingCompletedStep {
                completeOnboarding()
            }
        }
    }
    
    // MARK: - Onboarding Completion
    
    private func completeOnboarding() {
        // Mark onboarding as completed via WalletViewModel
        walletViewModel.markOnboardingCompleted()
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

// MARK: - Progress Indicator

/// Progress indicator for onboarding steps
struct OnboardingProgressIndicator: View {
    let currentStep: OnboardingFlowState.OnboardingStep
    let totalSteps: Int
    
    private var progress: Double {
        Double(currentStep.stepNumber) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Step indicator
            HStack {
                Text("Step \(currentStep.stepNumber) of \(totalSteps)")
                    .font(DesignSystem.Typography.caption(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text(currentStep.title)
                    .font(DesignSystem.Typography.caption(weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
}

// MARK: - Preview

#Preview {
    OnboardingFlowView()
}
