import Foundation
import BreezSDKLiquid

// MARK: - Additional Types

/// Response for buy Bitcoin operations
struct BuyBitcoinResponse {
    let url: String
}

/// Payment information extracted from input
struct PaymentInfo {
    let amount: UInt64?
    let description: String?
    let destination: String
}

/// Service responsible for payment operations and validation
/// This extracts payment-specific logic from WalletManager and provides
/// a focused interface for all payment-related operations.
protocol PaymentServiceProtocol {
    
    // MARK: - Payment Preparation
    
    /// Parse and validate payment input
    /// - Parameter input: Payment input string (invoice, address, LNURL, etc.)
    /// - Returns: Parsed and validated input type
    /// - Throws: PaymentServiceError if input is invalid
    func parsePaymentInput(_ input: String) async throws -> InputType
    
    /// Prepare a Lightning payment from parsed input
    /// - Parameter inputType: Previously parsed input type
    /// - Returns: Prepared payment with fee information
    /// - Throws: PaymentServiceError if preparation fails
    func preparePayment(from inputType: InputType) async throws -> PrepareSendResponse
    
    /// Prepare a Lightning payment from invoice string
    /// - Parameter invoice: Lightning invoice string
    /// - Returns: Prepared payment with fee information
    /// - Throws: PaymentServiceError if preparation fails
    func preparePayment(invoice: String) async throws -> PrepareSendResponse
    
    // MARK: - Payment Execution
    
    /// Execute a prepared Lightning payment
    /// - Parameter preparedPayment: Previously prepared payment
    /// - Returns: Payment result with transaction details
    /// - Throws: PaymentServiceError if payment fails
    func executePayment(_ preparedPayment: PrepareSendResponse) async throws -> SendPaymentResponse
    
    /// Send a Lightning payment (prepare + execute in one step)
    /// - Parameter destination: Payment destination
    /// - Returns: Payment result with transaction details
    /// - Throws: PaymentServiceError if payment fails
    func sendPayment(to destination: String) async throws -> SendPaymentResponse
    
    // MARK: - Receive Operations
    
