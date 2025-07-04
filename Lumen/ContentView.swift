import SwiftUI

struct ContentView: View {
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var lifecycleManager = AppLifecycleManager.shared
    @State private var showOnboarding = true

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
        // If user is logged in, try to connect automatically
        if walletManager.isLoggedIn {
            if walletManager.isConnected {
                // Already connected, go to main wallet view
                showOnboarding = false
            } else {
                // User is logged in but not connected, try cache first then full initialization
                Task {
                    // First try quick initialization from cache
                    let cacheSuccess = await walletManager.initializeWalletFromCache()

                    if cacheSuccess {
                        // Cache initialization successful
                        await MainActor.run {
                            showOnboarding = false
                        }
                    } else {
                        // Cache failed, let authentication flow handle it
                        await MainActor.run {
                            lifecycleManager.requiresAuthentication = true
                        }
                    }
                }
            }
        } else {
            // User not logged in, show onboarding
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
