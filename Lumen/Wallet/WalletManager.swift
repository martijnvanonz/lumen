import Foundation
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
                let mnemonic = try generateMnemonic()
                
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

            let connectRequest = ConnectRequest(mnemonic: mnemonic, config: config)

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
        }
    }
    
    /// Updates the wallet balance
    private func updateBalance() async {
        guard let sdk = sdk else { return }
        
        do {
            let walletInfo = try sdk.getInfo()
            await MainActor.run {
                self.balance = walletInfo.balanceSat
            }
        } catch {
            print("Failed to get wallet info: \(error)")
        }
    }
    
    // MARK: - Payment Methods
    
    /// Prepares a payment for the given invoice
    func preparePayment(invoice: String) async throws -> PreparePayResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }
        
        let request = PreparePayRequest(invoice: invoice)
        return try sdk.preparePay(req: request)
    }
    
    /// Sends a payment
    func sendPayment(prepareResponse: PreparePayResponse) async throws -> PayResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }
        
        let request = PayRequest(prepareResponse: prepareResponse)
        let response = try sdk.pay(req: request)
        
        // Update balance after payment
        await updateBalance()
        
        return response
    }
    
    /// Receives a payment by generating an invoice
    func receivePayment(amountSat: UInt64, description: String) async throws -> ReceivePaymentResponse {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }
        
        let request = ReceivePaymentRequest(
            amountSat: amountSat,
            description: description
        )
        
        return try sdk.receivePayment(req: request)
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
            let paymentList = try sdk.listPayments()

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
                case .pending:
                    eventHandler.pendingPayments.append(paymentInfo)
                case .complete:
                    eventHandler.recentPayments.append(paymentInfo)
                case .failed:
                    eventHandler.recentPayments.append(paymentInfo)
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
        case .pending:
            status = .pending
        case .complete:
            status = .succeeded
        case .failed:
            status = .failed
        }

        return PaymentEventHandler.PaymentInfo(
            paymentHash: payment.txId ?? UUID().uuidString,
            amountSat: payment.amountSat,
            direction: direction,
            status: status,
            timestamp: Date(timeIntervalSince1970: TimeInterval(payment.timestamp)),
            description: payment.description
        )
    }

    /// Gets payments with optional filtering
    func getPayments(
        filter: PaymentTypeFilter? = nil,
        limit: UInt32? = nil,
        offset: UInt32? = nil
    ) async throws -> [Payment] {
        guard let sdk = sdk else {
            throw WalletError.notConnected
        }

        // Create list payments request with filters
        let request = ListPaymentsRequest(
            filters: filter.map { [$0] },
            metadataFilters: nil,
            fromTimestamp: nil,
            toTimestamp: nil,
            includeFailures: true,
            limit: limit,
            offset: offset
        )

        logInfo("Fetching payments with filters: \(String(describing: filter))")
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
        }
    }
}
