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
                    LoadingView(text: "Loading payments...")
                } else if filteredPayments.isEmpty {
                    EmptyStateView(
                        icon: emptyStateIcon,
                        title: emptyStateTitle,
                        message: emptyStateMessage
                    )
                } else {
                    PaymentListView(payments: filteredPayments)
                }
            }
            .standardToolbar(
                title: "Payment History",
                displayMode: .large
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilterSheet = true
                    }
                }
            }
            .standardSheet(isPresented: $showingFilterSheet) {
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

    private var emptyStateIcon: String {
        switch selectedFilter {
        case .all: return "list.bullet"
        case .sent: return "arrow.up.circle"
        case .received: return "arrow.down.circle"
        case .pending: return "clock"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all: return "No Payments Yet"
        case .sent: return "No Sent Payments"
        case .received: return "No Received Payments"
        case .pending: return "No Pending Payments"
        case .completed: return "No Completed Payments"
        case .failed: return "No Failed Payments"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all: return "Your payment history will appear here once you start sending and receiving payments."
        case .sent: return "Payments you send will appear here."
        case .received: return "Payments you receive will appear here."
        case .pending: return "Payments currently being processed will appear here."
        case .completed: return "Successfully completed payments will appear here."
        case .failed: return "Failed payments will appear here."
        }
    }
}

// MARK: - Filter Types

enum PaymentFilter: String, CaseIterable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
    
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
                
                Text(filter.rawValue)
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

// MARK: - Legacy PaymentRowView (replaced by shared component)
// Use PaymentRowView from PaymentComponents.swift instead


// MARK: - Legacy Components (replaced by shared components)
// Use LoadingView and EmptyStateView from CoreComponents.swift instead
    
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
        case .all: return "No Payments Yet"
        case .sent: return "No Sent Payments"
        case .received: return "No Received Payments"
        case .pending: return "No Pending Payments"
        case .completed: return "No Completed Payments"
        case .failed: return "No Failed Payments"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "Your payment history will appear here once you start sending and receiving Lightning payments."
        case .sent: return "Payments you send will appear here."
        case .received: return "Payments you receive will appear here."
        case .pending: return "Payments waiting for confirmation will appear here."
        case .completed: return "Successfully completed payments will appear here."
        case .failed: return "Failed payments will appear here."
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
                        
                        Text(filter.rawValue)
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
