import SwiftUI

struct ContentView: View {
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var lifecycleManager = AppLifecycleManager.shared
    @State private var showOnboarding = true
    @State private var isCheckingWalletStatus = false

    var body: some View {
        ZStack {
            Group {
                if lifecycleManager.requiresAuthentication && !showOnboarding {
                    // Show authentication screen when required
                    AuthenticationRequiredView()
                } else if showOnboarding {
                    OnboardingView()
                } else {
                    WalletView()
                }
            }
            .errorAlert()

            // Overlay for offline mode
            if !networkMonitor.isConnected {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                OfflineModeView()
            }
        }
        .onAppear {
            checkWalletStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .walletLoggedOut)) { _ in
            handleWalletLogout()
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
            handleOnboardingCompleted()
        }
        .onChange(of: lifecycleManager.requiresAuthentication) { _, requiresAuth in
            if !requiresAuth && walletManager.isConnected {
                showOnboarding = false
            }
        }
    }

    private func checkWalletStatus() {
        // Prevent multiple concurrent checks
        guard !isCheckingWalletStatus else { return }
        isCheckingWalletStatus = true
        defer { isCheckingWalletStatus = false }

        // Check if user has completed onboarding (has wallet in keychain or UserDefaults)
        let hasExistingWallet = walletManager.hasWallet || KeychainManager.shared.mnemonicExists()

        if hasExistingWallet {
            // User has completed onboarding - never show onboarding again
            showOnboarding = false

            if walletManager.isConnected {
                // Already connected, stay in main wallet view
                return
            } else if walletManager.isLoggedIn {
                // User is logged in but not connected, try cache first then full initialization
                Task {
                    // First try quick initialization from cache
                    let cacheSuccess = await walletManager.initializeWalletFromCache()

                    if !cacheSuccess {
                        // Cache failed, require authentication but stay in wallet view
                        await MainActor.run {
                            lifecycleManager.requiresAuthentication = true
                        }
                    }
                }
            } else {
                // User has wallet but not logged in, require authentication
                lifecycleManager.requiresAuthentication = true
            }
        } else {
            // No existing wallet found, show onboarding for new users
            showOnboarding = true
        }
    }

    private func handleWalletLogout() {
        showOnboarding = true
    }

    private func handleOnboardingCompleted() {
        showOnboarding = false
    }
}

#Preview {
    ContentView()
}
