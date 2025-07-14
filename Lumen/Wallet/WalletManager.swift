import Foundation
import SwiftUI
import BreezSDKLiquid
import Web3Core

/// Manages the Breez SDK Liquid wallet integration
/// Refactored to coordinate between specialized managers instead of handling everything directly
class WalletManager: ObservableObject {

    // MARK: - Published Properties (Delegated to Managers)

    @Published var isConnected = false
    @Published var balance: UInt64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var payments: [Payment] = []
    @Published var isLoadingPayments = false

    // MARK: - Specialized Managers

    @Published var connectionManager: ConnectionManager
    @Published var balanceManager: BalanceManager
    @Published var transactionManager: TransactionManager
    @Published var stateManager: WalletStateManager

    // MARK: - Services

    internal let walletService: WalletServiceProtocol
    private let paymentService: PaymentServiceProtocol
    private let repository: DefaultWalletRepository
    private let eventHandler = PaymentEventHandler.shared
    private let errorHandler = ErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared

    // MARK: - Singleton

    static let shared = WalletManager()

    private init() {
        // Initialize services with dependency injection
        self.repository = DefaultWalletRepository()
        self.walletService = BreezWalletService()
        self.paymentService = DefaultPaymentService(walletService: walletService)

        // Initialize specialized managers
        self.connectionManager = ConnectionManager(walletService: walletService, repository: repository)
        self.balanceManager = BalanceManager(walletService: walletService)
        self.transactionManager = TransactionManager(paymentService: paymentService)
        self.stateManager = WalletStateManager(repository: repository, walletService: walletService)

        // Set up manager coordination
        setupManagerCoordination()
    }

    // MARK: - Manager Coordination

    private func setupManagerCoordination() {
        // Sync published properties with manager states
        connectionManager.$isConnected.assign(to: &$isConnected)
        connectionManager.$isLoading.assign(to: &$isLoading)
        connectionManager.$connectionError.assign(to: &$errorMessage)

        balanceManager.$balance.assign(to: &$balance)

        transactionManager.$payments.assign(to: &$payments)
        transactionManager.$isLoadingPayments.assign(to: &$isLoadingPayments)
    }

    // MARK: - Computed Properties (Delegated to Managers)

    /// Check if a wallet exists in storage
    var hasWallet: Bool {
        get { stateManager.hasWallet }
        set { stateManager.setHasWallet(newValue) }
    }

    /// Check if user is currently logged in
    var isLoggedIn: Bool {
        get { stateManager.isLoggedIn }
        set { stateManager.setIsLoggedIn(newValue) }
    }

    // MARK: - Wallet Lifecycle (Delegated to Managers)

    /// Imports a wallet from an existing mnemonic phrase
    /// - Parameter mnemonic: The BIP39 mnemonic phrase to import
    /// - Throws: WalletError if import fails
    func importWallet(mnemonic: String) async throws {
        // Delegate to connection manager
        try await connectionManager.importWallet(mnemonic: mnemonic)

        // Update state after successful import
        stateManager.setHasWallet(true)
        stateManager.setIsLoggedIn(true)

        // Start managers
        await startManagers()

        print("✅ Wallet import coordinated successfully")
    }

    /// Initializes the wallet - checks for existing mnemonic or creates new one
    func initializeWallet() async {
        do {
            // Delegate to connection manager
            try await connectionManager.initializeWallet()

            // Update state after successful initialization
            stateManager.setHasWallet(true)
            stateManager.setIsLoggedIn(true)

            // Start managers
            await startManagers()

            // Load currencies but don't auto-select default during onboarding
            Task {
                await CurrencyManager.shared.reloadCurrenciesFromSDK(setDefaultIfNone: false)
                await CurrencyManager.shared.fetchCurrentRates()
                await CurrencyManager.shared.startRateUpdates()
            }

            print("✅ Wallet initialization coordinated successfully")

        } catch {
            errorHandler.handle(error, context: "Wallet initialization")
        }
    }

    /// Start all managers after successful connection
    private func startManagers() async {
        // Start balance updates
        await balanceManager.updateBalance()
        balanceManager.startBalanceUpdates()

        // Load payment history
        await transactionManager.loadPaymentHistory()
        transactionManager.startPaymentUpdates()

        // Update wallet info
        await stateManager.updateWalletInfo()

        print("🚀 All managers started successfully")
    }

    /// Shared initialization task to prevent concurrent initialization
    private var initializationTask: Task<Bool, Never>?

