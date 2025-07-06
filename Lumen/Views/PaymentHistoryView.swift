import SwiftUI
import BreezSDKLiquid

struct PaymentHistoryView: View {
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var eventHandler = PaymentEventHandler.shared
    @State private var selectedFilter: PaymentFilter = .all
    @State private var showingFilterSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter bar
                FilterBar(selectedFilter: $selectedFilter, showingFilterSheet: $showingFilterSheet)
                
                // Payment list
                if walletManager.isLoadingPayments {
                    LoadingView()
                } else if filteredPayments.isEmpty {
                    EmptyStateView(filter: selectedFilter)
                } else {
                    PaymentListView(payments: filteredPayments)
                }
            }
            .navigationTitle(L("payment_history"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("filter")) {
                        showingFilterSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(selectedFilter: $selectedFilter)
            }
            .refreshable {
                await walletManager.refreshPayments()
            }
        }
    }
    
    private var filteredPayments: [Payment] {
        let payments = walletManager.payments
        
        switch selectedFilter {
        case .all:
            return payments
        case .sent:
            return payments.filter { $0.paymentType == .send }
        case .received:
            return payments.filter { $0.paymentType == .receive }
        case .pending:
            return payments.filter { $0.status == .pending }
        case .completed:
            return payments.filter { $0.status == .complete }
        case .failed:
            return payments.filter { $0.status == .failed }
        }
    }
}

// MARK: - Filter Types

enum PaymentFilter: String, CaseIterable {
    case all = "all"
    case sent = "sent"
    case received = "received"
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .all: return L("all_payments")
        case .sent: return L("sent_payments")
        case .received: return L("received_payments")
        case .pending: return L("pending_payments")
        case .completed: return L("completed_payments")
        case .failed: return L("failed_payments")
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .sent: return "arrow.up.circle"
        case .received: return "arrow.down.circle"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .sent: return .orange
        case .received: return .green
        case .pending: return .yellow
        case .completed: return .green
        case .failed: return .red
        }
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    @Binding var selectedFilter: PaymentFilter
    @Binding var showingFilterSheet: Bool
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PaymentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

struct FilterChip: View {
    let filter: PaymentFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? filter.color : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Payment List

struct PaymentListView: View {
    let payments: [Payment]
    
    var body: some View {
        List {
            ForEach(payments, id: \.txId) { payment in
                PaymentRowView(payment: payment)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct PaymentRowView: View {
    let payment: Payment
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundColor(statusColor)
            }
            
            // Payment details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(paymentTypeText)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    SatsAmountView.transaction(payment.amountSat, isReceive: payment.paymentType == .receive)
                }
                
                HStack {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(timestampText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Payment details based on type
                if let destination = payment.destination, !destination.isEmpty {
                    Text(destination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let txId = payment.txId {
                    Text("ID: \(txId.prefix(16))...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var paymentTypeText: String {
        switch payment.paymentType {
        case .send: return L("sent")
        case .receive: return L("received")
        }
    }

    private var statusText: String {
        switch payment.status {
        case .created: return L("created")
        case .pending: return L("pending")
        case .complete: return L("completed")
        case .failed: return L("failed")
        case .timedOut: return L("timed_out")
        case .refundable: return L("refundable")
        case .refundPending: return L("refund_pending")
        case .waitingFeeAcceptance: return L("waiting_fee_acceptance")
        }
    }
    
    private var statusIcon: String {
        switch payment.status {
        case .created: return "plus.circle"
        case .pending: return "clock"
        case .complete: return payment.paymentType == .send ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .timedOut: return "clock.badge.xmark"
        case .refundable: return "arrow.counterclockwise.circle"
        case .refundPending: return "arrow.counterclockwise.circle.fill"
        case .waitingFeeAcceptance: return "clock.arrow.circlepath"
        }
    }
    
    private var statusColor: Color {
        switch payment.status {
        case .created: return .blue
        case .pending: return .orange
        case .complete: return payment.paymentType == .send ? .orange : .green
        case .failed: return .red
        case .timedOut: return .red
        case .refundable: return .yellow
        case .refundPending: return .orange
        case .waitingFeeAcceptance: return .blue
        }
    }

    
    private var timestampText: String {
        let date = Date(timeIntervalSince1970: TimeInterval(payment.timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Loading and Empty States

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading payments...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    let filter: PaymentFilter
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch filter {
        case .all: return "list.bullet"
        case .sent: return "arrow.up.circle"
        case .received: return "arrow.down.circle"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all: return L("no_payments_yet")
        case .sent: return L("no_sent_payments")
        case .received: return L("no_received_payments")
        case .pending: return L("no_pending_payments")
        case .completed: return L("no_completed_payments")
        case .failed: return L("no_failed_payments")
        }
    }

    private var emptyStateMessage: String {
        switch filter {
        case .all: return L("no_payments_message")
        case .sent: return L("no_sent_message")
        case .received: return L("no_received_message")
        case .pending: return L("no_pending_message")
        case .completed: return L("no_completed_message")
        case .failed: return L("no_failed_message")
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Binding var selectedFilter: PaymentFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PaymentFilter.allCases, id: \.self) { filter in
                    HStack {
                        Image(systemName: filter.icon)
                            .foregroundColor(filter.color)
                            .frame(width: 24)
                        
                        Text(filter.displayName)
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedFilter = filter
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filter Payments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PaymentHistoryView()
}
