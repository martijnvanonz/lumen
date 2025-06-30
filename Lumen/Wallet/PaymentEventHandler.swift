import Foundation
import BreezSDKLiquid
import SwiftUI

/// Handles real-time payment events and UI notifications
class PaymentEventHandler: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recentPayments: [PaymentInfo] = []
    @Published var pendingPayments: [PaymentInfo] = []
    @Published var notifications: [PaymentNotification] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Types
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case syncing
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .syncing: return "Syncing..."
            }
        }
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .connecting, .syncing: return .orange
            case .disconnected: return .red
            }
        }
    }
    
    struct PaymentInfo: Identifiable, Equatable {
        let id = UUID()
        let paymentHash: String
        let amountSat: UInt64
        let direction: PaymentDirection
        let status: PaymentStatus
        let timestamp: Date
        let description: String?
        
        enum PaymentDirection {
            case incoming
            case outgoing
            
            var displayName: String {
                switch self {
                case .incoming: return "Received"
                case .outgoing: return "Sent"
                }
            }
            
            var icon: String {
                switch self {
                case .incoming: return "arrow.down.circle.fill"
                case .outgoing: return "arrow.up.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .incoming: return .green
                case .outgoing: return .orange
                }
            }
        }
        
        enum PaymentStatus {
            case pending
            case succeeded
            case failed
            case waitingConfirmation
            
            var displayName: String {
                switch self {
                case .pending: return "Pending"
                case .succeeded: return "Completed"
                case .failed: return "Failed"
                case .waitingConfirmation: return "Confirming"
                }
            }
            
            var color: Color {
                switch self {
                case .pending, .waitingConfirmation: return .orange
                case .succeeded: return .green
                case .failed: return .red
                }
            }
        }
    }
    
    struct PaymentNotification: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let message: String
        let type: NotificationType
        let timestamp: Date
        
        enum NotificationType {
            case success
            case failure
            case info
            case warning
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .failure: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .failure: return .red
                case .info: return .blue
                case .warning: return .orange
                }
            }
        }
    }
    
    // MARK: - Singleton
    
    static let shared = PaymentEventHandler()
    private init() {}
    
    // MARK: - Event Handling
    
    /// Handles SDK events and updates UI state
    func handleSDKEvent(_ event: SdkEvent) {
        DispatchQueue.main.async {
            switch event {
            case .synced:
                self.connectionStatus = .connected
                self.addNotification(
                    title: "Wallet Synced",
                    message: "Your wallet is up to date",
                    type: .info
                )
                
            case .paymentSucceeded(let details):
                self.handlePaymentSucceeded(details)
                
            case .paymentFailed(let details):
                self.handlePaymentFailed(details)
                
            case .paymentPending(let details):
                self.handlePaymentPending(details)
                
            case .paymentRefunded(let details):
                self.handlePaymentRefunded(details)
                
            case .paymentRefundPending(let details):
                self.handlePaymentRefundPending(details)
                
            case .paymentWaitingConfirmation(let details):
                self.handlePaymentWaitingConfirmation(details)

            case .paymentRefundable(let details):
                self.handlePaymentRefundable(details)

            case .paymentWaitingFeeAcceptance(let details):
                self.handlePaymentWaitingFeeAcceptance(details)

            case .dataSynced(let didPullNewRecords):
                self.handleDataSynced(didPullNewRecords)
            }
        }
    }
    
    // MARK: - Payment Event Handlers
    
    private func handlePaymentSucceeded(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .succeeded)
        addOrUpdatePayment(paymentInfo)
        
        let direction = details.paymentType == .receive ? "received" : "sent"
        addNotification(
            title: "Payment \(direction.capitalized)",
            message: "\(details.amountSat) sats \(direction) successfully",
            type: .success
        )
        
        // Remove from pending if it was there
        removePendingPayment(paymentHash: details.txId ?? "")
    }
    
    private func handlePaymentFailed(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .failed)
        addOrUpdatePayment(paymentInfo)
        
        addNotification(
            title: "Payment Failed",
            message: "Payment of \(details.amountSat) sats failed",
            type: .failure
        )
        
        // Remove from pending
        removePendingPayment(paymentHash: details.txId ?? "")
    }
    
    private func handlePaymentPending(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .pending)
        addPendingPayment(paymentInfo)
        
        let direction = details.paymentType == .receive ? "incoming" : "outgoing"
        addNotification(
            title: "Payment Pending",
            message: "\(direction.capitalized) payment of \(details.amountSat) sats is processing",
            type: .info
        )
    }
    
    private func handlePaymentRefunded(_ details: Payment) {
        addNotification(
            title: "Payment Refunded",
            message: "\(details.amountSat) sats refunded to your wallet",
            type: .info
        )
    }
    
    private func handlePaymentRefundPending(_ details: Payment) {
        addNotification(
            title: "Refund Pending",
            message: "Refund of \(details.amountSat) sats is being processed",
            type: .info
        )
    }
    
    private func handlePaymentWaitingConfirmation(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .waitingConfirmation)
        addOrUpdatePayment(paymentInfo)

        addNotification(
            title: "Waiting for Confirmation",
            message: "Payment of \(details.amountSat) sats is waiting for network confirmation",
            type: .warning
        )
    }

    private func handlePaymentRefundable(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .failed)
        addOrUpdatePayment(paymentInfo)

        addNotification(
            title: "Payment Refundable",
            message: "Payment failed and can be refunded",
            type: .warning
        )
    }

    private func handlePaymentWaitingFeeAcceptance(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .pending)
        addOrUpdatePayment(paymentInfo)

        addNotification(
            title: "Fee Acceptance Required",
            message: "Payment is waiting for fee acceptance",
            type: .info
        )
    }

    private func handleDataSynced(_ didPullNewRecords: Bool) {
        if didPullNewRecords {
            addNotification(
                title: "Data Updated",
                message: "New payment data synchronized",
                type: .info
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createPaymentInfo(from payment: Payment, status: PaymentInfo.PaymentStatus) -> PaymentInfo {
        let direction: PaymentInfo.PaymentDirection = payment.paymentType == .receive ? .incoming : .outgoing
        
        return PaymentInfo(
            paymentHash: payment.txId ?? UUID().uuidString,
            amountSat: payment.amountSat,
            direction: direction,
            status: status,
            timestamp: Date(timeIntervalSince1970: TimeInterval(payment.timestamp)),
            description: nil // Payment type doesn't have description property
        )
    }
    
    private func addOrUpdatePayment(_ payment: PaymentInfo) {
        // Remove existing payment with same hash if it exists
        recentPayments.removeAll { $0.paymentHash == payment.paymentHash }
        
        // Add new payment at the beginning (most recent first)
        recentPayments.insert(payment, at: 0)
        
        // Keep only the last 50 payments
        if recentPayments.count > 50 {
            recentPayments = Array(recentPayments.prefix(50))
        }
    }
    
    private func addPendingPayment(_ payment: PaymentInfo) {
        // Remove existing pending payment with same hash if it exists
        pendingPayments.removeAll { $0.paymentHash == payment.paymentHash }
        
        // Add to pending payments
        pendingPayments.insert(payment, at: 0)
    }
    
    private func removePendingPayment(paymentHash: String) {
        pendingPayments.removeAll { $0.paymentHash == paymentHash }
    }
    
    func addNotification(title: String, message: String, type: PaymentNotification.NotificationType) {
        let notification = PaymentNotification(
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )
        
        notifications.insert(notification, at: 0)
        
        // Keep only the last 20 notifications
        if notifications.count > 20 {
            notifications = Array(notifications.prefix(20))
        }
        
        // Auto-remove success and info notifications after 5 seconds
        if type == .success || type == .info {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.notifications.removeAll { $0.id == notification.id }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Manually dismiss a notification
    func dismissNotification(_ notification: PaymentNotification) {
        notifications.removeAll { $0.id == notification.id }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
    }
    
    /// Update connection status
    func updateConnectionStatus(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            self.connectionStatus = status
        }
    }
    
    /// Get recent payments for display
    func getRecentPayments(limit: Int = 10) -> [PaymentInfo] {
        return Array(recentPayments.prefix(limit))
    }
}
