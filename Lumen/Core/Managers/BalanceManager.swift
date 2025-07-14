import Foundation
import BreezSDKLiquid

/// Manages wallet balance updates and monitoring
/// Extracted from WalletManager to provide focused balance management
@MainActor
class BalanceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var balance: UInt64 = 0
    @Published var isLoadingBalance = false
    @Published var balanceError: String?
    
    // MARK: - Dependencies
    
    private let walletService: WalletServiceProtocol
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Private Properties
    
    private var balanceUpdateTimer: Timer?
    private let balanceUpdateInterval: TimeInterval = 30.0 // Update every 30 seconds
    
    // MARK: - Initialization
    
    init(walletService: WalletServiceProtocol) {
        self.walletService = walletService
    }
    
    deinit {
        // Note: Cannot call async methods in deinit
        // Balance updates will be stopped when the timer is deallocated
        balanceUpdateTimer?.invalidate()
    }
    
    // MARK: - Balance Management
    
    /// Update the wallet balance from the service
    func updateBalance() async {
        guard walletService.isConnected else {
            print("⚠️ Cannot update balance - wallet not connected")
            return
        }
        
        isLoadingBalance = true
        balanceError = nil
        
        do {
            let walletInfo = try await walletService.getWalletInfo()
            balance = walletInfo.walletInfo.balanceSat
            print("💰 Balance updated: \(balance) sats")
        } catch {
            balanceError = error.localizedDescription
            errorHandler.logError(.wallet(.balanceUpdateFailed), context: "Balance update")
            print("❌ Failed to update balance: \(error)")
        }
        
        isLoadingBalance = false
    }
    
    /// Start automatic balance updates
    func startBalanceUpdates() {
        guard walletService.isConnected else {
            print("⚠️ Cannot start balance updates - wallet not connected")
            return
        }
        
        stopBalanceUpdates() // Stop any existing timer
        
        balanceUpdateTimer = Timer.scheduledTimer(withTimeInterval: balanceUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateBalance()
            }
        }
        
        print("⏰ Started automatic balance updates every \(balanceUpdateInterval) seconds")
    }
    
    /// Stop automatic balance updates
    func stopBalanceUpdates() {
        balanceUpdateTimer?.invalidate()
        balanceUpdateTimer = nil
        print("⏹️ Stopped automatic balance updates")
    }
    
    /// Force refresh the balance immediately
    func refreshBalance() async {
        await updateBalance()
    }
    
    /// Get formatted balance string
    func getFormattedBalance() -> String {
        return NumberFormatter.satsFormatter.string(from: NSNumber(value: balance)) ?? "0"
    }
    
    /// Get balance in BTC
    func getBalanceInBTC() -> Double {
        return Double(balance) / 100_000_000.0
    }
    
    /// Get balance in selected fiat currency
    func getBalanceInFiat() -> Double? {
        guard let selectedCurrency = CurrencyManager.shared.selectedCurrency,
              let rate = CurrencyManager.shared.getCurrentRate() else {
            return nil
        }
        
        let btcAmount = getBalanceInBTC()
        return btcAmount * rate
    }
    
    /// Get formatted balance in selected fiat currency
    func getFormattedFiatBalance() -> String? {
        guard let fiatBalance = getBalanceInFiat(),
              let selectedCurrency = CurrencyManager.shared.selectedCurrency else {
            return nil
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.id
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: fiatBalance))
    }
    
    /// Check if balance is sufficient for a payment amount
    func hasSufficientBalance(for amountSats: UInt64) -> Bool {
        return balance >= amountSats
    }
    
    /// Get available balance after accounting for fees
    func getAvailableBalance(withFeeReserve feeReserveSats: UInt64 = 1000) -> UInt64 {
        let feeReserve: UInt64 = 1000 // Reserve 1000 sats for fees
        guard balance > feeReserve else { return 0 }
        return balance - feeReserveSats
    }
    
    /// Reset balance to zero (used during logout/reset)
    func resetBalance() {
        balance = 0
        balanceError = nil
        stopBalanceUpdates()
        print("🔄 Balance reset to zero")
    }
}

// MARK: - Balance Validation

extension BalanceManager {
    
    /// Validate if a payment amount is valid given current balance
    func validatePaymentAmount(_ amountSats: UInt64, estimatedFeeSats: UInt64 = 0) -> BalanceValidationResult {
        let totalRequired = amountSats + estimatedFeeSats
        
        if amountSats == 0 {
            return .invalid("Amount must be greater than zero")
        }
        
        if totalRequired > balance {
            let shortfall = totalRequired - balance
            return .insufficient("Insufficient balance. Need \(shortfall) more sats")
        }
        
        if amountSats > AppConstants.Limits.maxPaymentAmount {
            return .invalid("Amount exceeds maximum payment limit")
        }
        
        if amountSats < AppConstants.Limits.minPaymentAmount {
            return .invalid("Amount below minimum payment limit")
        }
        
        return .valid
    }
}

// MARK: - Supporting Types

enum BalanceValidationResult {
    case valid
    case invalid(String)
    case insufficient(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid, .insufficient:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message), .insufficient(let message):
            return message
        }
    }
}

// MARK: - NumberFormatter Extension
// Note: satsFormatter is already defined in PaymentService
