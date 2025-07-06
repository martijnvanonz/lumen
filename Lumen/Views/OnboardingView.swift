import SwiftUI
import BreezSDKLiquid

struct OnboardingView: View {
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var onboardingState = OnboardingState()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    switch onboardingState.currentStep {
                    case .welcome:
                        WelcomeStepView(onboardingState: onboardingState)
                    case .walletChoice:
                        WalletChoiceView(onboardingState: onboardingState)
                    case .biometricSetup:
                        BiometricSetupView(onboardingState: onboardingState)
                    case .walletInitialization:
                        WalletInitializationView(onboardingState: onboardingState)
                    case .currencySelection:
                        CurrencySelectionView(onboardingState: onboardingState)
                    case .completed:
                        CompletedView()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            checkExistingWallet()
        }
    }
    
    private func checkExistingWallet() {
        // If we reach onboarding, it means no existing wallet was found
        // or user explicitly chose to create a new wallet
        // Always start with welcome screen for new wallet creation
        onboardingState.currentStep = .welcome
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var onboardingState: OnboardingState
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        // If we reach onboarding, it means this is for a new wallet
        // ContentView already handles existing wallet detection
        NewWalletWelcomeView(onboardingState: onboardingState)
    }


}


// MARK: - New Wallet Welcome View

