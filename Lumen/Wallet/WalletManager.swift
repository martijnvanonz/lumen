import Foundation
import SwiftUI
import BreezSDKLiquid

/// Manages the Breez SDK Liquid wallet integration
class WalletManager: ObservableObject {
    
    // MARK: - Published Properties

    @Published var isConnected = false
    @Published var balance: UInt64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var payments: [Payment] = []
    @Published var isLoadingPayments = false
    
    // MARK: - Private Properties
    
    private var sdk: BindingLiquidSdk?
    private let keychainManager = KeychainManager.shared
    private let biometricManager = BiometricManager.shared
    private let eventHandler = PaymentEventHandler.shared
    private let errorHandler = ErrorHandler.shared
    private let networkMonitor = NetworkMonitor.shared
    private let configManager = ConfigurationManager.shared
    
    // MARK: - Singleton
    
    static let shared = WalletManager()
    private init() {}
    
    // MARK: - Wallet Lifecycle
    
    /// Initializes the wallet - checks for existing mnemonic or creates new one
    func initializeWallet() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let mnemonic: String
            
            // Check if mnemonic exists in keychain
            if keychainManager.mnemonicExists() {
                // Authenticate and retrieve existing mnemonic
                mnemonic = try await authenticateAndRetrieveMnemonic()
            } else {
                // Generate new mnemonic and store it securely
                mnemonic = try await generateAndStoreMnemonic()
            }
            
            // Connect to Breez SDK with the mnemonic
            try await connectToBreezSDK(mnemonic: mnemonic)
            