    /// Quick initialization using cached seed (no biometric auth required)
    func initializeWalletFromCache() async -> Bool {
        print("🔄 initializeWalletFromCache called from async context")

        // If already connected, no need to initialize again
        if isConnected {
            print("✅ Already connected - skipping initialization")
            return true
        }

        // If there's already an initialization task running, wait for it
        if let existingTask = initializationTask {
            print("⚠️ Wallet initialization already in progress - waiting for completion...")
            return await existingTask.value
        }

        // Create new initialization task
        let task = Task<Bool, Never> { @MainActor in
            return await self.performCacheInitialization()
        }

        initializationTask = task
        let result = await task.value
        initializationTask = nil

        return result
    }

    /// Perform the actual cache initialization
    @MainActor
    private func performCacheInitialization() async -> Bool {
        // Delegate to connection manager
        let success = await connectionManager.initializeFromCache()

        if success {
            // Update state after successful initialization
            stateManager.setHasWallet(true)
            stateManager.setIsLoggedIn(true)

            // Start managers
            await startManagers()

            // Load currencies
            Task {
                await CurrencyManager.shared.reloadCurrenciesFromSDK(setDefaultIfNone: false)
                await CurrencyManager.shared.fetchCurrentRates()
                await CurrencyManager.shared.startRateUpdates()
            }

            print("✅ Cache initialization coordinated successfully")
        }

        return success
    }
    
    // MARK: - Legacy Methods (Moved to Managers)
    // These methods are now handled by specialized managers
    
    // MARK: - Delegated Methods (Now handled by specialized managers)

    /// Updates the wallet balance (delegated to BalanceManager)
    func updateBalance() async {
        await balanceManager.updateBalance()
    }
    
    // MARK: - Payment Methods
    
    /// Prepares a payment for the given invoice
    func preparePayment(invoice: String) async throws -> PrepareSendResponse {
        return try await paymentService.preparePayment(invoice: invoice)
    }

    /// Sends a payment
    func sendPayment(prepareResponse: PrepareSendResponse) async throws -> SendPaymentResponse {
        let response = try await paymentService.executePayment(prepareResponse)

        // Update managers after successful payment
        await balanceManager.updateBalance()
        await transactionManager.loadPaymentHistory()

        return response
    }
    
