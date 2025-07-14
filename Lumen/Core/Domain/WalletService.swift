import Foundation
import BreezSDKLiquid

/// Protocol defining wallet service operations
/// This separates SDK interactions from UI state management and provides
/// a clean interface for wallet operations that can be easily tested and mocked.
protocol WalletServiceProtocol {
    
    // MARK: - Connection Management
    
    /// Connect to the wallet using a mnemonic phrase
    /// - Parameter mnemonic: BIP39 mnemonic phrase
    /// - Throws: WalletServiceError if connection fails
    func connect(mnemonic: String) async throws
    
    /// Disconnect from the wallet
    func disconnect() async throws
    
    /// Check if the wallet is currently connected
    var isConnected: Bool { get }
    
    /// Get current wallet information
    /// - Returns: Wallet information including balance and status
    /// - Throws: WalletServiceError if not connected or operation fails
    func getWalletInfo() async throws -> GetInfoResponse

    /// Get current wallet information (alias for getWalletInfo)
    /// - Returns: Wallet information including balance and status
    /// - Throws: WalletServiceError if not connected or operation fails
    func getInfo() async throws -> GetInfoResponse
    
    // MARK: - Balance Operations
    
    /// Get current wallet balance
    /// - Returns: Balance in satoshis
    /// - Throws: WalletServiceError if not connected or operation fails
    func getBalance() async throws -> UInt64
    
    /// Refresh wallet balance from the network
    /// - Throws: WalletServiceError if not connected or operation fails
    func refreshBalance() async throws
    
    // MARK: - Payment Operations
    
    /// Prepare a Lightning payment
    /// - Parameter destination: Payment destination (invoice, LNURL, etc.)
    /// - Returns: Prepared payment response with fee information
    /// - Throws: WalletServiceError if preparation fails
    func preparePayment(destination: String) async throws -> PrepareSendResponse
    
    /// Send a prepared Lightning payment
    /// - Parameter preparedPayment: Previously prepared payment
    /// - Returns: Payment response with transaction details
    /// - Throws: WalletServiceError if payment fails
    func sendPayment(preparedPayment: PrepareSendResponse) async throws -> SendPaymentResponse
    
