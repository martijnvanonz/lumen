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
        // Check if wallet is already connected
        if walletManager.isConnected {
            showOnboarding = false
        } else {
            // Check if we have a mnemonic stored (returning user)
            let keychainManager = KeychainManager.shared
            if keychainManager.mnemonicExists() {
                // Try to initialize wallet automatically
                Task {
                    await walletManager.initializeWallet()
                }
            }
        }
    }

    private func handleWalletLogout() {
        showOnboarding = true
    }
}

#Preview {
    ContentView()
}
