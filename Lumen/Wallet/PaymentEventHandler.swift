import Foundation
import BreezSDKLiquid
import SwiftUI
import UIKit

/// Handles real-time payment events
class PaymentEventHandler: ObservableObject {

    // MARK: - Published Properties

    @Published var recentPayments: [PaymentInfo] = []
    @Published var pendingPayments: [PaymentInfo] = []
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var showPaymentSuccess: Bool = false
    @Published var lastSuccessfulPayment: PaymentInfo?
    
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
                // Connection status is now shown via the top-right icon instead of toast notifications
                
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
        Task { @MainActor in
            let paymentInfo = createPaymentInfo(from: details, status: .succeeded)
            addOrUpdatePayment(paymentInfo)

            // Show success feedback for received payments
            if details.paymentType == .receive {
                showSuccessFeedback(for: paymentInfo)
            }

            // Remove from pending if it was there
            removePendingPayment(paymentHash: details.txId ?? "")
        }
    }
    
    private func handlePaymentFailed(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .failed)
        addOrUpdatePayment(paymentInfo)

        // Remove from pending
        removePendingPayment(paymentHash: details.txId ?? "")
    }
    
    private func handlePaymentPending(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .pending)
        addPendingPayment(paymentInfo)
    }
    
    private func handlePaymentRefunded(_ details: Payment) {
        // Payment refunded - no action needed for now
    }
    
    private func handlePaymentRefundPending(_ details: Payment) {
        // Refund pending - no action needed for now
    }
    
    private func handlePaymentWaitingConfirmation(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .waitingConfirmation)
        addOrUpdatePayment(paymentInfo)

        // Show success feedback for received payments (as per Breez SDK docs)
        if details.paymentType == .receive {
            showSuccessFeedback(for: paymentInfo)
        }
    }

    private func handlePaymentRefundable(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .failed)
        addOrUpdatePayment(paymentInfo)
    }

    private func handlePaymentWaitingFeeAcceptance(_ details: Payment) {
        let paymentInfo = createPaymentInfo(from: details, status: .pending)
        addOrUpdatePayment(paymentInfo)
    }

    private func handleDataSynced(_ didPullNewRecords: Bool) {
        // Data synced - no action needed for now
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
    
    // MARK: - Success Feedback

    private func showSuccessFeedback(for payment: PaymentInfo) {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Show visual feedback
        lastSuccessfulPayment = payment
        showPaymentSuccess = true

        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showPaymentSuccess = false
            self.lastSuccessfulPayment = nil
        }
    }

    // MARK: - Public Methods

    /// Manually dismiss success feedback
    func dismissSuccessFeedback() {
        showPaymentSuccess = false
        lastSuccessfulPayment = nil
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
