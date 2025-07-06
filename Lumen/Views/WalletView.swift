import SwiftUI
import BreezSDKLiquid

struct WalletView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var showingSendView = false
    @State private var showingReceiveView = false
    @State private var showingRefundView = false
    @State private var showingSettings = false
    @State private var refundableSwapsCount = 0

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Balance Card with Info Button
                        VStack(spacing: 12) {
                            BalanceCard(balance: walletManager.balance)
                        }

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

                            // Refund button (only show if there are refunds available)
                            if refundableSwapsCount > 0 {
                                Button(action: {
                                    showingRefundView = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.orange)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Get Money Back")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.orange)

                                            Text("\(refundableSwapsCount) payment\(refundableSwapsCount == 1 ? "" : "s") to refund")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        // Badge with count
                                        Text("\(refundableSwapsCount)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange)
                                            .clipShape(Capsule())
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)

                        // Enhanced Transaction History with real-time updates
                        EnhancedTransactionHistoryView()
                    }
                    .padding(.top)
                }
                .navigationTitle("Lumen")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            ConnectionStatusIcon()

                            Button(action: {
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .refreshable {
                    // Refresh wallet data and payment history
                    await refreshWallet()
                }
                .onAppear {
                    Task {
                        await checkRefundableSwaps()
                    }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func refreshWallet() async {
        // Refresh wallet balance and payment history
        await walletManager.updateBalance()
        await walletManager.refreshPayments()
        await checkRefundableSwaps()
    }

    /// Check for refundable swaps and update the count
    private func checkRefundableSwaps() async {
        do {
            let refundables = try await walletManager.listRefundableSwaps()
            await MainActor.run {
                refundableSwapsCount = refundables.count
            }
        } catch {
            // Silently fail - refund button just won't show
            await MainActor.run {
                refundableSwapsCount = 0
            }
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
                
                SatsAmountView.balance(balance)
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
    @State private var preparedPayment: PrepareSendResponse?
    @State private var showingConfirmation = false
    @State private var showingFeeDetails = false
    
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

                // Fee estimation display
                if let preparedPayment = preparedPayment {
                    VStack(spacing: 12) {
                        FeeEstimationCard(preparedPayment: preparedPayment)

                        Button("View Fee Details") {
                            showingFeeDetails = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
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
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Amount:")
                            SatsAmountView(
                                amount: amountSatsFromPayAmount(preparedPayment.amount),
                                displayMode: .satsOnly,
                                size: .compact,
                                style: .primary
                            )
                        }
                        HStack {
                            Text("Fee:")
                            SatsAmountView.fee(preparedPayment.feesSat ?? 0)
                        }
                        HStack {
                            Text("Total:")
                            SatsAmountView(
                                amount: amountSatsFromPayAmount(preparedPayment.amount) + (preparedPayment.feesSat ?? 0),
                                displayMode: .satsOnly,
                                size: .compact,
                                style: .primary
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFeeDetails) {
                if let preparedPayment = preparedPayment {
                    FeeDetailsSheet(preparedPayment: preparedPayment)
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

                    SatsAmountView(
                        amount: amount,
                        displayMode: .satsOnly,
                        size: .compact,
                        style: .primary
                    )
                }
            } else if let minAmount = paymentInfo.minAmount, let maxAmount = paymentInfo.maxAmount {
                HStack {
                    Text("Amount Range:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        SatsAmountView(
                            amount: minAmount,
                            displayMode: .satsOnly,
                            size: .compact,
                            style: .primary
                        )
                        Text("-")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        SatsAmountView(
                            amount: maxAmount,
                            displayMode: .satsOnly,
                            size: .compact,
                            style: .primary
                        )
                    }
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
                        .fontDesign(.monospaced)
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

// MARK: - Fee Estimation Card

struct FeeEstimationCard: View {
    let preparedPayment: PrepareSendResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.blue)

                Text("Payment Summary")
                    .font(.headline)
                    .foregroundColor(.blue)

                Spacer()

                Text("Ready to Send")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(4)
            }

            // Payment breakdown
            VStack(spacing: 8) {
                FeeRowView(
                    label: "Payment Amount",
                    amount: amountSatsFromPayAmount(preparedPayment.amount),
                    isTotal: false
                )

                FeeRowView(
                    label: "Lightning Fee",
                    amount: preparedPayment.feesSat ?? 0,
                    isTotal: false,
                    color: .orange
                )

                Divider()

                FeeRowView(
                    label: "Total",
                    amount: amountSatsFromPayAmount(preparedPayment.amount) + (preparedPayment.feesSat ?? 0),
                    isTotal: true
                )
            }

            // Fee percentage
            let amountSats = amountSatsFromPayAmount(preparedPayment.amount)
            let feesSats = preparedPayment.feesSat ?? 0
            let feePercentage = amountSats > 0 ? Double(feesSats) / Double(amountSats) * 100 : 0
            if feePercentage > 0 {
                HStack {
                    Text("Fee Rate:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(format: "%.2f%%", feePercentage))
                        .font(.caption)
                        .foregroundColor(feePercentage > 5 ? .orange : .secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FeeRowView: View {
    let label: String
    let amount: UInt64
    let isTotal: Bool
    let color: Color

    init(label: String, amount: UInt64, isTotal: Bool = false, color: Color = .primary) {
        self.label = label
        self.amount = amount
        self.isTotal = isTotal
        self.color = color
    }

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundColor(isTotal ? .primary : .secondary)

            Spacer()

            SatsAmountView(
                amount: amount,
                displayMode: .satsOnly,
                size: isTotal ? .regular : .compact,
                style: color == .primary ? .primary : .secondary
            )
        }
    }
}

// MARK: - Receive Payment View

struct ReceivePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currencyAmount = ""
    @State private var satsAmount = ""
    @State private var description = ""
    @State private var invoice: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preparedReceive: PrepareReceiveResponse?
    @State private var isEditingCurrency = true // true = currency input, false = sats input

    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Receive payment")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                if let invoice = invoice {
                    // Show generated invoice with new layout
                    VStack(spacing: 24) {
                        // QR Code
                        QRCodeView(data: invoice, size: 250)
                            .padding(.horizontal)

                        // Copy Invoice Button
                        Button("Copy invoice") {
                            UIPasteboard.general.string = invoice
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Amount and Fee Information
                        if let preparedReceive = preparedReceive {
                            VStack(spacing: 12) {
                                // You receive amount
                                HStack {
                                    Text("You receive")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    SatsAmountView(
                                        amount: getReceiveAmount(preparedReceive),
                                        displayMode: .both,
                                        size: .regular,
                                        style: .success
                                    )
                                }

                                // Service fee
                                if preparedReceive.feesSat > 0 {
                                    HStack {
                                        Text("Service fee")
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        SatsAmountView.fee(preparedReceive.feesSat)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Invoice creation form with new layout
                    VStack(spacing: 20) {
                        // Amount input section with toggle
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                if isEditingCurrency {
                                    // Currency icon/code
                                    if let currency = currencyManager.selectedCurrency {
                                        HStack(spacing: 8) {
                                            Image(systemName: currency.icon)
                                                .font(.title2)
                                                .foregroundColor(currency.iconColor)

                                            Text(currency.displayCode)
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                        }
                                    } else {
                                        HStack(spacing: 8) {
                                            Image(systemName: "dollarsign.circle")
                                                .font(.title2)
                                                .foregroundColor(.blue)

                                            Text("USD")
                                                .font(.title2)
                                                .fontWeight(.semibold)
                                        }
                                    }

                                    // Currency amount input
                                    TextField("0", text: $currencyAmount)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.leading)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .onChange(of: currencyAmount) { _, newValue in
                                            updateSatsFromCurrency(newValue)
                                        }
                                } else {
                                    // Sats icon
                                    HStack(spacing: 8) {
                                        Image(systemName: "bitcoinsign.circle")
                                            .font(.title2)
                                            .foregroundColor(.orange)

                                        Text("SATS")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }

                                    // Sats amount input
                                    TextField("0", text: $satsAmount)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.leading)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .onChange(of: satsAmount) { _, newValue in
                                            updateCurrencyFromSats(newValue)
                                        }
                                }

                                Spacer()
                            }

                            // Divider line
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(height: 1)

                            // Exchange icon
                            HStack {
                                Button(action: toggleInputMode) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }

                                Spacer()
                            }

                            // Secondary amount display
                            HStack {
                                if isEditingCurrency {
                                    // Show sats equivalent
                                    if let satsValue = convertToSats() {
                                        Text("\(satsValue) sats")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("0 sats")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    // Show currency equivalent
                                    if let currencyValue = convertToCurrency() {
                                        Text(currencyManager.formatFiatAmount(currencyValue))
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(currencyManager.formatFiatAmount(0))
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .padding(.horizontal)

                        // Description field
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Description", text: $description)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        .padding(.horizontal)
                    }
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
                            Text("Create invoice")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentAmountIsEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
                    .disabled(currentAmountIsEmpty || isLoading)
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

    // MARK: - Helper Functions

    private var currentAmountIsEmpty: Bool {
        return isEditingCurrency ? currencyAmount.isEmpty : satsAmount.isEmpty
    }

    private func toggleInputMode() {
        isEditingCurrency.toggle()
    }

    private func updateSatsFromCurrency(_ currencyValue: String) {
        guard let currencyDouble = Double(currencyValue),
              currencyDouble > 0,
              let rate = currencyManager.getCurrentRate(),
              rate > 0 else {
            satsAmount = ""
            return
        }

        let btcAmount = currencyDouble / rate
        let satsValue = btcAmount * 100_000_000.0
        satsAmount = String(UInt64(max(0, satsValue)))
    }

    private func updateCurrencyFromSats(_ satsValue: String) {
        guard let satsUInt = UInt64(satsValue),
              satsUInt > 0,
              let rate = currencyManager.getCurrentRate(),
              rate > 0 else {
            currencyAmount = ""
            return
        }

        let btcAmount = Double(satsUInt) / 100_000_000.0
        let currencyValue = btcAmount * rate
        currencyAmount = String(format: "%.2f", currencyValue)
    }

    private func convertToSats() -> UInt64? {
        if isEditingCurrency {
            guard let currencyValue = Double(currencyAmount),
                  currencyValue > 0,
                  let rate = currencyManager.getCurrentRate(),
                  rate > 0 else {
                return nil
            }

            let btcAmount = currencyValue / rate
            let satsAmount = btcAmount * 100_000_000.0

            return UInt64(max(0, satsAmount))
        } else {
            return UInt64(satsAmount) ?? nil
        }
    }

    private func convertToCurrency() -> Double? {
        guard let satsValue = UInt64(satsAmount),
              satsValue > 0,
              let rate = currencyManager.getCurrentRate(),
              rate > 0 else {
            return nil
        }

        let btcAmount = Double(satsValue) / 100_000_000.0
        return btcAmount * rate
    }

    private func getReceiveAmount(_ preparedReceive: PrepareReceiveResponse) -> UInt64 {
        let totalAmount = amountSatsFromReceiveAmount(preparedReceive.amount)
        return totalAmount - preparedReceive.feesSat
    }

    private func createInvoice() {
        guard let amountSats = convertToSats() else {
            errorMessage = "Invalid amount"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let walletManager = WalletManager.shared

                // First prepare the receive payment to get fee information
                let prepared = try await walletManager.prepareReceivePayment(
                    amountSat: amountSats,
                    description: description.isEmpty ? "Lumen payment" : description
                )

                // Then execute the receive payment
                let response = try await walletManager.receivePayment(
                    prepareResponse: prepared
                )

                await MainActor.run {
                    preparedReceive = prepared
                    invoice = response.destination
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

// MARK: - Receive Fee Card

struct ReceiveFeeCard: View {
    let preparedReceive: PrepareReceiveResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)

                Text("Receive Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                if preparedReceive.feesSat > 0 {
                    HStack {
                        Text("Service Fee:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        SatsAmountView.fee(preparedReceive.feesSat)
                    }

                    HStack {
                        Text("You'll Receive:")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Spacer()

                        SatsAmountView(
                            amount: amountSatsFromReceiveAmount(preparedReceive.amount) - preparedReceive.feesSat,
                            displayMode: .both,
                            size: .compact,
                            style: .success
                        )
                    }
                } else {
                    HStack {
                        Text("No fees for this payment")
                            .font(.caption)
                            .foregroundColor(.green)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Fee Details Sheet

struct FeeDetailsSheet: View {
    let preparedPayment: PrepareSendResponse
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Fee comparison
                    FeeComparisonView(
                        lightningFeeSats: preparedPayment.feesSat ?? 0,
                        paymentAmountSats: amountSatsFromPayAmount(preparedPayment.amount)
                    )

                    // Fee breakdown
                    FeeBreakdownView(preparedPayment: preparedPayment)

                    // Educational content
                    FeeEducationView()
                }
                .padding()
            }
            .navigationTitle("Fee Details")
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

// MARK: - Helper Functions

/// Extracts the amount in satoshis from a PayAmount enum
private func amountSatsFromPayAmount(_ payAmount: PayAmount?) -> UInt64 {
    guard let payAmount = payAmount else { return 0 }

    switch payAmount {
    case .bitcoin(let receiverAmountSat):
        return receiverAmountSat
    case .asset(_, let receiverAmount, _):
        // For assets, we approximate using the receiver amount
        // In a real app, you'd need proper conversion logic
        return UInt64(receiverAmount)
    case .drain:
        return 0 // Drain means send all available, amount is determined dynamically
    }
}

/// Extracts the amount in satoshis from a ReceiveAmount enum
private func amountSatsFromReceiveAmount(_ receiveAmount: ReceiveAmount?) -> UInt64 {
    guard let receiveAmount = receiveAmount else { return 0 }

    switch receiveAmount {
    case .bitcoin(let payerAmountSat):
        return payerAmountSat
    case .asset(_, let payerAmount):
        // For assets, we approximate using the payer amount
        // In a real app, you'd need proper conversion logic
        return UInt64(payerAmount ?? 0)
    }
}

#Preview {
    WalletView()
}