struct NewWalletWelcomeView: View {
    @ObservedObject var onboardingState: OnboardingState

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.3), radius: 20)

                VStack(spacing: 8) {
                    Text("Lumen")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Bright, simple payments.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Features
            VStack(spacing: 24) {
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Secure by Design",
                    description: "Your wallet is protected by biometric authentication and iCloud Keychain"
                )

                FeatureRow(
                    icon: "bolt.fill",
                    title: "Lightning Fast",
                    description: "Send and receive Bitcoin payments instantly with Lightning Network"
                )

                FeatureRow(
                    icon: "icloud.fill",
                    title: "Auto Recovery",
                    description: "Seamlessly restore your wallet on any device with your Apple ID"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Continue Button
            Button(action: {
                onboardingState.currentStep = .walletChoice
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Biometric Setup Step

struct BiometricSetupView: View {
    @ObservedObject var onboardingState: OnboardingState
    @State private var biometricType: BiometricManager.BiometricType = .none
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Biometric Icon
            VStack(spacing: 20) {
                Image(systemName: biometricIconName)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Enable \(biometricType.displayName)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Secure your wallet with biometric authentication")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Benefits
            VStack(spacing: 20) {
                BenefitRow(
                    icon: "checkmark.shield.fill",
                    text: "Your wallet stays secure even if your device is lost"
                )
                
                BenefitRow(
                    icon: "hand.raised.fill",
                    text: "No one else can access your funds"
                )
                
                BenefitRow(
                    icon: "speedometer",
                    text: "Quick and convenient access to your wallet"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Continue Button
            Button(action: {
                onboardingState.currentStep = .walletInitialization
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .onAppear {
            biometricType = BiometricManager.shared.availableBiometricType()
        }
    }
    
    private var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
}

// MARK: - Wallet Initialization Step

struct WalletInitializationView: View {
    @ObservedObject var onboardingState: OnboardingState
    @StateObject private var walletManager = WalletManager.shared
    @State private var initializationStarted = false

    var body: some View {
        // Show import view if this is an import flow
        if onboardingState.isImportFlow {
            ImportSeedView(onboardingState: onboardingState)
        } else {
            // Show normal wallet creation view
            WalletCreationView(onboardingState: onboardingState, walletManager: walletManager, initializationStarted: $initializationStarted)
        }
    }
}

// MARK: - Wallet Creation View

struct WalletCreationView: View {
    @ObservedObject var onboardingState: OnboardingState
    @ObservedObject var walletManager: WalletManager
    @Binding var initializationStarted: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Loading Animation
            VStack(spacing: 20) {
                if walletManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if walletManager.isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(statusDescription)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Error Message
            if let errorMessage = walletManager.errorMessage {
                VStack(spacing: 16) {
                    Text("Something went wrong")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Try Again") {
                            Task {
                                await walletManager.initializeWallet()
                            }
                        }
                        .buttonStyle(.bordered)

                        Button("Reset Wallet") {
                            Task {
                                try? await walletManager.deleteWalletFromKeychain()
                                await walletManager.initializeWallet()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Continue Button (only show when connected)
            if walletManager.isConnected {
                Button(action: {
                    // Check if currency is already selected
                    if CurrencyManager.shared.selectedCurrency != nil {
                        // Currency already selected, go to completed
                        onboardingState.currentStep = .completed
                    } else {
                        // Need to select currency first
                        onboardingState.currentStep = .currencySelection
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if !initializationStarted {
                initializationStarted = true
                Task {
                    await walletManager.initializeWallet()
                }
            }
        }
    }
    
    private var statusTitle: String {
        if walletManager.isLoading {
            return "Setting up your wallet..."
        } else if walletManager.isConnected {
            return "Wallet Ready!"
        } else {
            return "Setup Failed"
        }
    }
    
    private var statusDescription: String {
        if walletManager.isLoading {
            return "Please wait while we securely initialize your Lightning wallet"
        } else if walletManager.isConnected {
            return "Your Lumen wallet is ready to send and receive payments"
        } else {
            return "We encountered an issue setting up your wallet"
        }
    }
}

// MARK: - Completed Step

struct CompletedView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                VStack(spacing: 8) {
                    Text(L("welcome_to_lumen"))
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(L("your_wallet_is_ready"))
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Continue Button to finish onboarding
            Button(action: {
                // Post notification to signal onboarding completion
                NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            }) {
                Text(L("start_using_lumen"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding State

class OnboardingState: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isImportFlow: Bool = false
    
    enum OnboardingStep {
        case welcome
        case walletChoice
        case biometricSetup
        case walletInitialization
        case currencySelection
        case completed
    }
}

// MARK: - Currency Selection Step

struct CurrencySelectionView: View {
    @ObservedObject var onboardingState: OnboardingState
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""

    var filteredCurrencies: [FiatCurrency] {
        if searchText.isEmpty {
            return currencyManager.availableCurrencies
        } else {
            return currencyManager.availableCurrencies.filter { currency in
                currency.id.localizedCaseInsensitiveContains(searchText) ||
                currency.info.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)

                Text("Choose Your Currency")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Select your preferred currency for displaying Bitcoin values. You can change this later in settings.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Currency List
            VStack(spacing: 16) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search currencies...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)

                if currencyManager.isLoadingCurrencies {
                    ProgressView("Loading currencies...")
                        .frame(height: 200)
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(filteredCurrencies, id: \.id) { currency in
                                CurrencyGridItem(
                                    currency: currency,
                                    isSelected: currencyManager.selectedCurrency?.id == currency.id,
                                    onTap: {
                                        currencyManager.setSelectedCurrency(currency)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 300)
                }
            }

            Spacer()

            // Continue Button
            Button(action: {
                onboardingState.currentStep = .completed
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        currencyManager.selectedCurrency != nil ?
                        Color.yellow : Color.gray
                    )
                    .cornerRadius(12)
            }
            .disabled(currencyManager.selectedCurrency == nil)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Only load if we don't have currencies yet
            if currencyManager.availableCurrencies.isEmpty {
                Task {
                    await currencyManager.loadAvailableCurrencies(setDefaultIfNone: false)
                }
            }
        }
    }
}



// MARK: - Wallet Choice Step

struct WalletChoiceView: View {
    @ObservedObject var onboardingState: OnboardingState

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Header
            VStack(spacing: 20) {
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    Text("Set Up Your Wallet")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Choose how you'd like to get started")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Choice Buttons
            VStack(spacing: 16) {
                // Create New Wallet Button
                Button(action: {
                    onboardingState.currentStep = .biometricSetup
                }) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Create New Wallet")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Generate a new 24-word recovery phrase")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Import Existing Wallet Button
                Button(action: {
                    onboardingState.currentStep = .walletInitialization
                    // Set a flag to indicate this is an import flow
                    onboardingState.isImportFlow = true
                }) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.title2)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Existing Wallet")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Use your existing 12 or 24-word recovery phrase")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