            await MainActor.run {
                isConnected = true
                isLoading = false
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
    
    /// Generates a new mnemonic and stores it securely
    private func generateAndStoreMnemonic() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Generate mnemonic using Breez SDK
            do {
                let mnemonic = try generateBIP39Mnemonic()
                
                // Store mnemonic with biometric authentication
                biometricManager.authenticateAndStoreMnemonic(
                    mnemonic,
                    reason: "Secure your new Lumen wallet with biometric authentication"
                ) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: mnemonic)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Authenticates user and retrieves mnemonic from keychain
    private func authenticateAndRetrieveMnemonic() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            biometricManager.authenticateAndRetrieveMnemonic(
                reason: "Access your Lumen wallet"
            ) { result in
                switch result {
                case .success(let mnemonic):
                    continuation.resume(returning: mnemonic)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Connects to the Breez SDK with the provided mnemonic
    private func connectToBreezSDK(mnemonic: String) async throws {
        // Check network connectivity first
        guard networkMonitor.isNetworkAvailableForLightning() else {
            throw WalletError.networkError
        }

        await MainActor.run {
            eventHandler.updateConnectionStatus(.connecting)
        }

        do {
            // Get configuration with API key from ConfigurationManager
            let config = try configManager.getBreezSDKConfig()

            let connectRequest = ConnectRequest(config: config, mnemonic: mnemonic)

            // Connect to the SDK
            sdk = try connect(req: connectRequest)

            // Start listening for events
            startEventListener()

            await MainActor.run {
                eventHandler.updateConnectionStatus(.syncing)
            }

            // Get initial balance
            await updateBalance()

            // Load payment history
            await loadPaymentHistory()

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
    
    /// Starts listening for Breez SDK events
    private func startEventListener() {
        guard let sdk = sdk else { return }
        
        // Set up event listener for real-time updates
        let eventListener = LumenEventListener { [weak self] event in
            // Handle event through the event handler
            self?.eventHandler.handleSDKEvent(event)

            // Also handle wallet-specific updates
            Task { @MainActor in
                await self?.handleSDKEvent(event)
            }
        }
        
        do {
            try sdk.addEventListener(listener: eventListener)
        } catch {
            print("Failed to add event listener: \(error)")
        }
    }
    
    /// Handles events from the Breez SDK
    @MainActor
    private func handleSDKEvent(_ event: SdkEvent) async {
        switch event {
        case .synced:
            await updateBalance()
            await loadPaymentHistory()
        case .paymentSucceeded(let details):
            await updateBalance()
            await loadPaymentHistory()
            logInfo("Payment succeeded: \(details.txId ?? "unknown")")
        case .paymentFailed(let details):
            await loadPaymentHistory()
            logWarning("Payment failed: \(details.txId ?? "unknown")")
        case .paymentPending(let details):
            await loadPaymentHistory()
            logInfo("Payment pending: \(details.txId ?? "unknown")")
        case .paymentRefunded(let details):
            await updateBalance()
            await loadPaymentHistory()
            logInfo("Payment refunded: \(details.txId ?? "unknown")")
        case .paymentRefundPending(let details):
            await loadPaymentHistory()
            logInfo("Payment refund pending: \(details.txId ?? "unknown")")
        case .paymentWaitingConfirmation(let details):
            await loadPaymentHistory()
            logInfo("Payment waiting confirmation: \(details.txId ?? "unknown")")
        case .paymentRefundable(let details):
            await loadPaymentHistory()
            logInfo("Payment refundable: \(details.txId ?? "unknown")")
        case .paymentWaitingFeeAcceptance(let details):
            await loadPaymentHistory()
            logInfo("Payment waiting fee acceptance: \(details.txId ?? "unknown")")
        case .dataSynced(let didPullNewRecords):
            if didPullNewRecords {
                await updateBalance()
                await loadPaymentHistory()
                logInfo("Data synced with new records")
            }
        }
    }
    
    /// Updates the wallet balance
    func updateBalance() async {
        guard let sdk = sdk else { return }
        
        do {
            let walletInfo = try sdk.getInfo()
            await MainActor.run {
                self.balance = walletInfo.walletInfo.balanceSat
            }
        } catch {
            print("Failed to get wallet info: \(error)")
        }
    }
    
    // MARK: - Payment Methods
    
    /// Prepares a payment for the given invoice
    func preparePayment(invoice: String) async throws -> PrepareSendResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        let request = PrepareSendRequest(destination: invoice)
        return try sdk.prepareSendPayment(req: request)
    }

    /// Sends a payment
    func sendPayment(prepareResponse: PrepareSendResponse) async throws -> SendPaymentResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        let request = SendPaymentRequest(prepareResponse: prepareResponse)
        let response = try sdk.sendPayment(req: request)
        
        // Update balance after payment
        await updateBalance()
        
        return response
    }
    
    /// Prepares a receive payment (gets fee information)
    func prepareReceivePayment(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        let receiveAmount = ReceiveAmount.bitcoin(payerAmountSat: amountSat)
        let request = PrepareReceiveRequest(
            paymentMethod: .lightning,
            amount: receiveAmount
        )

        logInfo("Preparing receive payment for \(amountSat) sats")

        do {
            let response = try sdk.prepareReceivePayment(req: request)
            logInfo("Receive payment prepared. Fee: \(response.feesSat) sats")
            return response
        } catch {
            logError("Failed to prepare receive payment: \(error)")
            throw error
        }
    }

    /// Receives a payment using prepared response
    func receivePayment(prepareResponse: PrepareReceiveResponse, description: String? = nil) async throws -> ReceivePaymentResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        logInfo("Executing receive payment")

        do {
            let request = ReceivePaymentRequest(
                prepareResponse: prepareResponse,
                description: description
            )
            let response = try sdk.receivePayment(req: request)
            logInfo("Receive payment executed successfully")
            return response
        } catch {
            logError("Failed to execute receive payment: \(error)")
            throw error
        }
    }

    /// Legacy method for backward compatibility
    func receivePayment(amountSat: UInt64, description: String) async throws -> ReceivePaymentResponse {
        let prepared = try await prepareReceivePayment(amountSat: amountSat, description: description)
        return try await receivePayment(prepareResponse: prepared)
    }
    
    // MARK: - Utility Methods

    /// Disconnects from the Breez SDK
    func disconnect() async {
        guard let sdk = sdk else { return }

        do {
            try sdk.disconnect()
            await MainActor.run {
                self.isConnected = false
                self.sdk = nil
            }
        } catch {
            print("Failed to disconnect: \(error)")
        }
    }

    /// Resets the wallet by clearing stored mnemonic and disconnecting
    /// Use this to recover from corrupted wallet state
    func resetWallet() async throws {
        // Disconnect from SDK first
        await disconnect()

        // Clear stored mnemonic from keychain
        try keychainManager.deleteMnemonic()

        await MainActor.run {
            self.balance = 0
            self.payments = []
            self.errorMessage = nil
            self.isConnected = false
            self.isLoading = false
        }

        print("✅ Wallet reset completed - ready for fresh initialization")
    }
    
    /// Gets the current wallet info
    func getWalletInfo() async throws -> GetInfoResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        return try sdk.getInfo()
    }

    // MARK: - Payment Management

    /// Loads payment history from the SDK
    func loadPaymentHistory() async {
        guard let sdk = sdk else {
            logError("Cannot load payments: SDK not connected")
            return
        }

        await MainActor.run {
            isLoadingPayments = true
        }

        do {
            logInfo("Loading payment history...")
            let request = ListPaymentsRequest()
            let paymentList = try sdk.listPayments(req: request)

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
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        // Create list payments request with filters
        let request = ListPaymentsRequest(
            filters: filters,
            states: nil,
            fromTimestamp: nil,
            toTimestamp: nil,
            offset: offset,
            limit: limit,
            details: nil,
            sortAscending: nil
        )

        logInfo("Fetching payments with filters: \(String(describing: filters))")
        return try sdk.listPayments(req: request)
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
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        logInfo("Fetching refundable swaps...")

        do {
            let refundables = try sdk.listRefundables()
            logInfo("Found \(refundables.count) refundable swaps")
            return refundables
        } catch {
            logError("Failed to list refundables: \(error)")
            throw error
        }
    }

    /// Gets recommended fees for Bitcoin transactions
    func getRecommendedFees() async throws -> RecommendedFees {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        logInfo("Fetching recommended fees...")

        do {
            let fees = try sdk.recommendedFees()
            logInfo("Recommended fees - Fast: \(fees.fastestFee), Half hour: \(fees.halfHourFee), Hour: \(fees.hourFee), Economy: \(fees.economyFee)")
            return fees
        } catch {
            logError("Failed to get recommended fees: \(error)")
            throw error
        }
    }

    /// Executes a refund for a failed swap
    func executeRefund(
        swapAddress: String,
        refundAddress: String,
        feeRateSatPerVbyte: UInt32
    ) async throws -> RefundResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        logInfo("Executing refund for swap \(swapAddress) to \(refundAddress) with fee rate \(feeRateSatPerVbyte)")

        let request = RefundRequest(
            swapAddress: swapAddress,
            refundAddress: refundAddress,
            feeRateSatPerVbyte: feeRateSatPerVbyte
        )

        do {
            let response = try sdk.refund(req: request)
            logInfo("Refund executed successfully. TX ID: \(response.refundTxId)")

            // Refresh payment history to reflect the refund
            await loadPaymentHistory()

            return response
        } catch {
            logError("Failed to execute refund: \(error)")
            throw error
        }
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
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw WalletError.invalidInvoice
        }

        logInfo("Parsing input: \(trimmedInput.prefix(50))...")

        do {
            let inputType = try sdk.parse(input: trimmedInput)
            logInfo("Successfully parsed input as: \(inputType)")
            return inputType
        } catch {
            logError("Failed to parse input: \(error)")
            throw WalletError.invalidInvoice
        }
    }

