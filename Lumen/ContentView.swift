import SwiftUI

struct ContentView: View {
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOnboarding = true

    var body: some View {
        ZStack {
            Group {
                if showOnboarding {
                    OnboardingView()
                        .onReceive(walletManager.$isConnected) { isConnected in
                            if isConnected {
                                showOnboarding = false
                            }
                        }
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
    }

    private func checkWalletStatus() {
        // If user is logged in, try to connect automatically
        if walletManager.isLoggedIn {
            if walletManager.isConnected {
                // Already connected, go to main wallet view
                showOnboarding = false
            } else {
                // User is logged in but not connected, initialize wallet automatically
                Task {
                    await walletManager.initializeWallet()
                    await MainActor.run {
                        if walletManager.isConnected {
                            showOnboarding = false
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
