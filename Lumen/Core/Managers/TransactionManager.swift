import Foundation
import BreezSDKLiquid

/// Manages payment history and transaction operations
/// Extracted from WalletManager to provide focused transaction management
@MainActor
class TransactionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var payments: [Payment] = []
    @Published var isLoadingPayments = false
    @Published var paymentError: String?
    @Published var lastPaymentUpdate: Date?
    
    // MARK: - Dependencies
    
    private let paymentService: PaymentServiceProtocol
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Private Properties
    
    private var paymentUpdateTimer: Timer?
    private let paymentUpdateInterval: TimeInterval = 60.0 // Update every minute
    private let maxPaymentsToLoad: UInt32 = 100
    
    // MARK: - Initialization
    
    init(paymentService: PaymentServiceProtocol) {
        self.paymentService = paymentService
    }
    
    deinit {
        // Note: Cannot call async methods in deinit
        // Payment updates will be stopped when the timer is deallocated
        paymentUpdateTimer?.invalidate()
    }
    
    // MARK: - Payment History Management
    
    /// Load payment history from the service
    func loadPaymentHistory() async {
        isLoadingPayments = true
        paymentError = nil
        
        do {
            let loadedPayments = try await paymentService.getPayments(
                filters: nil,
                limit: maxPaymentsToLoad,
                offset: 0
            )
            
            payments = loadedPayments.sorted { $0.timestamp > $1.timestamp }
            lastPaymentUpdate = Date()
            
            print("📋 Loaded \(payments.count) payments")
        } catch {
            paymentError = error.localizedDescription
            errorHandler.logError(.payment(.historyLoadFailed), context: "Payment history load")
            print("❌ Failed to load payment history: \(error)")
        }
        
        isLoadingPayments = false
    }
    
    /// Refresh payment history
    func refreshPaymentHistory() async {
        await loadPaymentHistory()
    }
    
    /// Start automatic payment history updates
    func startPaymentUpdates() {
        stopPaymentUpdates() // Stop any existing timer
        
        paymentUpdateTimer = Timer.scheduledTimer(withTimeInterval: paymentUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.loadPaymentHistory()
            }
        }
        
        print("⏰ Started automatic payment updates every \(paymentUpdateInterval) seconds")
    }
    
    /// Stop automatic payment history updates
    func stopPaymentUpdates() {
        paymentUpdateTimer?.invalidate()
        paymentUpdateTimer = nil
        print("⏹️ Stopped automatic payment updates")
    }
    
    /// Get filtered payments by type
    func getPayments(ofType type: PaymentType) -> [Payment] {
        return payments.filter { $0.paymentType == type }
    }
    
    /// Get recent payments (last 24 hours)
    func getRecentPayments() -> [Payment] {
        let oneDayAgo = Date().timeIntervalSince1970 - 86400 // 24 hours in seconds
        return payments.filter { $0.timestamp > UInt64(oneDayAgo) }
    }
    
    /// Get payments within a date range
    func getPayments(from startDate: Date, to endDate: Date) -> [Payment] {
        let startTimestamp = UInt64(startDate.timeIntervalSince1970)
        let endTimestamp = UInt64(endDate.timeIntervalSince1970)
        
        return payments.filter { payment in
            payment.timestamp >= startTimestamp && payment.timestamp <= endTimestamp
        }
    }
    
    /// Find payment by transaction ID
    func findPayment(byTxId txId: String) -> Payment? {
        return payments.first { $0.txId == txId }
    }
    
    /// Get total sent amount
    func getTotalSentAmount() -> UInt64 {
        return getPayments(ofType: .send).reduce(0) { $0 + $1.amountSat }
    }
    
    /// Get total received amount
    func getTotalReceivedAmount() -> UInt64 {
        return getPayments(ofType: .receive).reduce(0) { $0 + $1.amountSat }
    }
    
    /// Get payment statistics
    func getPaymentStatistics() -> PaymentStatistics {
        let sentPayments = getPayments(ofType: .send)
        let receivedPayments = getPayments(ofType: .receive)
        
        return PaymentStatistics(
            totalPayments: payments.count,
            sentCount: sentPayments.count,
            receivedCount: receivedPayments.count,
            totalSentAmount: sentPayments.reduce(0) { $0 + $1.amountSat },
            totalReceivedAmount: receivedPayments.reduce(0) { $0 + $1.amountSat },
            averageSentAmount: sentPayments.isEmpty ? 0 : sentPayments.reduce(0) { $0 + $1.amountSat } / UInt64(sentPayments.count),
            averageReceivedAmount: receivedPayments.isEmpty ? 0 : receivedPayments.reduce(0) { $0 + $1.amountSat } / UInt64(receivedPayments.count)
        )
    }
    
    /// Clear payment history (used during logout/reset)
    func clearPaymentHistory() {
        payments.removeAll()
        paymentError = nil
        lastPaymentUpdate = nil
        stopPaymentUpdates()
        print("🗑️ Payment history cleared")
    }
    
    /// Load more payments (pagination)
    func loadMorePayments() async {
        guard !isLoadingPayments else { return }
        
        isLoadingPayments = true
        
        do {
            let additionalPayments = try await paymentService.getPayments(
                filters: nil,
                limit: maxPaymentsToLoad,
                offset: UInt32(payments.count)
            )
            
            // Append new payments and sort
            payments.append(contentsOf: additionalPayments)
            payments = payments.sorted { $0.timestamp > $1.timestamp }
            
            print("📋 Loaded \(additionalPayments.count) additional payments")
        } catch {
            paymentError = error.localizedDescription
            errorHandler.logError(.payment(.historyLoadFailed), context: "Load more payments")
            print("❌ Failed to load more payments: \(error)")
        }
        
        isLoadingPayments = false
    }
    
    /// Check if there are more payments to load
    func hasMorePayments() -> Bool {
        // This is a simple heuristic - in a real implementation,
        // the service would provide this information
        return payments.count >= maxPaymentsToLoad
    }
}

// MARK: - Supporting Types

struct PaymentStatistics {
    let totalPayments: Int
    let sentCount: Int
    let receivedCount: Int
    let totalSentAmount: UInt64
    let totalReceivedAmount: UInt64
    let averageSentAmount: UInt64
    let averageReceivedAmount: UInt64
    
    var netAmount: Int64 {
        return Int64(totalReceivedAmount) - Int64(totalSentAmount)
    }
    
    var isNetPositive: Bool {
        return netAmount > 0
    }
}

// MARK: - Payment Formatting Helpers

extension TransactionManager {
    
    /// Format payment amount with currency
    func formatPaymentAmount(_ payment: Payment) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        let amountString = formatter.string(from: NSNumber(value: payment.amountSat)) ?? "0"
        return "\(amountString) sats"
    }
    
    /// Format payment date
    func formatPaymentDate(_ payment: Payment) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(payment.timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Get payment direction display string
    func getPaymentDirection(_ payment: Payment) -> String {
        switch payment.paymentType {
        case .send:
            return "Sent"
        case .receive:
            return "Received"
        }
    }
    
    /// Get payment status display string
    func getPaymentStatus(_ payment: Payment) -> String {
        switch payment.status {
        case .created:
            return "Created"
        case .pending:
            return "Pending"
        case .complete:
            return "Complete"
        case .failed:
            return "Failed"
        case .timedOut:
            return "Timed Out"
        case .refundable:
            return "Refundable"
        case .refundPending:
            return "Refund Pending"
        case .waitingFeeAcceptance:
            return "Waiting Fee Acceptance"
        }
    }
}
