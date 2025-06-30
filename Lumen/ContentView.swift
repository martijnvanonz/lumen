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
    }

    private func checkWalletStatus() {
        // Check if user is logged in and wallet is connected
        if walletManager.isLoggedIn && walletManager.isConnected {
            showOnboarding = false
        } else {
            // Show onboarding for wallet setup/recovery choice
            // The onboarding flow will handle existing wallet detection
            showOnboarding = true
        }
    }

    private func handleWalletLogout() {
        showOnboarding = true
    }
}

#Preview {
    ContentView()
}
