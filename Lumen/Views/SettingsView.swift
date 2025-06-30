import SwiftUI
import BreezSDKLiquid

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingCurrencySelection = false
    @State private var showingLogoutConfirmation = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationView {
            List {
                // Currency Section
                Section("Display Currency") {
                    Button(action: {
                        showingCurrencySelection = true
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.yellow)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Currency")
                                    .foregroundColor(.primary)
                                
                                if let selectedCurrency = currencyManager.selectedCurrency {
                                    Text("\(selectedCurrency.id.uppercased()) - \(selectedCurrency.info.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // App Information Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Version")
                                .foregroundColor(.primary)
                            
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Network Section
                Section("Network") {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.green)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Network")
                                .foregroundColor(.primary)

                            Text("Liquid Network")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }

                // Wallet Management Section
                Section("Wallet Management") {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Logout Wallet")
                                    .foregroundColor(.red)

                                Text("Disconnect and return to onboarding")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isLoggingOut {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCurrencySelection) {
            CurrencySelectionSettingsView()
        }
        .alert("Logout Wallet", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to logout? This will disconnect your wallet and return you to the onboarding screen. Your wallet will remain safely stored in iCloud Keychain.")
        }
    }

    // MARK: - Private Methods

    private func performLogout() {
        isLoggingOut = true

        Task {
            do {
                // Reset the wallet (disconnect and clear state)
                try await walletManager.resetWallet()

                await MainActor.run {
                    isLoggingOut = false
                    dismiss()

                    // Post notification to trigger return to onboarding
                    NotificationCenter.default.post(name: .walletLoggedOut, object: nil)
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    // Handle error - could show an error alert here
                    print("❌ Logout failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Currency Selection Settings View

struct CurrencySelectionSettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search currencies...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Currency List
                if currencyManager.isLoadingCurrencies {
                    Spacer()
                    ProgressView("Loading currencies...")
                    Spacer()
                } else {
                    List(filteredCurrencies, id: \.id) { currency in
                        Button(action: {
                            currencyManager.setSelectedCurrency(currency)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currency.id.uppercased())
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(currency.info.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if currencyManager.selectedCurrency?.id == currency.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.yellow)
                                        .font(.headline)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await currencyManager.loadAvailableCurrencies()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

#Preview("Currency Selection") {
    CurrencySelectionSettingsView()
}
