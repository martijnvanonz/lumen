import SwiftUI
import BreezSDKLiquid

// MARK: - Enhanced Transaction History with Real-time Updates

struct EnhancedTransactionHistoryView: View {
    @StateObject private var eventHandler = PaymentEventHandler.shared
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingPaymentHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()

                if !eventHandler.pendingPayments.isEmpty {
                    Text("\(eventHandler.pendingPayments.count) pending")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }

                Button("See All") {
                    showingPaymentHistory = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // Pending payments section
            if !eventHandler.pendingPayments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pending")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(.horizontal)
                    
                    ForEach(eventHandler.pendingPayments.prefix(3)) { payment in
                        EnhancedTransactionRow(payment: payment)
                    }
                }
            }
            
            // Recent completed payments
            let recentPayments = eventHandler.getRecentPayments(limit: 5)
            if !recentPayments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !eventHandler.pendingPayments.isEmpty {
                        Text("Completed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    
                    ForEach(recentPayments) { payment in
                        EnhancedTransactionRow(payment: payment)
                    }
                }
            } else if eventHandler.pendingPayments.isEmpty && eventHandler.recentPayments.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("No recent activity")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("Your payments will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
        .sheet(isPresented: $showingPaymentHistory) {
            PaymentHistoryView()
        }
    }
}

// MARK: - Enhanced Transaction Row

struct EnhancedTransactionRow: View {
    let payment: PaymentEventHandler.PaymentInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with animation
            ZStack {
                Circle()
                    .fill(payment.direction.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                if payment.status == .pending || payment.status == .waitingConfirmation {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: payment.status.color))
                } else {
                    Image(systemName: payment.direction.icon)
                        .font(.title3)
                        .foregroundColor(payment.direction.color)
                }
            }
            
            // Payment details
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(payment.direction.displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    SatsAmountView.transaction(
                        payment.amountSat,
                        isReceive: payment.direction == .incoming
                    )
                }
                
                HStack {
                    Text(payment.status.displayName)
                        .font(.caption)
                        .foregroundColor(payment.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(payment.status.color.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(payment.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let description = payment.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .padding(.horizontal)
    }
}

#Preview {
    EnhancedTransactionHistoryView()
}
