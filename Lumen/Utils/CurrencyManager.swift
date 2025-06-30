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
    func loadAvailableCurrencies() async {
        guard let sdk = WalletManager.shared.sdk else {
            print("❌ SDK not available for loading currencies")
            return
        }
        
        await MainActor.run {
            isLoadingCurrencies = true
        }
        
        do {
            let currencies = try sdk.listFiatCurrencies()
            
            await MainActor.run {
                self.availableCurrencies = currencies.sorted { $0.id < $1.id }
                self.isLoadingCurrencies = false
                
                // Set default currency if none selected
                if self.selectedCurrency == nil {
                    self.setDefaultCurrency()
                }
            }
            
            print("✅ Loaded \(currencies.count) fiat currencies")
        } catch {
            await MainActor.run {
                self.isLoadingCurrencies = false
            }
            print("❌ Failed to load fiat currencies: \(error)")
        }
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