    /// Prepares a receive payment (gets fee information)
    func prepareReceivePayment(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse {
        return try await paymentService.prepareReceive(amountSat: amountSat, description: description)
    }

    /// Receives a payment using prepared response
    func receivePayment(prepareResponse: PrepareReceiveResponse, description: String? = nil) async throws -> ReceivePaymentResponse {
        return try await paymentService.executeReceive(prepareResponse, description: description)
    }

    /// Legacy method for backward compatibility
    func receivePayment(amountSat: UInt64, description: String) async throws -> ReceivePaymentResponse {
        let prepared = try await prepareReceivePayment(amountSat: amountSat, description: description)
        return try await receivePayment(prepareResponse: prepared)
    }

    // MARK: - Add Bitcoin Methods

    /// Fetches onchain payment limits for receiving and sending
    func fetchOnchainLimits() async throws -> OnchainPaymentLimitsResponse {
        return try await walletService.fetchOnchainLimits()
    }

    /// Prepares an onchain receive payment
    func prepareReceiveOnchain(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse {
        return try await paymentService.prepareReceiveOnchain(payerAmountSat: payerAmountSat)
    }

    /// Executes an onchain receive payment
    func receiveOnchain(prepareResponse: PrepareReceiveResponse) async throws -> ReceivePaymentResponse {
        return try await paymentService.executeReceiveOnchain(prepareResponse, description: "Lumen onchain receive")
    }

    /// Prepares a liquid receive payment (alternative to lightning)
    func prepareReceiveLiquid(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse {
        return try await paymentService.prepareReceiveLiquid(payerAmountSat: payerAmountSat)
    }

    /// Executes a liquid receive payment
    func receiveLiquid(prepareResponse: PrepareReceiveResponse, description: String? = nil) async throws -> ReceivePaymentResponse {
        return try await paymentService.executeReceiveLiquid(prepareResponse, description: description ?? "")
    }

    /// Prepares a Bitcoin purchase via Moonpay
    func prepareBuyBitcoin(provider: BuyBitcoinProvider, amountSat: UInt64) async throws -> PrepareBuyBitcoinResponse {
        return try await paymentService.prepareBuyBitcoin(provider: provider, amountSat: amountSat)
    }

    /// Executes a Bitcoin purchase and returns the provider URL
    func buyBitcoin(prepareResponse: PrepareBuyBitcoinResponse, redirectUrl: String? = nil) async throws -> String {
        let response = try await paymentService.executeBuyBitcoin(prepareResponse, redirectUrl: redirectUrl ?? "")
        return response.url
    }
    
    // MARK: - Utility Methods

    /// Disconnects from the wallet service (delegated to ConnectionManager)
    func disconnect() async {
        await connectionManager.disconnect()

        // Stop manager updates
        balanceManager.stopBalanceUpdates()
        transactionManager.stopPaymentUpdates()
    }

    /// Resets the wallet by clearing stored mnemonic and disconnecting
    /// Use this to recover from corrupted wallet state
    func resetWallet() async throws {
        // Use the new deleteWalletFromKeychain method for consistency
        try await deleteWalletFromKeychain()

        print("✅ Wallet reset completed - ready for fresh initialization")
    }

    /// Gets the current wallet info
    func getWalletInfo() async throws -> GetInfoResponse {
        guard walletService.isConnected else {
            throw WalletError.notConnected
        }

        return try await walletService.getInfo()
    }

    // MARK: - State Management
    // Note: hasWallet and isLoggedIn computed properties are defined earlier in the class

    /// Logs out the user (clears in-memory state but preserves keychain)
    func logout() async {
        // Disconnect from wallet service
        await connectionManager.disconnect()

        // Clear manager states
        balanceManager.resetBalance()
        transactionManager.clearPaymentHistory()
        await stateManager.logout()

        // Notify that authentication state should be reset
        NotificationCenter.default.post(name: .authenticationStateReset, object: nil)

        print("✅ User logged out - wallet remains in keychain, secure cache cleared")
    }

    /// Permanently deletes wallet from keychain and clears all state
    func deleteWalletFromKeychain() async throws {
        // First logout to clear all state
        await logout()

        // Delete wallet using state manager
        try await stateManager.deleteWallet()

        print("✅ Wallet permanently deleted from keychain and secure cache cleared")
    }



    // MARK: - Payment Management

    /// Loads payment history (delegated to TransactionManager)
    func loadPaymentHistory() async {
        await transactionManager.loadPaymentHistory()

        // Update the PaymentEventHandler with real payment data
        await updatePaymentEventHandler(with: transactionManager.payments)
    }

    /// Updates the PaymentEventHandler with real payment data
    private func updatePaymentEventHandler(with payments: [Payment]) async {
        await MainActor.run {
            // Clear existing placeholder data
            eventHandler.recentPayments.removeAll()
            eventHandler.pendingPayments.removeAll()

            // Convert SDK payments to PaymentEventHandler format
            for payment in payments {
                let paymentInfo = createPaymentInfo(from: payment)

                // Add to appropriate list based on status
                switch payment.status {
                case .created, .pending:
                    eventHandler.pendingPayments.append(paymentInfo)
                case .complete:
                    eventHandler.recentPayments.append(paymentInfo)
                case .failed, .timedOut:
                    eventHandler.recentPayments.append(paymentInfo)
                case .refundable, .refundPending:
                    eventHandler.recentPayments.append(paymentInfo)
                case .waitingFeeAcceptance:
                    eventHandler.pendingPayments.append(paymentInfo)
                }
            }

            // Sort by timestamp (most recent first)
            eventHandler.recentPayments.sort { $0.timestamp > $1.timestamp }
            eventHandler.pendingPayments.sort { $0.timestamp > $1.timestamp }
        }
    }

    /// Converts SDK Payment to PaymentEventHandler.PaymentInfo
    private func createPaymentInfo(from payment: Payment) -> PaymentEventHandler.PaymentInfo {
        let direction: PaymentEventHandler.PaymentInfo.PaymentDirection =
            payment.paymentType == .receive ? .incoming : .outgoing

        let status: PaymentEventHandler.PaymentInfo.PaymentStatus
        switch payment.status {
        case .created, .pending:
            status = .pending
        case .complete:
            status = .succeeded
        case .failed, .timedOut:
            status = .failed
        case .refundable, .refundPending:
            status = .failed
        case .waitingFeeAcceptance:
            status = .waitingConfirmation
        }

        return PaymentEventHandler.PaymentInfo(
            paymentHash: payment.txId ?? UUID().uuidString,
            amountSat: payment.amountSat,
            direction: direction,
            status: status,
            timestamp: Date(timeIntervalSince1970: TimeInterval(payment.timestamp)),
            description: nil // Payment type doesn't have description property
        )
    }

    /// Gets payments with optional filtering
    func getPayments(
        filters: [PaymentType]? = nil,
        limit: UInt32? = nil,
        offset: UInt32? = nil
    ) async throws -> [Payment] {
        return try await paymentService.getPayments(filters: filters, limit: limit, offset: offset)
    }

    /// Gets recent payments (last 50)
    func getRecentPayments() async throws -> [Payment] {
        return try await getPayments(limit: 50)
    }

    /// Gets pending payments only
    func getPendingPayments() async throws -> [Payment] {
        let allPayments = try await getPayments()
        return allPayments.filter { $0.status == .pending }
    }

    /// Gets completed payments only
    func getCompletedPayments() async throws -> [Payment] {
        let allPayments = try await getPayments()
        return allPayments.filter { $0.status == .complete }
    }

    /// Refreshes payment data
    func refreshPayments() async {
        await loadPaymentHistory()
    }

    // MARK: - Refund Management

    /// Lists all refundable swaps (failed Bitcoin payments)
    func listRefundableSwaps() async throws -> [RefundableSwap] {
        return try await paymentService.listRefundableSwaps()
    }

    /// Gets recommended fees for Bitcoin transactions
    func getRecommendedFees() async throws -> RecommendedFees {
        return try await walletService.getRecommendedFees()
    }

    // MARK: - Payment Limits

    /// Fetches Lightning payment limits
    func fetchLightningLimits() async throws -> LightningPaymentLimitsResponse {
        return try await walletService.fetchLightningLimits()
    }



    /// Executes a refund for a failed swap
    func executeRefund(
        swapAddress: String,
        refundAddress: String,
        feeRateSatPerVbyte: UInt32
    ) async throws -> RefundResponse {
        let response = try await paymentService.executeRefund(
            swapAddress: swapAddress,
            refundAddress: refundAddress,
            feeRateSatPerVbyte: feeRateSatPerVbyte
        )

        // Refresh payment history to reflect the refund
        await loadPaymentHistory()

        return response
    }

    /// Estimates the cost of a refund transaction
    func estimateRefundCost(
        swapAddress: String,
        refundAddress: String,
        feeRateSatPerVbyte: UInt32
    ) -> RefundEstimate {
        // Estimate transaction size (typical refund transaction is ~200-250 vbytes)
        let estimatedVbytes: UInt32 = 225
        let estimatedFee = estimatedVbytes * feeRateSatPerVbyte

        return RefundEstimate(
            estimatedVbytes: estimatedVbytes,
            estimatedFeeSats: estimatedFee,
            feeRateSatPerVbyte: feeRateSatPerVbyte
        )
    }

    /// Validates a Bitcoin address for refunds
    func validateBitcoinAddress(_ address: String) -> Bool {
        // Basic Bitcoin address validation
        // In production, you might want more sophisticated validation
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check length and format for common Bitcoin address types
        if trimmedAddress.hasPrefix("bc1") && trimmedAddress.count >= 42 && trimmedAddress.count <= 62 {
            // Bech32 (native segwit)
            return true
        } else if trimmedAddress.hasPrefix("3") && trimmedAddress.count >= 26 && trimmedAddress.count <= 35 {
            // P2SH
            return true
        } else if trimmedAddress.hasPrefix("1") && trimmedAddress.count >= 26 && trimmedAddress.count <= 35 {
            // P2PKH (legacy)
            return true
        }

        return false
    }

    // MARK: - Input Parsing

    /// Parses various input types (BOLT11, LNURL, Bitcoin addresses, etc.)
    func parseInput(_ input: String) async throws -> InputType {
        return try await paymentService.parseInput(input)
    }

    /// Validates and prepares a payment based on parsed input
    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        return try await paymentService.validateAndPreparePayment(from: inputType)
    }

    // Note: Payment preparation methods moved to PaymentService

    /// Gets payment information from parsed input without preparing
    func getPaymentInfo(from inputType: InputType) -> PaymentInputInfo {
        // Convert PaymentInfo to PaymentInputInfo
        if let paymentInfo = paymentService.getPaymentInfo(from: inputType) {
            return PaymentInputInfo(
                type: .bolt11, // Default type, should be determined from inputType
                amount: paymentInfo.amount,
                description: paymentInfo.description,
                destination: paymentInfo.destination
            )
        } else {
            // Return default PaymentInputInfo for unsupported types
            return PaymentInputInfo(
                type: .unsupported,
                destination: ""
            )
        }
    }
}

// MARK: - Errors

enum WalletError: Error, LocalizedError {
    case notConnected
    case invalidInvoice
    case insufficientFunds
    case networkError
    case unsupportedPaymentType(String)
    case paymentExpired
    case amountOutOfRange
    case mnemonicGenerationFailed
    case invalidMnemonic(String)
    case initializationInProgress
    case walletNotFound
    case connectionFailed
    case importFailed
    case deletionFailed
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Wallet is not connected"
        case .invalidInvoice:
            return "Invalid payment invoice"
        case .insufficientFunds:
            return "Insufficient funds for this payment"
        case .networkError:
            return "Network connection error"
        case .unsupportedPaymentType(let type):
            return "Unsupported payment type: \(type)"
        case .paymentExpired:
            return "Payment request has expired"
        case .amountOutOfRange:
            return "Payment amount is out of allowed range"
        case .mnemonicGenerationFailed:
            return "Failed to generate secure wallet seed phrase"
        case .invalidMnemonic(let message):
            return "Invalid seed phrase: \(message)"
        case .initializationInProgress:
            return "Wallet initialization already in progress"
        case .walletNotFound:
            return "Wallet not found. Please create or restore a wallet."
        case .connectionFailed:
            return "Failed to connect to wallet service"
        case .importFailed:
            return "Failed to import wallet from seed phrase"
        case .deletionFailed:
            return "Failed to delete wallet from secure storage"
        case .exportFailed:
            return "Failed to export wallet seed phrase"
        }
    }
}

