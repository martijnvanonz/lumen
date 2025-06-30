import SwiftUI

struct WalletView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    BalanceCard(balance: walletManager.balance)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(
                            title: "Send",
                            icon: "arrow.up.circle.fill",
                            color: .orange
                        ) {
                            showingSendView = true
                        }
                        
                        ActionButton(
                            title: "Receive",
                            icon: "arrow.down.circle.fill",
                            color: .green
                        ) {
                            showingReceiveView = true
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions (placeholder)
                    TransactionHistoryView()
                }
                .padding(.top)
            }
            .navigationTitle("Lumen")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh wallet data
                await refreshWallet()
            }
        }
        .sheet(isPresented: $showingSendView) {
            SendPaymentView()
        }
        .sheet(isPresented: $showingReceiveView) {
            ReceivePaymentView()
        }
    }
    
    private func refreshWallet() async {
        // Refresh wallet balance and transactions
        do {
            let _ = try await walletManager.getWalletInfo()
        } catch {
            print("Failed to refresh wallet: \(error)")
        }
    }
}

// MARK: - Balance Card

struct BalanceCard: View {
    let balance: UInt64
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Balance")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(balance) sats")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("≈ $\(formattedUSDValue)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Lightning Network indicator
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                
                Text("Lightning Network")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private var formattedUSDValue: String {
        // Placeholder conversion - in real app, you'd fetch current BTC price
        let btcPrice = 45000.0 // Placeholder
        let btcAmount = Double(balance) / 100_000_000.0 // Convert sats to BTC
        let usdValue = btcAmount * btcPrice
        
        return String(format: "%.2f", usdValue)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction History

struct TransactionHistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full transaction history
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            // Placeholder for transactions
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    TransactionRow(
                        type: index % 2 == 0 ? .received : .sent,
                        amount: UInt64.random(in: 1000...50000),
                        timestamp: Date().addingTimeInterval(-Double(index * 3600))
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    enum TransactionType {
        case sent
        case received
        
        var icon: String {
            switch self {
            case .sent: return "arrow.up.circle.fill"
            case .received: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .sent: return .orange
            case .received: return .green
            }
        }
        
        var prefix: String {
            switch self {
            case .sent: return "-"
            case .received: return "+"
            }
        }
    }
    
    let type: TransactionType
    let amount: UInt64
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type == .sent ? "Sent" : "Received")
                    .font(.headline)
                
                Text(timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(type.prefix)\(amount) sats")
                .font(.headline)
                .foregroundColor(type.color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// MARK: - Send Payment View

struct SendPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var invoice = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Send Payment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lightning Invoice")
                        .font(.headline)
                    
                    TextField("Paste invoice here...", text: $invoice, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button(action: sendPayment) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send Payment")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(invoice.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
                .disabled(invoice.isEmpty || isLoading)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendPayment() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let walletManager = WalletManager.shared
                let prepareResponse = try await walletManager.preparePayment(invoice: invoice)
                let _ = try await walletManager.sendPayment(prepareResponse: prepareResponse)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Receive Payment View

struct ReceivePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var description = ""
    @State private var invoice: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Receive Payment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if let invoice = invoice {
                    // Show generated invoice
                    VStack(spacing: 16) {
                        Text("Payment Request Created")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text(invoice)
                            .font(.caption)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                        
                        Button("Copy Invoice") {
                            UIPasteboard.general.string = invoice
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                } else {
                    // Invoice creation form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount (sats)")
                                .font(.headline)
                            
                            TextField("Enter amount...", text: $amount)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (optional)")
                                .font(.headline)
                            
                            TextField("What's this for?", text: $description)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                if invoice == nil {
                    Button(action: createInvoice) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Invoice")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(amount.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
                    .disabled(amount.isEmpty || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createInvoice() {
        guard let amountSats = UInt64(amount) else {
            errorMessage = "Invalid amount"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let walletManager = WalletManager.shared
                let response = try await walletManager.receivePayment(
                    amountSat: amountSats,
                    description: description.isEmpty ? "Lumen payment" : description
                )
                
                await MainActor.run {
                    invoice = response.invoice
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    WalletView()
}