    /// Prepare to receive a Lightning payment
    /// - Parameters:
    ///   - amountSat: Amount to receive in satoshis
    ///   - description: Payment description
    /// - Returns: Prepared receive with fee information
    /// - Throws: PaymentServiceError if preparation fails
    func prepareReceive(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse
    
    /// Execute a prepared receive operation
    /// - Parameters:
    ///   - preparedReceive: Previously prepared receive
    ///   - description: Optional payment description
    /// - Returns: Receive result with invoice details
    /// - Throws: PaymentServiceError if receive fails
    func executeReceive(_ preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse
    
    /// Create a Lightning invoice (prepare + execute in one step)
    /// - Parameters:
    ///   - amountSat: Amount to receive in satoshis
    ///   - description: Payment description
    /// - Returns: Receive result with invoice details
    /// - Throws: PaymentServiceError if creation fails
    func createInvoice(amountSat: UInt64, description: String) async throws -> ReceivePaymentResponse
    
    // MARK: - Payment Validation
    
    /// Validate payment amount against wallet balance
    /// - Parameter amountSat: Amount to validate in satoshis
    /// - Returns: True if payment is possible
    /// - Throws: PaymentServiceError if validation fails
    func validatePaymentAmount(_ amountSat: UInt64) async throws -> Bool
    
    /// Estimate payment fees
    /// - Parameter destination: Payment destination
    /// - Returns: Estimated fee in satoshis
    /// - Throws: PaymentServiceError if estimation fails
    func estimatePaymentFee(for destination: String) async throws -> UInt64
    
    /// Check if payment destination is valid
    /// - Parameter destination: Payment destination to validate
    /// - Returns: True if destination is valid
    /// - Throws: PaymentServiceError if validation fails
    func validatePaymentDestination(_ destination: String) async throws -> Bool

    // MARK: - Onchain Operations

    /// Prepare to receive an onchain payment
    /// - Parameter payerAmountSat: Optional amount in satoshis
    /// - Returns: Prepared receive response
    /// - Throws: PaymentServiceError if preparation fails
    func prepareReceiveOnchain(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse

    /// Execute an onchain receive payment
    /// - Parameters:
    ///   - prepareResponse: Previously prepared receive response
    ///   - description: Payment description
    /// - Returns: Receive payment response
    /// - Throws: PaymentServiceError if execution fails
    func executeReceiveOnchain(_ prepareResponse: PrepareReceiveResponse, description: String) async throws -> ReceivePaymentResponse

    // MARK: - Liquid Operations

    /// Prepare to receive a Liquid payment
    /// - Parameter payerAmountSat: Optional amount in satoshis
    /// - Returns: Prepared receive response
    /// - Throws: PaymentServiceError if preparation fails
    func prepareReceiveLiquid(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse

    /// Execute a Liquid receive payment
    /// - Parameters:
    ///   - prepareResponse: Previously prepared receive response
    ///   - description: Payment description
    /// - Returns: Receive payment response
    /// - Throws: PaymentServiceError if execution fails
    func executeReceiveLiquid(_ prepareResponse: PrepareReceiveResponse, description: String) async throws -> ReceivePaymentResponse

    // MARK: - Buy Bitcoin Operations

    /// Prepare to buy Bitcoin
    /// - Parameters:
    ///   - provider: Buy Bitcoin provider
    ///   - amountSat: Amount in satoshis
    /// - Returns: Prepared buy Bitcoin response
    /// - Throws: PaymentServiceError if preparation fails
    func prepareBuyBitcoin(provider: BuyBitcoinProvider, amountSat: UInt64) async throws -> PrepareBuyBitcoinResponse

    /// Execute a buy Bitcoin operation
    /// - Parameters:
    ///   - prepareResponse: Previously prepared buy Bitcoin response
    ///   - redirectUrl: Redirect URL
    /// - Returns: Buy Bitcoin response
    /// - Throws: PaymentServiceError if execution fails
    func executeBuyBitcoin(_ prepareResponse: PrepareBuyBitcoinResponse, redirectUrl: String) async throws -> BuyBitcoinResponse

    // MARK: - Payment History

    /// Get payment history
    /// - Returns: Array of payments
    /// - Throws: PaymentServiceError if operation fails
    func getPaymentHistory() async throws -> [Payment]

    /// Get payments with filtering
    /// - Parameters:
    ///   - filters: Payment type filters
    ///   - limit: Maximum number of payments
    ///   - offset: Offset for pagination
    /// - Returns: Array of payments
    /// - Throws: PaymentServiceError if operation fails
    func getPayments(filters: [PaymentType]?, limit: UInt32?, offset: UInt32?) async throws -> [Payment]

    // MARK: - Refund Operations

    /// List refundable swaps
    /// - Returns: Array of refundable swaps
    /// - Throws: PaymentServiceError if operation fails
    func listRefundableSwaps() async throws -> [RefundableSwap]

    /// Execute a refund
    /// - Parameters:
    ///   - swapAddress: Swap address
    ///   - refundAddress: Refund address
    ///   - feeRateSatPerVbyte: Fee rate
    /// - Returns: Refund response
    /// - Throws: PaymentServiceError if execution fails
    func executeRefund(swapAddress: String, refundAddress: String, feeRateSatPerVbyte: UInt32) async throws -> RefundResponse

    // MARK: - Input Processing

    /// Parse input string
    /// - Parameter input: Input string to parse
    /// - Returns: Parsed input type
    /// - Throws: PaymentServiceError if parsing fails
    func parseInput(_ input: String) async throws -> InputType

    /// Validate and prepare payment from input type
    /// - Parameter inputType: Input type to validate and prepare
    /// - Returns: Prepared payment response
    /// - Throws: PaymentServiceError if validation or preparation fails
    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse

    /// Get payment info from input type
    /// - Parameter inputType: Input type
    /// - Returns: Payment info
    func getPaymentInfo(from inputType: InputType) -> PaymentInfo?
}

// MARK: - Payment Service Errors

enum PaymentServiceError: Error, LocalizedError {
    case invalidInput(String)
    case unsupportedPaymentType(String)
    case insufficientFunds(UInt64, UInt64) // required, available
    case paymentPreparationFailed(String)
    case paymentExecutionFailed(String)
    case receivePreparationFailed(String)
    case receiveExecutionFailed(String)
    case invalidAmount(String)
    case networkError
    case walletNotConnected
    case feeEstimationFailed(String)
    case validationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid payment input: \(message)"
        case .unsupportedPaymentType(let type):
            return "Unsupported payment type: \(type)"
        case .insufficientFunds(let required, let available):
            let requiredFormatted = NumberFormatter.satsFormatter.string(from: NSNumber(value: required)) ?? "\(required)"
            let availableFormatted = NumberFormatter.satsFormatter.string(from: NSNumber(value: available)) ?? "\(available)"
            return "Insufficient funds. Required: \(requiredFormatted) sats, Available: \(availableFormatted) sats"
        case .paymentPreparationFailed(let message):
            return "Failed to prepare payment: \(message)"
        case .paymentExecutionFailed(let message):
            return "Payment failed: \(message)"
        case .receivePreparationFailed(let message):
            return "Failed to prepare receive: \(message)"
        case .receiveExecutionFailed(let message):
            return "Failed to create invoice: \(message)"
        case .invalidAmount(let message):
            return "Invalid amount: \(message)"
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .walletNotConnected:
            return "Wallet is not connected. Please connect your wallet first."
        case .feeEstimationFailed(let message):
            return "Failed to estimate fees: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Default Implementation

class DefaultPaymentService: PaymentServiceProtocol {
    
    // MARK: - Dependencies
    
    private let walletService: WalletServiceProtocol
    private let errorHandler: ErrorHandler
    
    // MARK: - Initialization
    
    init(
        walletService: WalletServiceProtocol,
        errorHandler: ErrorHandler = ErrorHandler.shared
    ) {
        self.walletService = walletService
        self.errorHandler = errorHandler
    }
    
    // MARK: - Payment Preparation
    
    func parsePaymentInput(_ input: String) async throws -> InputType {
        do {
            return try await walletService.parsePaymentInput(input)
        } catch {
            throw PaymentServiceError.invalidInput(error.localizedDescription)
        }
    }
    
    func preparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        guard walletService.isConnected else {
            throw PaymentServiceError.walletNotConnected
        }
        
        do {
            let preparedPayment = try await walletService.validateAndPreparePayment(from: inputType)
            
            // Validate amount against balance
            if let feesSat = preparedPayment.feesSat {
                // Extract amount from PayAmount enum
                let recipientAmount: UInt64
                if let amount = preparedPayment.amount {
                    switch amount {
                    case .bitcoin(let receiverAmountSat):
                        recipientAmount = receiverAmountSat
                    case .asset(_, let receiverAmount, _):
                        // For asset payments, convert to sats (this is an approximation)
                        recipientAmount = UInt64(receiverAmount)
                    case .drain:
                        recipientAmount = 0
                    }
                } else {
                    recipientAmount = 0
                }

                let totalRequired = recipientAmount + feesSat
                try await validatePaymentAmount(totalRequired)
            }
            
            return preparedPayment
        } catch let error as WalletServiceError {
            throw PaymentServiceError.paymentPreparationFailed(error.localizedDescription)
        } catch let error as PaymentServiceError {
            throw error
        } catch {
            throw PaymentServiceError.paymentPreparationFailed(error.localizedDescription)
        }
    }
    
    func preparePayment(invoice: String) async throws -> PrepareSendResponse {
        do {
            return try await walletService.preparePayment(destination: invoice)
        } catch let error as WalletServiceError {
            throw PaymentServiceError.paymentPreparationFailed(error.localizedDescription)
        } catch {
            throw PaymentServiceError.paymentPreparationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Payment Execution
    
    func executePayment(_ preparedPayment: PrepareSendResponse) async throws -> SendPaymentResponse {
        guard walletService.isConnected else {
            throw PaymentServiceError.walletNotConnected
        }
        
        do {
            let result = try await walletService.sendPayment(preparedPayment: preparedPayment)
            
            // Log successful payment
            print("✅ Payment executed successfully: \(result.payment.txId ?? "unknown")")
            
            return result
        } catch let error as WalletServiceError {
            throw PaymentServiceError.paymentExecutionFailed(error.localizedDescription)
        } catch {
            throw PaymentServiceError.paymentExecutionFailed(error.localizedDescription)
        }
    }
    
    func sendPayment(to destination: String) async throws -> SendPaymentResponse {
        // Parse input
        let inputType = try await parsePaymentInput(destination)
        
        // Prepare payment
        let preparedPayment = try await preparePayment(from: inputType)
        
        // Execute payment
        return try await executePayment(preparedPayment)
    }
    
    // MARK: - Receive Operations
    
    func prepareReceive(amountSat: UInt64, description: String) async throws -> PrepareReceiveResponse {
        guard walletService.isConnected else {
            throw PaymentServiceError.walletNotConnected
        }
        
        // Validate amount
        guard amountSat > 0 else {
            throw PaymentServiceError.invalidAmount("Amount must be greater than 0")
        }
        
        guard amountSat <= AppConstants.Limits.maxPaymentAmount else {
            throw PaymentServiceError.invalidAmount("Amount exceeds maximum limit")
        }
        
        do {
            return try await walletService.prepareReceivePayment(amountSat: amountSat, description: description)
        } catch let error as WalletServiceError {
            throw PaymentServiceError.receivePreparationFailed(error.localizedDescription)
        } catch {
            throw PaymentServiceError.receivePreparationFailed(error.localizedDescription)
        }
    }
    
    func executeReceive(_ preparedReceive: PrepareReceiveResponse, description: String?) async throws -> ReceivePaymentResponse {
        guard walletService.isConnected else {
            throw PaymentServiceError.walletNotConnected
        }
        
        do {
            let result = try await walletService.receivePayment(preparedReceive: preparedReceive, description: description)
            
            // Log successful receive setup
            print("✅ Receive payment created successfully")
            
            return result
        } catch let error as WalletServiceError {
            throw PaymentServiceError.receiveExecutionFailed(error.localizedDescription)
        } catch {
            throw PaymentServiceError.receiveExecutionFailed(error.localizedDescription)
        }
    }
    
    func createInvoice(amountSat: UInt64, description: String) async throws -> ReceivePaymentResponse {
        // Prepare receive
        let preparedReceive = try await prepareReceive(amountSat: amountSat, description: description)
        
        // Execute receive
        return try await executeReceive(preparedReceive, description: description)
    }
    
    // MARK: - Payment Validation
    
    func validatePaymentAmount(_ amountSat: UInt64) async throws -> Bool {
        guard walletService.isConnected else {
            throw PaymentServiceError.walletNotConnected
        }
        
        do {
            let currentBalance = try await walletService.getBalance()
            
            guard amountSat <= currentBalance else {
                throw PaymentServiceError.insufficientFunds(amountSat, currentBalance)
            }
            
            guard amountSat >= AppConstants.Limits.minPaymentAmount else {
                throw PaymentServiceError.invalidAmount("Amount below minimum limit")
            }
            
            guard amountSat <= AppConstants.Limits.maxPaymentAmount else {
                throw PaymentServiceError.invalidAmount("Amount exceeds maximum limit")
            }
            
            return true
        } catch let error as PaymentServiceError {
            throw error
        } catch {
            throw PaymentServiceError.validationFailed(error.localizedDescription)
        }
    }
    
    func estimatePaymentFee(for destination: String) async throws -> UInt64 {
        do {
            let preparedPayment = try await preparePayment(invoice: destination)
            return preparedPayment.feesSat ?? 0
        } catch {
            throw PaymentServiceError.feeEstimationFailed(error.localizedDescription)
        }
    }
    
    func validatePaymentDestination(_ destination: String) async throws -> Bool {
        do {
            _ = try await parsePaymentInput(destination)
            return true
        } catch {
            throw PaymentServiceError.validationFailed("Invalid payment destination")
        }
    }

    // MARK: - Missing Method Implementations

    func prepareReceiveOnchain(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse {
        return try await walletService.prepareReceiveOnchain()
    }

    func executeReceiveOnchain(_ prepareResponse: PrepareReceiveResponse, description: String) async throws -> ReceivePaymentResponse {
        return try await walletService.receiveOnchain(preparedReceive: prepareResponse)
    }

    func prepareReceiveLiquid(payerAmountSat: UInt64?) async throws -> PrepareReceiveResponse {
        return try await walletService.prepareReceiveLiquid()
    }

    func executeReceiveLiquid(_ prepareResponse: PrepareReceiveResponse, description: String) async throws -> ReceivePaymentResponse {
        return try await walletService.receiveLiquid(preparedReceive: prepareResponse, description: description)
    }

    func prepareBuyBitcoin(provider: BuyBitcoinProvider, amountSat: UInt64) async throws -> PrepareBuyBitcoinResponse {
        return try await walletService.prepareBuyBitcoin(provider: provider)
    }

    func executeBuyBitcoin(_ prepareResponse: PrepareBuyBitcoinResponse, redirectUrl: String) async throws -> BuyBitcoinResponse {
        let url = try await walletService.buyBitcoin(preparedBuy: prepareResponse, redirectUrl: redirectUrl)
        // Convert string URL to BuyBitcoinResponse - this might need adjustment based on actual response type
        return BuyBitcoinResponse(url: url)
    }

    func getPaymentHistory() async throws -> [Payment] {
        return try await walletService.getPaymentHistory()
    }

    func getPayments(filters: [PaymentType]?, limit: UInt32?, offset: UInt32?) async throws -> [Payment] {
        // Create list payments request
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

        // This would need to be implemented in WalletService
        // For now, delegate to a simplified version
        return try await getPaymentHistory()
    }

    func listRefundableSwaps() async throws -> [RefundableSwap] {
        // This would need to be implemented in WalletService
        // For now, return empty array as placeholder
        return []
    }

    func executeRefund(swapAddress: String, refundAddress: String, feeRateSatPerVbyte: UInt32) async throws -> RefundResponse {
        // This would need to be implemented in WalletService
        // For now, throw unsupported operation
        throw PaymentServiceError.unsupportedPaymentType("Refund operations not yet implemented in service layer")
    }

    func parseInput(_ input: String) async throws -> InputType {
        return try await parsePaymentInput(input)
    }

    func validateAndPreparePayment(from inputType: InputType) async throws -> PrepareSendResponse {
        return try await walletService.validateAndPreparePayment(from: inputType)
    }

    func getPaymentInfo(from inputType: InputType) -> PaymentInfo? {
        // This would contain the logic to extract payment info from input type
        // For now, return nil as placeholder
        return nil
    }
}

// MARK: - Helper Extensions

extension NumberFormatter {
    static let satsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}