// MARK: - Payment Input Types

struct PaymentInputInfo {
    let type: PaymentInputType
    let amount: UInt64?
    let description: String?
    let destination: String?
    let expiry: Date?
    let isExpired: Bool
    let minAmount: UInt64?
    let maxAmount: UInt64?

    init(
        type: PaymentInputType,
        amount: UInt64? = nil,
        description: String? = nil,
        destination: String? = nil,
        expiry: Date? = nil,
        isExpired: Bool = false,
        minAmount: UInt64? = nil,
        maxAmount: UInt64? = nil
    ) {
        self.type = type
        self.amount = amount
        self.description = description
        self.destination = destination
        self.expiry = expiry
        self.isExpired = isExpired
        self.minAmount = minAmount
        self.maxAmount = maxAmount
    }
}

enum PaymentInputType {
    case bolt11
    case lnUrlPay
    case bolt12Offer
    case bitcoinAddress
    case lnUrlWithdraw
    case lnUrlAuth
    case unsupported

    var displayName: String {
        switch self {
        case .bolt11: return "Lightning Invoice"
        case .lnUrlPay: return "Lightning Address"
        case .bolt12Offer: return "BOLT12 Offer"
        case .bitcoinAddress: return "Bitcoin Address"
        case .lnUrlWithdraw: return "LNURL Withdraw"
        case .lnUrlAuth: return "LNURL Auth"
        case .unsupported: return "Unsupported"
        }
    }

