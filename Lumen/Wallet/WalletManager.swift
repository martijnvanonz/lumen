import Foundation
import BreezSDKLiquid

/// Manages the Breez SDK Liquid wallet integration
class WalletManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isConnected = false
    @Published var balance: UInt64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var sdk: BindingLiquidSdk?
    private let keychainManager = KeychainManager.shared
    private let biometricManager = BiometricManager.shared
    private let eventHandler = PaymentEventHandler.shared
    
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
        await MainActor.run {
            eventHandler.updateConnectionStatus(.connecting)
        }

        let config = try defaultConfig(network: LiquidNetwork.mainnet)

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

        await MainActor.run {
            eventHandler.updateConnectionStatus(.connected)
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
        case .paymentSucceeded(let details):
            await updateBalance()
            print("Payment succeeded: \(details)")
        case .paymentFailed(let details):
            print("Payment failed: \(details)")
        case .paymentPending(let details):
            print("Payment pending: \(details)")
        case .paymentRefunded(let details):
            await updateBalance()
            print("Payment refunded: \(details)")
        case .paymentRefundPending(let details):
            print("Payment refund pending: \(details)")
        case .paymentWaitingConfirmation(let details):
            print("Payment waiting confirmation: \(details)")
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
