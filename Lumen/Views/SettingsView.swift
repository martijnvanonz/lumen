import SwiftUI
import BreezSDKLiquid

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var btcMapService = BTCMapService.shared
    @State private var showingCurrencySelection = false
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteWalletConfirmation = false
    @State private var showingRefundView = false
    @State private var showingWalletInfo = false
    @State private var showingExportSeed = false
    @State private var isLoggingOut = false
    @State private var isDeletingWallet = false
    @State private var searchRadius: Double = 5.0
    
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

                // Bitcoin Places Section
                Section("Bitcoin Places") {
                    // Location toggle
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Nearby Places")
                                .foregroundColor(.primary)

                            Text(locationManager.locationStatusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { locationManager.isLocationEnabled },
                            set: { _ in locationManager.toggleLocationServices() }
                        ))
                        .disabled(!locationManager.hasLocationPermission && !locationManager.canRequestPermission)
                    }

                    // Search radius (only show if location is enabled)
                    if locationManager.isLocationEnabled {
                        HStack {
                            Image(systemName: "circle.dashed")
                                .foregroundColor(.green)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Search Radius")
                                    .foregroundColor(.primary)

                                Text("\(Int(searchRadius)) km")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Picker("Radius", selection: $searchRadius) {
                                Text("1 km").tag(1.0)
                                Text("2.5 km").tag(2.5)
                                Text("5 km").tag(5.0)
                                Text("10 km").tag(10.0)
                                Text("20 km").tag(20.0)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }

                    // Cache info and management
                    if let cacheStats = getCacheStats() {
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cache Status")
                                    .foregroundColor(.primary)

                                Text(cacheStats)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("Clear") {
                                BTCMapCache.shared.clearAllCache()
                                Task {
                                    await btcMapService.forceRefresh()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }

                // Refund Section (always available as backup)
                Section("Money Recovery") {
                    Button(action: {
                        showingRefundView = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Get Money Back")
                                    .foregroundColor(.primary)

                                Text("Recover funds from failed payments")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Wallet Details Section
                Section("Wallet Details") {
                    Button(action: {
                        showingWalletInfo = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Technical Information")
                                    .foregroundColor(.primary)

                                Text("View wallet status, limits, and network info")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
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
                        showingExportSeed = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export Seed Phrase")
                                    .foregroundColor(.primary)

                                Text("View your 24-word recovery phrase")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

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
                    .disabled(isLoggingOut || isDeletingWallet)
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        showingDeleteWalletConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete Wallet from Keychain")
                                    .foregroundColor(.red)

                                Text("Permanently remove wallet seed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if isDeletingWallet {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isLoggingOut || isDeletingWallet)
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
        .sheet(isPresented: $showingRefundView) {
            RefundView()
        }
        .sheet(isPresented: $showingWalletInfo) {
            WalletInfoView()
        }
        .sheet(isPresented: $showingExportSeed) {
            ExportSeedView()
        }
        .alert("Logout Wallet", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to logout? This will disconnect your wallet and return you to the onboarding screen. Your wallet will remain safely stored in iCloud Keychain.")
        }
        .alert("Delete Wallet from Keychain", isPresented: $showingDeleteWalletConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                performDeleteWallet()
            }
        } message: {
            Text("⚠️ WARNING: This will permanently delete your wallet seed from iCloud Keychain. You will lose access to your funds unless you have backed up your seed phrase elsewhere. This action cannot be undone.")
        }
    }

    // MARK: - Private Methods

    private func getCacheStats() -> String? {
        let stats = BTCMapCache.shared.getCacheStats()
        guard stats.snapshotSizeBytes > 0 || stats.detailsCount > 0 else { return nil }

        return "\(stats.detailsCount) places cached, \(String(format: "%.1f", stats.snapshotSizeMB)) MB"
    }

    private func performLogout() {
        isLoggingOut = true

        Task {
            // Use the new logout method that preserves keychain
            await walletManager.logout()

            await MainActor.run {
                isLoggingOut = false
                dismiss()

                // Post notification to trigger return to onboarding
                NotificationCenter.default.post(name: .walletLoggedOut, object: nil)
            }
        }
    }

    private func performDeleteWallet() {
        isDeletingWallet = true

        Task {
            do {
                // Permanently delete wallet from keychain
                try await walletManager.deleteWalletFromKeychain()

                await MainActor.run {
                    isDeletingWallet = false
                    dismiss()

                    // Post notification to trigger return to onboarding
                    NotificationCenter.default.post(name: .walletLoggedOut, object: nil)
                }
            } catch {
                await MainActor.run {
                    isDeletingWallet = false
                    // Handle error - could show an error alert here
                    print("❌ Delete wallet failed: \(error)")
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
                
                // Currency Grid
                if currencyManager.isLoadingCurrencies {
                    Spacer()
                    ProgressView("Loading currencies...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                            ForEach(filteredCurrencies, id: \.id) { currency in
                                CurrencyGridItem(
                                    currency: currency,
                                    isSelected: currencyManager.selectedCurrency?.id == currency.id,
                                    onTap: {
                                        currencyManager.setSelectedCurrency(currency)
                                        dismiss()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
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
            // Only load if we don't have currencies yet
            if currencyManager.availableCurrencies.isEmpty {
                Task {
                    await currencyManager.loadAvailableCurrencies(setDefaultIfNone: true)
                }
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