    var icon: String {
        switch self {
        case .bolt11: return "bolt.fill"
        case .lnUrlPay: return "at"
        case .bolt12Offer: return "gift.fill"
        case .bitcoinAddress: return "bitcoinsign.circle.fill"
        case .lnUrlWithdraw: return "arrow.down.circle.fill"
        case .lnUrlAuth: return "key.fill"
        case .unsupported: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .bolt11: return .yellow
        case .lnUrlPay: return .blue
        case .bolt12Offer: return .purple
        case .bitcoinAddress: return .orange
        case .lnUrlWithdraw: return .green
        case .lnUrlAuth: return .red
        case .unsupported: return .gray
        }
    }
}

// MARK: - Refund Types

struct RefundEstimate {
    let estimatedVbytes: UInt32
    let estimatedFeeSats: UInt32
    let feeRateSatPerVbyte: UInt32

    var costDescription: String {
        return "~\(estimatedFeeSats) sats (\(feeRateSatPerVbyte) sat/vB)"
    }
}

// MARK: - Helper Functions

/// Generates a BIP39 mnemonic phrase using Web3Swift
/// Uses 256 bits of entropy for maximum security (24 words)
private func generateBIP39Mnemonic() throws -> String {
    do {
        // Generate 24-word mnemonic with 256 bits of entropy for maximum security
        let mnemonicArray = try BIP39.generateMnemonics(entropy: 256)
        let mnemonic = mnemonicArray.joined(separator: " ")

        print("✅ Generated secure BIP39 mnemonic with 256 bits of entropy")
        return mnemonic
    } catch {
        print("❌ Failed to generate BIP39 mnemonic: \(error)")
        throw WalletError.mnemonicGenerationFailed
    }
}

// MARK: - Extensions

extension Amount {
    /// Converts Amount to millisatoshis (UInt64)
    func toMsat() -> UInt64 {
        switch self {
        case .bitcoin(let amountMsat):
            return amountMsat
        case .currency(_, let fractionalAmount):
            // For currency amounts, we'll need to convert to bitcoin equivalent
            // This is a simplified conversion - in production you'd use exchange rates
            return fractionalAmount
        }
    }
}
