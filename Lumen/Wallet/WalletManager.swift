import Foundation
import SwiftUI
import BreezSDKLiquid
import Web3Core

/// Manages the Breez SDK Liquid wallet integration
/// Refactored to coordinate between services instead of handling everything directly
class WalletManager: ObservableObject {

    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var balance: UInt64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var payments: [Payment] = []
    @Published var isLoadingPayments = false

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
    }

    // MARK: - Computed Properties

    /// Check if a wallet exists in storage
    var hasWallet: Bool {
        get { repository.hasWallet }
        set { repository.hasWallet = newValue }
    }

    /// Check if user is currently logged in
    var isLoggedIn: Bool {
        get { repository.isLoggedIn }
        set { repository.isLoggedIn = newValue }
    }

    // MARK: - Wallet Lifecycle

    private var isInitializing = false

    /// Imports a wallet from an existing mnemonic phrase
    /// - Parameter mnemonic: The BIP39 mnemonic phrase to import
    /// - Throws: WalletError if import fails
    func importWallet(mnemonic: String) async throws {
        // Prevent concurrent initialization
        guard !isInitializing else {
            print("⚠️ Wallet initialization already in progress - skipping import")
            throw WalletError.initializationInProgress
        }

        isInitializing = true
        defer { isInitializing = false }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            // Validate the mnemonic first
            let normalizedMnemonic = SeedPhraseValidator.normalizeSeedPhrase(mnemonic)
            let validation = SeedPhraseValidator.validateSeedPhrase(normalizedMnemonic)

            guard validation.isValid else {
                throw WalletError.invalidMnemonic(validation.errorMessage)
            }

            // Store the imported mnemonic using repository
            try repository.storeMnemonic(normalizedMnemonic)

            // Clear any previously selected currency for imported wallet
            await MainActor.run {
                CurrencyManager.shared.clearSelectedCurrency()
            }

            // Connect to wallet with event handling
            try await connectToWallet(mnemonic: normalizedMnemonic)

            await MainActor.run {
                isConnected = walletService.isConnected
                isLoading = false
                repository.hasWallet = true
                repository.isLoggedIn = true
            }

            print("✅ Successfully imported wallet with \(normalizedMnemonic.components(separatedBy: " ").count) words")

        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    /// Initializes the wallet - checks for existing mnemonic or creates new one
    func initializeWallet() async {
        // Prevent concurrent initialization
        guard !isInitializing else {
            print("⚠️ Wallet initialization already in progress - skipping duplicate call")
            return
        }

        isInitializing = true
        defer { isInitializing = false }
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let mnemonic: String

            // Check if mnemonic exists using repository
            if repository.mnemonicExists() {
                // Retrieve existing mnemonic
                mnemonic = try await retrieveExistingMnemonic()
            } else {
                // Generate new mnemonic and store it securely
                mnemonic = try await generateAndStoreMnemonic()
            }

            // Connect to wallet with event handling
            try await connectToWallet(mnemonic: mnemonic)

            await MainActor.run {
                isConnected = walletService.isConnected
                isLoading = false
            }

            // Update state flags on main thread
            await MainActor.run {
                repository.hasWallet = true
                repository.isLoggedIn = true
            }

            // Load currencies but don't auto-select default during onboarding
            Task {
                await CurrencyManager.shared.reloadCurrenciesFromSDK(setDefaultIfNone: false)
                await CurrencyManager.shared.fetchCurrentRates()
                await CurrencyManager.shared.startRateUpdates()
            }

        } catch {
            await MainActor.run {
                errorMessage = "Failed to initialize wallet: \(error.localizedDescription)"
                isLoading = false
            }

            // Handle error through error handler
            errorHandler.handle(error, context: "Wallet initialization")
        }
    }

    /// Shared initialization task to prevent concurrent initialization
    private var initializationTask: Task<Bool, Never>?

    /// Quick initialization using cached seed (no biometric auth required)
    func initializeWalletFromCache() async -> Bool {
        print("🔄 initializeWalletFromCache called from async context")
        print("🔄 Current state - isInitializing: \(isInitializing), isConnected: \(isConnected), isLoggedIn: \(isLoggedIn)")

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
            await self.performSingleInitialization()
        }

        initializationTask = task
        let result = await task.value
        initializationTask = nil

        return result
    }

    /// Perform single initialization to prevent race conditions
    @MainActor
    private func performSingleInitialization() async -> Bool {
        // Double-check if already connected
        if isConnected {
            print("✅ Already connected during single initialization - skipping")
            return true
        }

        // Prevent concurrent initialization
        guard !isInitializing else {
            print("⚠️ Wallet initialization already in progress during single init - skipping")
            return false
        }

        // Check if we have a valid cached seed using repository
        guard repository.isCacheValid() else {
            print("❌ Cache invalid - cannot initialize from cache")
            return false
        }

        print("🔄 Starting single wallet initialization from cache...")
        isInitializing = true

        defer {
            isInitializing = false
            print("🔄 Single wallet initialization from cache completed")
        }

        return await performCacheInitialization()
    }

    /// Perform the actual cache initialization
    private func performCacheInitialization() async -> Bool {

        do {
            let cachedSeed = try repository.retrieveCachedSeed()

            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }

            // Connect to wallet with cached mnemonic and event handling
            try await connectToWallet(mnemonic: cachedSeed)

            await MainActor.run {
                isConnected = walletService.isConnected
                isLoading = false
            }

            // Update state flags on main thread
            await MainActor.run {
                repository.hasWallet = true
                repository.isLoggedIn = true
            }

            // Load currencies
            Task {
                await CurrencyManager.shared.reloadCurrenciesFromSDK(setDefaultIfNone: false)
                await CurrencyManager.shared.fetchCurrentRates()
                await CurrencyManager.shared.startRateUpdates()
            }

            print("✅ Wallet initialized from secure cache")
            return true

        } catch {
            print("❌ Failed to initialize from cache: \(error)")
            return false
        }
    }
    
    /// Generates a new mnemonic and stores it securely in iCloud Keychain
    private func generateAndStoreMnemonic() async throws -> String {
        // Generate mnemonic using Breez SDK
        let mnemonic = try generateBIP39Mnemonic()

        // Store mnemonic using repository
        try repository.storeMnemonic(mnemonic)

        // Clear any previously selected currency for new wallet
        await MainActor.run {
            CurrencyManager.shared.clearSelectedCurrency()
        }

        print("✅ Generated secure BIP39 mnemonic with \(mnemonic.split(separator: " ").count * 11) bits of entropy")
        return mnemonic
    }

    /// Retrieves existing mnemonic with secure authentication and caching
    private func retrieveExistingMnemonic() async throws -> String {
        print("🔐 WalletManager: Retrieving existing mnemonic with biometric auth")
        // Use repository for secure mnemonic retrieval with biometric authentication and caching
        let mnemonic = try await repository.getSecureMnemonic(reason: "Unlock your Lumen wallet")
        print("✅ WalletManager: Successfully retrieved and cached mnemonic")
        return mnemonic
    }
    
    /// Connects to the wallet using services and sets up event handling
    private func connectToWallet(mnemonic: String) async throws {
        print("🔗 connectToWallet called from async context")

        await MainActor.run {
            eventHandler.updateConnectionStatus(.connecting)
        }

        do {
            // Connect using wallet service
            try await walletService.connect(mnemonic: mnemonic)

            // Set up event handling (if the wallet service provides SDK access)
            await setupEventHandling()

            await MainActor.run {
                eventHandler.updateConnectionStatus(.syncing)
            }

            // Get initial balance
            await updateBalance()

            // Load payment history
            await loadPaymentHistory()

            // Start currency manager rate updates
            await MainActor.run {
                CurrencyManager.shared.startRateUpdates()
            }

            await MainActor.run {
                eventHandler.updateConnectionStatus(.connected)
            }
        } catch {
            await MainActor.run {
                eventHandler.updateConnectionStatus(.disconnected)
            }

            // Log error and re-throw
            errorHandler.logError(.sdk(.connectionFailed), context: "SDK connection")
            throw error
        }
    }

    /// Sets up event handling for wallet events
    private func setupEventHandling() async {
        // For now, we'll need to access the SDK through the wallet service
        // This is a temporary solution until we fully abstract event handling
        if let breezService = walletService as? BreezWalletService {
            // We'll need to add a method to get the SDK instance from the service
            // This is a design decision - we could either:
            // 1. Add event handling to the service layer
            // 2. Expose SDK access for event handling
            // For now, we'll skip detailed event setup and rely on service-level handling
            print("⚠️ Event handling setup deferred to service layer")
        }
    }
    
    // Note: Event listening is now handled by the wallet service
    
    // Note: SDK event handling is now managed by the wallet service
    
    /// Updates the wallet balance
    func updateBalance() async {
        guard walletService.isConnected else { return }

        do {
            let newBalance = try await walletService.getBalance()
            await MainActor.run {
                self.balance = newBalance
            }
        } catch {
            print("Failed to get wallet balance: \(error)")
        }
    }
    
    // MARK: - Payment Methods
    
    /// Prepares a payment for the given invoice
    func preparePayment(invoice: String) async throws -> PrepareSendResponse {
        return try await paymentService.preparePayment(invoice: invoice)
    }

    /// Sends a payment
    func sendPayment(prepareResponse: PrepareSendResponse) async throws -> SendPaymentResponse {
        let response = try await paymentService.executePayment(prepareResponse)

        // Update balance and payment history after successful payment
        await updateBalance()
        await loadPaymentHistory()

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

    /// Disconnects from the wallet service
    func disconnect() async {
        guard walletService.isConnected else { return }

        do {
            try await walletService.disconnect()
            await MainActor.run {
                self.isConnected = false
                // Stop currency manager rate updates
                CurrencyManager.shared.stopRateUpdates()
            }
        } catch {
            print("Failed to disconnect: \(error)")
        }
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
        // Clear secure seed cache using repository
        repository.clearCache()

        // Disconnect from wallet service
        await disconnect()

        // Clear in-memory state
        await MainActor.run {
            self.isConnected = false
            self.balance = 0
            self.payments = []
            self.errorMessage = nil
            self.isLoading = false
        }

        // Update state (preserve hasWallet, clear isLoggedIn)
        repository.isLoggedIn = false

        // Notify that authentication state should be reset
        NotificationCenter.default.post(name: .authenticationStateReset, object: nil)

        print("✅ User logged out - wallet remains in keychain, secure cache cleared")
    }

    /// Permanently deletes wallet from keychain and clears all state
    func deleteWalletFromKeychain() async throws {
        // Clear secure seed cache using repository
        repository.clearCache()

        // First logout to clear all state
        await logout()

        // Delete mnemonic using repository
        try repository.deleteMnemonic()

        // Clear all state
        repository.hasWallet = false
        repository.isLoggedIn = false

        // Clear selected currency
        CurrencyManager.shared.clearSelectedCurrency()

        print("✅ Wallet permanently deleted from keychain and secure cache cleared")
    }



    // MARK: - Payment Management

    /// Loads payment history using payment service
    func loadPaymentHistory() async {
        guard walletService.isConnected else {
            logError("Cannot load payments: Wallet service not connected")
            return
        }

        await MainActor.run {
            isLoadingPayments = true
        }

        do {
            logInfo("Loading payment history...")
            let paymentList = try await paymentService.getPaymentHistory()

            await MainActor.run {
                self.payments = paymentList
                self.isLoadingPayments = false
                logInfo("Loaded \(paymentList.count) payments")
            }

            // Update the PaymentEventHandler with real payment data
            await updatePaymentEventHandler(with: paymentList)

        } catch {
            await MainActor.run {
                self.isLoadingPayments = false
            }

            logError("Failed to load payment history: \(error)")
            errorHandler.handle(error, context: "Loading payment history")
        }
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
