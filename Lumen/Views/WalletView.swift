import SwiftUI

struct WalletView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    @State private var showingRefundView = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Connection status bar
                        ConnectionStatusBar()

                        // Network status bar
                        NetworkStatusView()

                        // Balance Card
                        BalanceCard(balance: walletManager.balance)

                        // Action Buttons
                        VStack(spacing: 16) {
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

                            // Refund button (smaller, secondary action)
                            Button(action: {
                                showingRefundView = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.counterclockwise.circle")
                                        .font(.title3)
                                        .foregroundColor(.blue)

                                    Text("Manage Refunds")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)

                        // Enhanced Transaction History with real-time updates
                        EnhancedTransactionHistoryView()
                    }
                    .padding(.top)
                }
                .navigationTitle("Lumen")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    // Refresh wallet data and payment history
                    await refreshWallet()
                }

                // Notification overlay
                VStack {
                    NotificationOverlay()
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $showingSendView) {
            SendPaymentView()
        }
        .sheet(isPresented: $showingReceiveView) {
            ReceivePaymentView()
        }
        .sheet(isPresented: $showingRefundView) {
            RefundView()
        }
    }
    
    private func refreshWallet() async {
        // Refresh wallet balance and payment history
        await walletManager.updateBalance()
        await walletManager.refreshPayments()
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



// MARK: - Send Payment View

struct SendPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var paymentInfo: PaymentInputInfo?
    @State private var preparedPayment: PreparePayResponse?
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Send Payment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment Details")
                        .font(.headline)

                    TextField("Paste invoice, Lightning address, or Bitcoin address...", text: $inputText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                        .onChange(of: inputText) { _, newValue in
                            if !newValue.isEmpty {
                                parseInput()
                            } else {
                                paymentInfo = nil
                                preparedPayment = nil
                            }
                        }
                }
                .padding(.horizontal)

                // Payment info display
                if let paymentInfo = paymentInfo {
                    PaymentInfoCard(paymentInfo: paymentInfo)
                        .padding(.horizontal)
                }

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if paymentInfo != nil && preparedPayment == nil && !isLoading {
                        Button(action: preparePayment) {
                            Text("Prepare Payment")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if let preparedPayment = preparedPayment {
                        Button(action: { showingConfirmation = true }) {
                            Text("Send Payment")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if isLoading {
                        ProgressView("Processing...")
                            .padding()
                    }
                }
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
            .alert("Confirm Payment", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Send") {
                    sendPayment()
                }
            } message: {
                if let preparedPayment = preparedPayment {
                    Text("Send \(preparedPayment.amountSat) sats with \(preparedPayment.feesSat) sats fee?")
                }
            }
        }
    }
    
    private func parseInput() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        Task {
            do {
                let walletManager = WalletManager.shared
                let inputType = try await walletManager.parseInput(inputText)
                let info = walletManager.getPaymentInfo(from: inputType)

                await MainActor.run {
                    paymentInfo = info
                    errorMessage = nil

                    // Check for expired payments
                    if info.isExpired {
                        errorMessage = "This payment request has expired"
                    }
                }
            } catch {
                await MainActor.run {
                    paymentInfo = nil
                    preparedPayment = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func preparePayment() {
        guard let paymentInfo = paymentInfo else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let walletManager = WalletManager.shared
                let inputType = try await walletManager.parseInput(inputText)
                let prepared = try await walletManager.validateAndPreparePayment(from: inputType)

                await MainActor.run {
                    preparedPayment = prepared
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

    private func sendPayment() {
        guard let preparedPayment = preparedPayment else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let walletManager = WalletManager.shared
                let _ = try await walletManager.sendPayment(prepareResponse: preparedPayment)

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

// MARK: - Payment Info Card

struct PaymentInfoCard: View {
    let paymentInfo: PaymentInputInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type
            HStack {
                Image(systemName: paymentInfo.type.icon)
                    .foregroundColor(paymentInfo.type.color)

                Text(paymentInfo.type.displayName)
                    .font(.headline)
                    .foregroundColor(paymentInfo.type.color)

                Spacer()

                if paymentInfo.isExpired {
                    Text("EXPIRED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                }
            }

            // Amount information
            if let amount = paymentInfo.amount {
                HStack {
                    Text("Amount:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(amount) sats")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            } else if let minAmount = paymentInfo.minAmount, let maxAmount = paymentInfo.maxAmount {
                HStack {
                    Text("Amount Range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(minAmount) - \(maxAmount) sats")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // Description
            if let description = paymentInfo.description, !description.isEmpty {
                HStack {
                    Text("Description:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(description)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Destination
            if let destination = paymentInfo.destination {
                HStack {
                    Text("To:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(destination.count > 20 ? "\(destination.prefix(20))..." : destination)
                        .font(.subheadline)
                        .fontFamily(.monospaced)
                }
            }

            // Expiry
            if let expiry = paymentInfo.expiry {
                HStack {
                    Text("Expires:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(expiry, style: .relative)
                        .font(.subheadline)
                        .foregroundColor(paymentInfo.isExpired ? .red : .primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(paymentInfo.type.color.opacity(0.3), lineWidth: 1)
                )
        )
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
