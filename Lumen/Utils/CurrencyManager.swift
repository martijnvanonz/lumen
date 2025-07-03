import Foundation
import BreezSDKLiquid

/// Manages currency preferences and BTC rate fetching
class CurrencyManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedCurrency: FiatCurrency?
    @Published var availableCurrencies: [FiatCurrency] = []
    @Published var currentRates: [Rate] = []
    @Published var isLoadingRates = false
    @Published var isLoadingCurrencies = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let selectedCurrencyKey = "selectedFiatCurrency"
    private var rateUpdateTimer: Timer?
    
    // MARK: - Singleton
    
    static let shared = CurrencyManager()
    
    private init() {
        loadSelectedCurrency()
    }
    
    // MARK: - Public Methods
    
    /// Load available currencies from Breez SDK
    func loadAvailableCurrencies(setDefaultIfNone: Bool = false) async {
        // Check if we already have currencies loaded
        if !availableCurrencies.isEmpty {
            return
        }

        await MainActor.run {
            isLoadingCurrencies = true
        }

        // Try to get SDK, but don't fail if it's not available yet
        guard let sdk = WalletManager.shared.sdk else {
            print("⚠️ SDK not available for loading currencies, will load fallback currencies")
            await loadFallbackCurrencies(setDefaultIfNone: setDefaultIfNone)
            return
        }

        do {
            let currencies = try sdk.listFiatCurrencies()

            await MainActor.run {
                self.availableCurrencies = currencies.sorted { $0.id < $1.id }
                self.isLoadingCurrencies = false

                // Only set default currency if explicitly requested
                if setDefaultIfNone && self.selectedCurrency == nil {
                    self.setDefaultCurrency()
                }
            }

            print("✅ Loaded \(currencies.count) fiat currencies from SDK")
        } catch {
            await MainActor.run {
                self.isLoadingCurrencies = false
            }
            print("❌ Failed to load fiat currencies from SDK: \(error)")
            // Load fallback currencies as backup
            await loadFallbackCurrencies(setDefaultIfNone: setDefaultIfNone)
        }
    }

    /// Load fallback currencies when SDK is not available
    private func loadFallbackCurrencies(setDefaultIfNone: Bool = false) async {
        let fallbackCurrencies = createFallbackCurrencies()

        await MainActor.run {
            self.availableCurrencies = fallbackCurrencies
            self.isLoadingCurrencies = false

            // Only set default currency if explicitly requested
            if setDefaultIfNone && self.selectedCurrency == nil {
                self.setDefaultCurrency()
            }
        }

        print("✅ Loaded \(fallbackCurrencies.count) fallback currencies")
    }

    /// Create a list of common fallback currencies
    private func createFallbackCurrencies() -> [FiatCurrency] {
        let commonCurrencies = [
            ("usd", "US Dollar", 2),
            ("eur", "Euro", 2),
            ("gbp", "British Pound", 2),
            ("jpy", "Japanese Yen", 0),
            ("cad", "Canadian Dollar", 2),
            ("aud", "Australian Dollar", 2),
            ("chf", "Swiss Franc", 2),
            ("cny", "Chinese Yuan", 2),
            ("sek", "Swedish Krona", 2),
            ("nok", "Norwegian Krone", 2),
            ("dkk", "Danish Krone", 2),
            ("pln", "Polish Zloty", 2),
            ("czk", "Czech Koruna", 2),
            ("huf", "Hungarian Forint", 0),
            ("rub", "Russian Ruble", 2),
            ("brl", "Brazilian Real", 2),
            ("mxn", "Mexican Peso", 2),
            ("inr", "Indian Rupee", 2),
            ("krw", "South Korean Won", 0),
            ("sgd", "Singapore Dollar", 2),
            ("hkd", "Hong Kong Dollar", 2),
            ("nzd", "New Zealand Dollar", 2),
            ("zar", "South African Rand", 2),
            ("try", "Turkish Lira", 2),
            ("ils", "Israeli Shekel", 2),
            ("aed", "UAE Dirham", 2),
            ("sar", "Saudi Riyal", 2),
            ("thb", "Thai Baht", 2),
            ("myr", "Malaysian Ringgit", 2),
            ("php", "Philippine Peso", 2)
        ]

        return commonCurrencies.map { (id, name, fractionSize) in
            FiatCurrency(
                id: id,
                info: CurrencyInfo(
                    name: name,
                    fractionSize: UInt32(fractionSize),
                    spacing: nil,
                    symbol: nil,
                    uniqSymbol: nil,
                    localizedName: [],
                    localeOverrides: []
                )
            )
        }.sorted { $0.id < $1.id }
    }

    /// Fetch current BTC rates from Breez SDK
    func fetchCurrentRates() async {
        guard let sdk = WalletManager.shared.sdk else {
            print("❌ SDK not available for fetching rates")
            return
        }
        
        await MainActor.run {
            isLoadingRates = true
        }
        
        do {
            let rates = try sdk.fetchFiatRates()

            await MainActor.run {
                self.currentRates = rates
                self.isLoadingRates = false
            }

            print("✅ Fetched \(rates.count) BTC rates")

            // Debug: Print first few rates to check for invalid values
            for (index, rate) in rates.prefix(5).enumerated() {
                print("Rate \(index): \(rate.coin) = \(rate.value) (isFinite: \(rate.value.isFinite), isNaN: \(rate.value.isNaN))")
            }
        } catch {
            await MainActor.run {
                self.isLoadingRates = false
            }
            print("❌ Failed to fetch BTC rates: \(error)")
        }
    }
    
    /// Set the selected currency and save to UserDefaults
    func setSelectedCurrency(_ currency: FiatCurrency) {
        selectedCurrency = currency
        saveCurrencyToUserDefaults(currency)
        print("✅ Selected currency: \(currency.id)")
    }

    /// Clear the selected currency (used when creating new wallet)
    func clearSelectedCurrency() {
        selectedCurrency = nil
        userDefaults.removeObject(forKey: selectedCurrencyKey)
        print("🗑️ Cleared selected currency")
    }

    /// Reload currencies from SDK when it becomes available
    /// This replaces fallback currencies with real SDK currencies
    func reloadCurrenciesFromSDK(setDefaultIfNone: Bool = false) async {
        guard let sdk = WalletManager.shared.sdk else {
            print("⚠️ SDK still not available for reloading currencies")
            return
        }

        print("🔄 Reloading currencies from SDK...")

        do {
            let currencies = try sdk.listFiatCurrencies()

            await MainActor.run {
                // Store the currently selected currency ID to restore it
                let selectedCurrencyId = self.selectedCurrency?.id

                // Update available currencies
                self.availableCurrencies = currencies.sorted { $0.id < $1.id }

                // Restore selected currency if it exists in the new list
                if let selectedId = selectedCurrencyId,
                   let restoredCurrency = currencies.first(where: { $0.id == selectedId }) {
                    self.selectedCurrency = restoredCurrency
                } else if setDefaultIfNone && self.selectedCurrency == nil {
                    // Only set default if explicitly requested
                    self.setDefaultCurrency()
                }
            }

            print("✅ Reloaded \(currencies.count) currencies from SDK")
        } catch {
            print("❌ Failed to reload currencies from SDK: \(error)")
        }
    }
    
    /// Get the current BTC rate for the selected currency
    func getCurrentRate() -> Double? {
        guard let selectedCurrency = selectedCurrency else { return nil }

        let rate = currentRates.first { $0.coin.uppercased() == selectedCurrency.id.uppercased() }?.value

        // Validate the rate is a valid number
        guard let validRate = rate,
              validRate > 0,
              validRate.isFinite,
              !validRate.isNaN else {
            return nil
        }

        return validRate
    }
    
    /// Convert satoshis to fiat amount using current rate
    func convertSatsToFiat(_ sats: UInt64) -> Double? {
        guard let rate = getCurrentRate(),
              rate > 0,
              rate.isFinite else { return nil }

        let btcAmount = Double(sats) / 100_000_000.0 // Convert sats to BTC
        let fiatAmount = btcAmount * rate

        // Ensure the result is valid
        guard fiatAmount.isFinite && !fiatAmount.isNaN else { return nil }

        return fiatAmount
    }

    /// Format fiat amount with currency symbol
    func formatFiatAmount(_ amount: Double) -> String {
        guard let selectedCurrency = selectedCurrency,
              amount.isFinite && !amount.isNaN else { return "" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.id
        formatter.maximumFractionDigits = Int(selectedCurrency.info.fractionSize)

        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    /// Start periodic rate updates
    func startRateUpdates() {
        stopRateUpdates() // Stop any existing timer
        
        // Update rates every 5 minutes
        rateUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.fetchCurrentRates()
            }
        }
        
        // Initial fetch
        Task {
            await fetchCurrentRates()
        }
    }
    
    /// Stop periodic rate updates
    func stopRateUpdates() {
        rateUpdateTimer?.invalidate()
        rateUpdateTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func loadSelectedCurrency() {
        guard let currencyId = userDefaults.string(forKey: selectedCurrencyKey) else {
            return
        }

        // We'll set the selected currency after loading available currencies
        // by matching the stored currency ID
        Task {
            await loadAvailableCurrencies()
            await MainActor.run {
                if let currency = self.availableCurrencies.first(where: { $0.id == currencyId }) {
                    self.selectedCurrency = currency
                }
            }
        }
    }

    private func saveCurrencyToUserDefaults(_ currency: FiatCurrency) {
        userDefaults.set(currency.id, forKey: selectedCurrencyKey)
    }
    
    private func setDefaultCurrency() {
        // Try to find user's locale currency first
        let localeCurrencyCode = Locale.current.currency?.identifier.uppercased()
        
        var defaultCurrency: FiatCurrency?
        
        // First try to match locale currency
        if let currencyCode = localeCurrencyCode {
            defaultCurrency = availableCurrencies.first { $0.id.uppercased() == currencyCode }
        }
        
        // Fallback to common currencies
        if defaultCurrency == nil {
            let fallbackCurrencies = ["USD", "EUR", "GBP", "JPY"]
            for currencyCode in fallbackCurrencies {
                if let currency = availableCurrencies.first(where: { $0.id.uppercased() == currencyCode }) {
                    defaultCurrency = currency
                    break
                }
            }
        }
        
        // Final fallback to first available currency
        if defaultCurrency == nil {
            defaultCurrency = availableCurrencies.first
        }
        
        if let currency = defaultCurrency {
            setSelectedCurrency(currency)
        }
    }
}