    /// Prepare to receive a Lightning payment
    /// - Parameters:
    ///   - amountSat: Amount to receive in satoshis
    ///   - description: Payment description
    /// - Returns: Prepared receive response with fee information
    /// - Throws: WalletServiceError if preparation fails
    func prepareReceivePayment(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse
    
    /// Execute a prepared receive payment
    /// - Parameters:
    ///   - preparedReceive: Previously prepared receive payment
    ///   - description: Optional payment description
    /// - Returns: Receive payment response with invoice details
    /// - Throws: WalletServiceError if receive fails
    func receivePayment(preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse
    
    // MARK: - Onchain Operations
    
    /// Prepare to receive an onchain Bitcoin payment
    /// - Returns: Prepared receive response with address and fee information
    /// - Throws: WalletServiceError if preparation fails
    func prepareReceiveOnchain() async throws -> PrepareReceiveResponse
    
    /// Execute a prepared onchain receive payment
    /// - Parameter preparedReceive: Previously prepared onchain receive
    /// - Returns: Receive payment response with address details
    /// - Throws: WalletServiceError if receive fails
    func receiveOnchain(preparedReceive: PrepareReceiveResponse) async throws -> ReceivePaymentResponse
    
    // MARK: - Liquid Operations
    
    /// Prepare to receive a Liquid Bitcoin payment
    /// - Returns: Prepared receive response with address and fee information
    /// - Throws: WalletServiceError if preparation fails
    func prepareReceiveLiquid() async throws -> PrepareReceiveResponse
    
    /// Execute a prepared Liquid receive payment
    /// - Parameters:
    ///   - preparedReceive: Previously prepared Liquid receive
    ///   - description: Optional payment description
    /// - Returns: Receive payment response with address details
    /// - Throws: WalletServiceError if receive fails
    func receiveLiquid(preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse
    
    // MARK: - Buy Bitcoin Operations
    
    /// Prepare to buy Bitcoin through a provider
    /// - Parameter provider: Buy Bitcoin provider
    /// - Returns: Prepared buy Bitcoin response
    /// - Throws: WalletServiceError if preparation fails
    func prepareBuyBitcoin(provider: BuyBitcoinProvider) async throws -> PrepareBuyBitcoinResponse
    
    /// Execute a prepared buy Bitcoin operation
    /// - Parameters:
    ///   - preparedBuy: Previously prepared buy Bitcoin operation
    ///   - redirectUrl: Optional redirect URL after purchase
    /// - Returns: Provider URL for completing the purchase
    /// - Throws: WalletServiceError if operation fails
    func buyBitcoin(preparedBuy: PrepareBuyBitcoinResponse, redirectUrl: String?) async throws -> String
    
    // MARK: - Payment History
    
    /// Get payment history
    /// - Returns: Array of payments
    /// - Throws: WalletServiceError if not connected or operation fails
    func getPaymentHistory() async throws -> [Payment]
    
    /// Refresh payment history from the network
    /// - Throws: WalletServiceError if not connected or operation fails
    func refreshPaymentHistory() async throws
    
    // MARK: - Input Parsing
    
    /// Parse payment input to determine type and extract data
    /// - Parameter input: Payment input string (invoice, address, LNURL, etc.)
    /// - Returns: Parsed input type with extracted data
    /// - Throws: WalletServiceError if input is invalid or unsupported
    func parsePaymentInput(_ input: String) async throws -> InputType
    
    /// Validate and prepare payment from parsed input
    /// - Parameter inputType: Previously parsed input type
    /// - Returns: Prepared payment response
    /// - Throws: WalletServiceError if validation or preparation fails
    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse

    // MARK: - Limits and Fees

    /// Fetch onchain payment limits
    /// - Returns: Onchain payment limits
    /// - Throws: WalletServiceError if operation fails
    func fetchOnchainLimits() async throws -> OnchainPaymentLimitsResponse

    /// Fetch Lightning payment limits
    /// - Returns: Lightning payment limits
    /// - Throws: WalletServiceError if operation fails
    func fetchLightningLimits() async throws -> LightningPaymentLimitsResponse

    /// Get recommended fees for Bitcoin transactions
    /// - Returns: Recommended fees
    /// - Throws: WalletServiceError if operation fails
    func getRecommendedFees() async throws -> RecommendedFees

    // MARK: - Currency Operations

    /// List available fiat currencies
    /// - Returns: Array of available currencies
    /// - Throws: WalletServiceError if operation fails
    func listFiatCurrencies() async throws -> [FiatCurrency]

    /// Fetch current fiat exchange rates
    /// - Returns: Current exchange rates
    /// - Throws: WalletServiceError if operation fails
    func fetchFiatRates() async throws -> [Rate]
}

// MARK: - Wallet Service Errors

/// Errors that can occur during wallet service operations
enum WalletServiceError: Error, LocalizedError {
    case notConnected
    case connectionFailed(String)
    case invalidMnemonic(String)
    case networkError
    case insufficientFunds
    case invalidPaymentRequest(String)
    case paymentFailed(String)
    case unsupportedOperation(String)
    case sdkError(String)
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Wallet is not connected. Please connect your wallet first."
        case .connectionFailed(let message):
            return "Failed to connect to wallet: \(message)"
        case .invalidMnemonic(let message):
            return "Invalid mnemonic phrase: \(message)"
        case .networkError:
            return "Network error. Please check your internet connection."
        case .insufficientFunds:
            return "Insufficient funds for this transaction."
        case .invalidPaymentRequest(let message):
            return "Invalid payment request: \(message)"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .unsupportedOperation(let message):
            return "Unsupported operation: \(message)"
        case .sdkError(let message):
            return "SDK error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}

// MARK: - Default Implementation

/// Default implementation of WalletServiceProtocol using Breez SDK Liquid
class BreezWalletService: WalletServiceProtocol {
    
    // MARK: - Private Properties
    
    private var sdk: BindingLiquidSdk?
    private let configuration: AppConfigurationProtocol
    private let networkMonitor: NetworkMonitor
    
    // MARK: - Initialization
    
    init(
        configuration: AppConfigurationProtocol = DefaultAppConfiguration.shared,
        networkMonitor: NetworkMonitor = NetworkMonitor.shared
    ) {
        self.configuration = configuration
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - Connection Management
    
    var isConnected: Bool {
        return sdk != nil
    }
    
    func connect(mnemonic: String) async throws {
        // Check network connectivity
        guard networkMonitor.isNetworkAvailableForLightning() else {
            throw WalletServiceError.networkError
        }
        
        do {
            // Get SDK configuration
            let config = try configuration.getBreezSDKConfig()
            
            // Create connect request
            let connectRequest = ConnectRequest(config: config, mnemonic: mnemonic)
            
            // Connect to SDK
            sdk = try BreezSDKLiquid.connect(req: connectRequest)
            
            print("✅ WalletService connected to Breez SDK")
            
        } catch {
            throw WalletServiceError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() async throws {
        guard let sdk = sdk else { return }
        
        do {
            try sdk.disconnect()
            self.sdk = nil
            print("✅ WalletService disconnected from Breez SDK")
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }
    
    func getWalletInfo() async throws -> GetInfoResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            return try sdk.getInfo()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }
    
    // MARK: - Balance Operations
    
    func getBalance() async throws -> UInt64 {
        let walletInfo = try await getWalletInfo()
        return walletInfo.walletInfo.balanceSat
    }
    
    func refreshBalance() async throws {
        // Balance is automatically updated when getting wallet info
        _ = try await getBalance()
    }
    
    // MARK: - Payment Operations
    
    func preparePayment(destination: String) async throws -> PrepareSendResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = PrepareSendRequest(destination: destination)
            return try sdk.prepareSendPayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func sendPayment(preparedPayment: PrepareSendResponse) async throws -> SendPaymentResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = SendPaymentRequest(prepareResponse: preparedPayment)
            return try sdk.sendPayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func prepareReceivePayment(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let receiveAmount = ReceiveAmount.bitcoin(payerAmountSat: amountSat)
            let request = PrepareReceiveRequest(
                paymentMethod: .lightning,
                amount: receiveAmount
            )
            return try sdk.prepareReceivePayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func receivePayment(preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = ReceivePaymentRequest(
                prepareResponse: preparedReceive,
                description: description
            )
            return try sdk.receivePayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Additional Operations (Simplified for now)
    
    func prepareReceiveOnchain() async throws -> PrepareReceiveResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = PrepareReceiveRequest(
                paymentMethod: .bitcoinAddress,
                amount: nil
            )
            return try sdk.prepareReceivePayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func receiveOnchain(preparedReceive: PrepareReceiveResponse) async throws -> ReceivePaymentResponse {
        return try await receivePayment(preparedReceive: preparedReceive, description: "Lumen onchain receive")
    }
    
    func prepareReceiveLiquid() async throws -> PrepareReceiveResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = PrepareReceiveRequest(
                paymentMethod: .liquidAddress,
                amount: nil
            )
            return try sdk.prepareReceivePayment(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func receiveLiquid(preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse {
        return try await receivePayment(preparedReceive: preparedReceive, description: description)
    }
    
    func prepareBuyBitcoin(provider: BuyBitcoinProvider) async throws -> PrepareBuyBitcoinResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = PrepareBuyBitcoinRequest(provider: provider, amountSat: 100000)
            return try sdk.prepareBuyBitcoin(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func buyBitcoin(preparedBuy: PrepareBuyBitcoinResponse, redirectUrl: String?) async throws -> String {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = BuyBitcoinRequest(prepareResponse: preparedBuy, redirectUrl: redirectUrl)
            return try sdk.buyBitcoin(req: request)
        } catch {
            throw WalletServiceError.paymentFailed(error.localizedDescription)
        }
    }
    
    func getPaymentHistory() async throws -> [Payment] {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            let request = ListPaymentsRequest()
            return try sdk.listPayments(req: request)
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }
    
    func refreshPaymentHistory() async throws {
        // Payment history is automatically updated when listing payments
        _ = try await getPaymentHistory()
    }
    
    func parsePaymentInput(_ input: String) async throws -> InputType {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }
        
        do {
            return try sdk.parse(input: input)
        } catch {
            throw WalletServiceError.invalidPaymentRequest(error.localizedDescription)
        }
    }
    
    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        // This would contain the complex validation logic from WalletManager
        // For now, simplified implementation
        switch inputType {
        case .bolt11(let invoice):
            return try await preparePayment(destination: invoice.bolt11)
        default:
            throw WalletServiceError.unsupportedOperation("Input type not yet supported in service layer")
        }
    }

    func getInfo() async throws -> GetInfoResponse {
        return try await getWalletInfo()
    }

    func fetchOnchainLimits() async throws -> OnchainPaymentLimitsResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }

        do {
            return try sdk.fetchOnchainLimits()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }

    func fetchLightningLimits() async throws -> LightningPaymentLimitsResponse {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }

        do {
            return try sdk.fetchLightningLimits()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }

    func getRecommendedFees() async throws -> RecommendedFees {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }

        do {
            return try sdk.recommendedFees()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }

    func listFiatCurrencies() async throws -> [FiatCurrency] {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }

        do {
            return try sdk.listFiatCurrencies()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }

    func fetchFiatRates() async throws -> [Rate] {
        guard let sdk = sdk else {
            throw WalletServiceError.notConnected
        }

        do {
            return try sdk.fetchFiatRates()
        } catch {
            throw WalletServiceError.sdkError(error.localizedDescription)
        }
    }
}