    /// Validates and prepares a payment based on parsed input
    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        switch inputType {
        case .bolt11(let invoice):
            return try await prepareBolt11Payment(invoice: invoice)

        case .lnUrlPay(let data, let bip353Address):
            return try await prepareLnUrlPayment(data: data, bip353Address: bip353Address)

        case .bolt12Offer(let offer, let bip353Address):
            return try await prepareBolt12Payment(offer: offer, bip353Address: bip353Address)

        case .bitcoinAddress(let address):
            throw WalletError.unsupportedPaymentType("Bitcoin on-chain payments not yet supported")

        case .liquidAddress(let address):
            throw WalletError.unsupportedPaymentType("Liquid address payments not yet supported")

        case .lnUrlWithdraw(let data):
            throw WalletError.unsupportedPaymentType("LNURL-Withdraw not yet supported")

        case .nodeId(let nodeId):
            throw WalletError.unsupportedPaymentType("Node ID payments not yet supported")

        case .url(let url):
            throw WalletError.unsupportedPaymentType("URL payments not yet supported")

        case .lnUrlAuth(let data):
            throw WalletError.unsupportedPaymentType("LNURL-Auth not yet supported")

        case .lnUrlError(let data):
            throw WalletError.unsupportedPaymentType("LNURL error: \(data.reason)")

        case .lnUrlAuth(let data):
            throw WalletError.unsupportedPaymentType("LNURL-Auth not yet supported")

        case .lnUrlError(let data):
            throw WalletError.invalidInvoice

        case .nodeId(let nodeId):
            throw WalletError.unsupportedPaymentType("Direct node payments not supported")

        case .url(let url):
            throw WalletError.unsupportedPaymentType("URL payments not yet supported")
        }
    }

    /// Prepares a BOLT11 invoice payment
    private func prepareBolt11Payment(invoice: LnInvoice) async throws -> PrepareSendResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        let request = PrepareSendRequest(destination: invoice.bolt11)

        logInfo("Preparing BOLT11 payment for \(invoice.amountMsat ?? 0) msats")

        do {
            let response = try sdk.prepareSendPayment(req: request)
            logInfo("Payment prepared successfully. Fee: \(response.feesSat) sats")
            return response
        } catch {
            logError("Failed to prepare BOLT11 payment: \(error)")
            throw error
        }
    }

    /// Prepares an LNURL-Pay payment
    private func prepareLnUrlPayment(data: LnUrlPayRequestData, bip353Address: String?) async throws -> PrepareSendResponse {
        // For LNURL-Pay, we need to first get the invoice from the LNURL service
        // This is a simplified implementation - full LNURL-Pay requires more steps
        throw WalletError.unsupportedPaymentType("LNURL-Pay requires additional implementation")
    }

    /// Prepares a BOLT12 offer payment
    private func prepareBolt12Payment(offer: LnOffer, bip353Address: String?) async throws -> PrepareSendResponse {
        // BOLT12 offers require additional implementation
        throw WalletError.unsupportedPaymentType("BOLT12 offers require additional implementation")
    }

    /// Gets payment information from parsed input without preparing
    func getPaymentInfo(from inputType: InputType) -> PaymentInputInfo {
        switch inputType {
        case .bolt11(let invoice):
            return PaymentInputInfo(
                type: .bolt11,
                amount: invoice.amountMsat,
                description: invoice.description,
                destination: invoice.payeePubkey,
                expiry: Date(timeIntervalSince1970: TimeInterval(invoice.expiry)),
                isExpired: invoice.expiry < UInt64(Date().timeIntervalSince1970)
            )

        case .lnUrlPay(let data, let bip353Address):
            return PaymentInputInfo(
                type: .lnUrlPay,
                amount: nil, // LNURL-Pay allows variable amounts
                description: data.commentAllowed > 0 ? "LNURL-Pay (comment allowed)" : "LNURL-Pay",
                destination: bip353Address ?? data.callback,
                expiry: nil,
                isExpired: false,
                minAmount: data.minSendable,
                maxAmount: data.maxSendable
            )

        case .bolt12Offer(let offer, let bip353Address):
            return PaymentInputInfo(
                type: .bolt12Offer,
                amount: offer.minAmount?.toMsat(),
                description: offer.description,
                destination: bip353Address,
                expiry: nil,
                isExpired: false
            )

        case .bitcoinAddress(let address):
            return PaymentInputInfo(
                type: .bitcoinAddress,
                amount: nil,
                description: "Bitcoin on-chain payment",
                destination: address.address,
                expiry: nil,
                isExpired: false
            )

        default:
            return PaymentInputInfo(
                type: .unsupported,
                amount: nil,
                description: "Unsupported payment type",
                destination: nil,
                expiry: nil,
                isExpired: false
            )
        }
    }
}

// MARK: - Event Listener

private class LumenEventListener: EventListener {
    private let onEvent: (SdkEvent) -> Void
    
    init(onEvent: @escaping (SdkEvent) -> Void) {
        self.onEvent = onEvent
    }
    
    func onEvent(e: SdkEvent) {
        onEvent(e)
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

/// Generates a BIP39 mnemonic phrase using Breez SDK
private func generateBIP39Mnemonic() throws -> String {
    // Use Breez SDK's built-in mnemonic generation which ensures proper BIP39 compliance
    return try BreezSDKLiquid.generateMnemonic()
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
