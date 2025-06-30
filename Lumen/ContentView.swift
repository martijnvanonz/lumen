import SwiftUI

struct ContentView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showOnboarding = true

    var body: some View {
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
        .onAppear {
            checkWalletStatus()
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
}

#Preview {
    ContentView()
}
