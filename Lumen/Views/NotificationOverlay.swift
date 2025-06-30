import SwiftUI

struct NotificationOverlay: View {
    @StateObject private var eventHandler = PaymentEventHandler.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(eventHandler.notifications.prefix(3)) { notification in
                NotificationCard(notification: notification)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: eventHandler.notifications)
    }
}

struct NotificationCard: View {
    let notification: PaymentEventHandler.PaymentNotification
    @StateObject private var eventHandler = PaymentEventHandler.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: notification.type.icon)
                .font(.title3)
                .foregroundColor(notification.type.color)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: {
                eventHandler.dismissNotification(notification)
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notification.type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct ConnectionStatusBar: View {
    @StateObject private var eventHandler = PaymentEventHandler.shared
    
    var body: some View {
        if eventHandler.connectionStatus != .connected {
            HStack(spacing: 8) {
                if eventHandler.connectionStatus == .connecting || eventHandler.connectionStatus == .syncing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: eventHandler.connectionStatus.color))
                } else {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                        .foregroundColor(eventHandler.connectionStatus.color)
                }
                
                Text(eventHandler.connectionStatus.displayText)
                    .font(.caption)
                    .foregroundColor(eventHandler.connectionStatus.color)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(eventHandler.connectionStatus.color.opacity(0.1))
        }
    }
}

// MARK: - Enhanced Transaction History with Real-time Updates

struct EnhancedTransactionHistoryView: View {
    @StateObject private var eventHandler = PaymentEventHandler.shared
    
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
                    // Navigate to full transaction history
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
            } else if eventHandler.pendingPayments.isEmpty {
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
    }
}

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
                    
                    Text("\(payment.direction == .incoming ? "+" : "-")\(payment.amountSat) sats")
                        .font(.headline)
                        .foregroundColor(payment.direction.color)
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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        NotificationOverlay()
        Spacer()
        EnhancedTransactionHistoryView()
    }
    .background(Color(.systemGroupedBackground))
}
