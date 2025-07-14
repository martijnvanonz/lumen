import Foundation
import SwiftUI
import BreezSDKLiquid
import Web3Core

/// ViewModel for wallet UI state management
/// This extracts UI-related state from WalletManager and provides
/// a clean MVVM interface for wallet views.
@MainActor
class WalletViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Connection state
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var connectionError: String?
    
    /// Wallet state
    @Published var balance: UInt64 = 0
    @Published var isLoadingBalance = false
    @Published var balanceError: String?
    
    /// Payment state
    @Published var payments: [Payment] = []
    @Published var isLoadingPayments = false
    @Published var paymentsError: String?
    
    /// General loading and error state
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    /// Wallet info
    @Published var walletInfo: GetInfoResponse?
    @Published var isLoadingWalletInfo = false
    
    // MARK: - Dependencies
    
    private let walletService: WalletServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private var repository: WalletRepositoryProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - Initialization
    
    init(
        walletService: WalletServiceProtocol,
        paymentService: PaymentServiceProtocol,
        repository: WalletRepositoryProtocol,
        errorHandler: ErrorHandler = ErrorHandler.shared
    ) {
        self.walletService = walletService
        self.paymentService = paymentService
        self.repository = repository
        self.errorHandler = errorHandler
        
        // Set up error handling
        setupErrorHandling()
    }
    
    // MARK: - Computed Properties
    
    /// Check if wallet exists in storage
    var hasWallet: Bool {
        repository.hasWallet
    }
    
    /// Check if user is logged in
    var isLoggedIn: Bool {
        repository.isLoggedIn
    }
    
    /// Check if onboarding is completed
    var hasCompletedOnboarding: Bool {
        repository.hasCompletedOnboarding
    }
    
    /// Formatted balance string
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: balance)) ?? "\(balance)"
    }
    
    /// Check if any operation is in progress
    var isAnyOperationInProgress: Bool {
        return isLoading || isConnecting || isLoadingBalance || isLoadingPayments || isLoadingWalletInfo
    }
    
    // MARK: - Wallet Lifecycle
    
    /// Initialize wallet (create new or restore existing)
    func initializeWallet() async {
        isLoading = true
        clearErrors()
        
        do {
            let mnemonic: String
            
            if repository.mnemonicExists() {
                // Restore existing wallet
                mnemonic = try repository.retrieveMnemonic()
                print("🔄 Restoring existing wallet")
            } else {
                // Create new wallet
                mnemonic = try generateNewMnemonic()
                try repository.storeMnemonic(mnemonic)
                print("✨ Created new wallet")
            }
            
            // Connect to wallet service
            try await connectWallet(mnemonic: mnemonic)
            
            // Update repository state
            repository.hasWallet = true
            repository.isLoggedIn = true
            
            // Load initial data
            await loadWalletData()
            
        } catch {
            handleError(error, context: "Wallet initialization")
        }
        
        isLoading = false
    }
    
    /// Import wallet from existing mnemonic
    func importWallet(mnemonic: String) async {
        isLoading = true
        clearErrors()
        
        do {
            // Validate mnemonic
            let normalizedMnemonic = SeedPhraseValidator.normalizeSeedPhrase(mnemonic)
            let validation = SeedPhraseValidator.validateSeedPhrase(normalizedMnemonic)
            
            guard validation.isValid else {
                throw WalletViewModelError.invalidMnemonic(validation.errorMessage)
            }
            
            // Store mnemonic
            try repository.storeMnemonic(normalizedMnemonic)
            
            // Connect to wallet service
            try await connectWallet(mnemonic: normalizedMnemonic)
            
            // Update repository state
            repository.hasWallet = true
            repository.isLoggedIn = true
            
            // Load initial data
            await loadWalletData()
            
        } catch {
            handleError(error, context: "Wallet import")
        }
        
        isLoading = false
    }
    
    /// Initialize from cached seed (fast startup)
    func initializeFromCache() async -> Bool {
        guard repository.isSeedCached() else {
            return false
        }
        
        isLoading = true
        clearErrors()
        
        do {
            let cachedSeed = try repository.retrieveCachedSeed()
            try await connectWallet(mnemonic: cachedSeed)
            
            repository.hasWallet = true
            repository.isLoggedIn = true
            
            await loadWalletData()
            
            isLoading = false
            return true
            
        } catch {
            isLoading = false
            print("❌ Failed to initialize from cache: \(error)")
            return false
        }
    }
    
    // MARK: - Connection Management
    
    private func connectWallet(mnemonic: String) async throws {
        isConnecting = true
        connectionError = nil
        
        do {
            try await walletService.connect(mnemonic: mnemonic)
            isConnected = true
            
            // Cache seed for quick access
            try repository.cacheSeed(mnemonic)
            
        } catch {
            isConnected = false
            connectionError = error.localizedDescription
            throw error
        }
        
        isConnecting = false
    }
    
    /// Disconnect wallet
    func disconnect() async {
        do {
            try await walletService.disconnect()
            isConnected = false
            
            // Clear cached seed
            try repository.clearCachedSeed()
            
        } catch {
            handleError(error, context: "Wallet disconnect")
        }
    }
    
    /// Logout (disconnect but keep wallet)
    func logout() async {
        await disconnect()
        repository.clearSessionData()
    }
    
    /// Reset wallet (delete all data)
    func resetWallet() async {
        await disconnect()
        
        do {
            try repository.resetWalletData()
            clearAllState()
        } catch {
            handleError(error, context: "Wallet reset")
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all wallet data
    func loadWalletData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshBalance() }
            group.addTask { await self.refreshPayments() }
            group.addTask { await self.refreshWalletInfo() }
        }
    }
    
    /// Refresh wallet balance
    func refreshBalance() async {
        guard walletService.isConnected else { return }
        
        isLoadingBalance = true
        balanceError = nil
        
        do {
            balance = try await walletService.getBalance()
        } catch {
            balanceError = error.localizedDescription
            handleError(error, context: "Balance refresh")
        }
        
        isLoadingBalance = false
    }
    
    /// Refresh payment history
    func refreshPayments() async {
        guard walletService.isConnected else { return }

        isLoadingPayments = true
        paymentsError = nil

        do {
            payments = try await walletService.getPaymentHistory()
        } catch {
            paymentsError = error.localizedDescription
            handleError(error, context: "Payments refresh")
        }

        isLoadingPayments = false
    }

    // MARK: - Payment Operations

    /// Parse payment input string
    func parsePaymentInput(_ input: String) async throws -> InputType {
        guard walletService.isConnected else {
            throw WalletViewModelError.walletNotConnected
        }

        return try await walletService.parsePaymentInput(input)
    }

    /// Prepare payment from input type
    func preparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        guard walletService.isConnected else {
            throw WalletViewModelError.walletNotConnected
        }

        return try await paymentService.preparePayment(from: inputType)
    }

    /// Send prepared payment
    func sendPayment(preparedPayment: PrepareSendResponse) async throws -> SendPaymentResponse {
        guard walletService.isConnected else {
            throw WalletViewModelError.walletNotConnected
        }

        let result = try await paymentService.executePayment(preparedPayment)

        // Refresh data after successful payment
        await refreshBalance()
        await refreshPayments()

        return result
    }

    /// Get payment info from parsed input type
    func getPaymentInfo(from inputType: InputType) -> PaymentInputInfo {
        // Convert InputType to PaymentInputInfo
        // This is a simplified implementation - in production you'd extract more details
        switch inputType {
        case .bolt11(let invoice):
            return PaymentInputInfo(
                type: .bolt11,
                amount: invoice.amountMsat.map { $0 / 1000 }, // Convert msat to sat
                description: invoice.description,
                destination: invoice.bolt11,
                expiry: Date(timeIntervalSince1970: TimeInterval(invoice.expiry)),
                isExpired: invoice.expiry < UInt64(Date().timeIntervalSince1970)
            )
        case .lnUrlPay(let data, let bip353Address):
            return PaymentInputInfo(
                type: .lnUrlPay,
                description: data.commentAllowed > 0 ? "LNURL Pay" : nil,
                destination: data.callback,
                minAmount: data.minSendable / 1000, // Convert msat to sat
                maxAmount: data.maxSendable / 1000
            )
        case .bitcoinAddress(let address):
            return PaymentInputInfo(
                type: .bitcoinAddress,
                destination: address.address
            )
        case .liquidAddress(let address):
            return PaymentInputInfo(
                type: .liquidAddress,
                destination: address.address
            )
        case .bolt12Offer(let offer, let bip353Address):
            return PaymentInputInfo(
                type: .bolt12Offer,
                description: offer.description,
                destination: bip353Address ?? "BOLT12 Offer"
            )
        case .nodeId(let nodeId):
            return PaymentInputInfo(
                type: .nodeId,
                destination: nodeId
            )
        case .url(let url):
            return PaymentInputInfo(
                type: .url,
                destination: url
            )
        case .lnUrlWithdraw(let data):
            return PaymentInputInfo(
                type: .lnUrlWithdraw,
                description: data.defaultDescription,
                destination: data.callback,
                minAmount: data.minWithdrawable / 1000,
                maxAmount: data.maxWithdrawable / 1000
            )
        case .lnUrlAuth(let data):
            return PaymentInputInfo(
                type: .lnUrlAuth,
                destination: data.url
            )
        case .lnUrlError(let data):
            return PaymentInputInfo(
                type: .unsupported,
                description: data.reason
            )
        }
    }
    
    /// Refresh wallet info
    func refreshWalletInfo() async {
        guard walletService.isConnected else { return }
        
        isLoadingWalletInfo = true
        
        do {
            walletInfo = try await walletService.getWalletInfo()
        } catch {
            handleError(error, context: "Wallet info refresh")
        }
        
        isLoadingWalletInfo = false
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
        // Observe error handler for global errors
        errorHandler.objectWillChange.sink { [weak self] in
            Task { @MainActor in
                self?.handleGlobalError()
            }
        }.store(in: &cancellables)
    }
    
    private func handleGlobalError() {
        if let currentError = errorHandler.currentError {
            errorMessage = currentError.message
            showingError = true
        }
    }
    
    // MARK: - Onboarding Management

    func markOnboardingCompleted() {
        repository.hasCompletedOnboarding = true
    }

    private func handleError(_ error: Error, context: String) {
        let appError = ErrorHandler.AppError.unknown(error.localizedDescription)
        errorMessage = appError.message
        showingError = true

        print("❌ \(context) error: \(error)")
    }
    
    private func clearErrors() {
        errorMessage = nil
        showingError = false
        connectionError = nil
        balanceError = nil
        paymentsError = nil
    }
    
    private func clearAllState() {
        isConnected = false
        balance = 0
        payments = []
        walletInfo = nil
        clearErrors()
    }
    
    // MARK: - Helper Methods
    
    private func generateNewMnemonic() throws -> String {
        // This would use the same logic as WalletManager
        // For now, simplified implementation
        do {
            return try BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english) ?? ""
        } catch {
            throw WalletViewModelError.mnemonicGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - ViewModel Errors

enum WalletViewModelError: Error, LocalizedError {
    case invalidMnemonic(String)
    case mnemonicGenerationFailed(String)
    case connectionFailed(String)
    case dataLoadFailed(String)
    case walletNotConnected

    var errorDescription: String? {
        switch self {
        case .invalidMnemonic(let message):
            return "Invalid mnemonic: \(message)"
        case .mnemonicGenerationFailed(let message):
            return "Failed to generate mnemonic: \(message)"
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .dataLoadFailed(let message):
            return "Failed to load data: \(message)"
        case .walletNotConnected:
            return "Wallet is not connected"
        }
    }
}

// MARK: - Convenience Extensions

extension WalletViewModel {
    
    /// Create a configured instance with default dependencies
    static func create() -> WalletViewModel {
        let walletService = BreezWalletService()
        let paymentService = DefaultPaymentService(walletService: walletService)
        let repository = DefaultWalletRepository()
        
        return WalletViewModel(
            walletService: walletService,
            paymentService: paymentService,
            repository: repository
        )
    }
}

// MARK: - Required Import

import Combine
