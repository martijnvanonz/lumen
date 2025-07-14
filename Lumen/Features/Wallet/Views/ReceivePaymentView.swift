import SwiftUI
import BreezSDKLiquid

/// Modern receive payment view using new service architecture
/// Replaces the old monolithic ReceivePaymentView with clean, component-based implementation
struct ModernReceivePaymentView: View {
    
    // MARK: - View Models & Services

    @StateObject private var walletViewModel = WalletViewModel.create()
    @StateObject private var errorHandler = ErrorHandler.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @ObservedObject private var eventHandler = PaymentEventHandler.shared
    @Environment(\.dismiss) private var dismiss

    // Services
    private let walletService = BreezWalletService()
    private let paymentService: PaymentServiceProtocol

    // MARK: - Initialization

    init() {
        self.paymentService = DefaultPaymentService(walletService: walletService)
    }
    
    // MARK: - UI State
    
    @State private var currencyAmount = ""
    @State private var satsAmount = ""
    @State private var description = ""
    @State private var invoice: String?
    @State private var isLoading = false
    @State private var preparedReceive: PrepareReceiveResponse?
    @State private var isEditingCurrency = true // true = currency input, false = sats input
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                Text("Receive Payment")
                    .font(DesignSystem.Typography.title(weight: .bold))
                    .padding(.top)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                
                // Main content
                if let invoice = invoice {
                    // Show generated invoice
                    invoiceDisplaySection
                } else {
                    // Invoice creation form
                    invoiceCreationSection
                }
                
                // Error display
                if errorHandler.currentError != nil {
                    InlineErrorView(error: errorHandler.currentError)
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // Loading indicator
                if isLoading {
                    LoadingStateView.inline("Creating invoice...")
                        .padding()
                }
                
                Spacer()
                
                // Create invoice button
                if invoice == nil {
                    createInvoiceButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    StandardButton(title: "Cancel", action: { dismiss() })
                        .style(.tertiary)
                        .size(.compact)
                }
            }
        }
        .errorAlert(errorHandler: errorHandler)
        .onChange(of: eventHandler.showPaymentSuccess) { _, showSuccess in
            if showSuccess {
                dismiss()
            }
        }
    }
    
    // MARK: - Invoice Display Section
    
    @ViewBuilder
    private var invoiceDisplaySection: some View {
        if let invoice = invoice {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // QR Code
                QRCodeView(data: invoice, size: 250)
                    .padding(.horizontal)
                
                // Copy Invoice Button
                StandardButton(
                    title: "Copy Invoice",
                    action: { UIPasteboard.general.string = invoice }
                )
                .style(.primary)
                .size(.large)
                .icon("doc.on.clipboard")
                .padding(.horizontal)
                
                // Amount and Fee Information
                if let preparedReceive = preparedReceive {
                    receiveInfoCard(preparedReceive)
                }
            }
        }
    }
    
    // MARK: - Invoice Creation Section
    
    @ViewBuilder
    private var invoiceCreationSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Amount input section
            amountInputSection
            
            // Description field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Description (optional)")
                    .font(DesignSystem.Typography.caption(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Payment description", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DesignSystem.Typography.body())
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Amount Input Section
    
    @ViewBuilder
    private var amountInputSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Primary amount input
            HStack(spacing: DesignSystem.Spacing.md) {
                if isEditingCurrency {
                    // Currency input mode
                    currencyInputView
                } else {
                    // Sats input mode
                    satsInputView
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Divider
            Rectangle()
                .fill(DesignSystem.Colors.borderPrimary)
                .frame(height: 1)
                .padding(.horizontal)
            
            // Toggle and secondary amount
            HStack {
                Button(action: toggleInputMode) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(DesignSystem.Typography.title3())
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                // Secondary amount display
                secondaryAmountView
            }
            .padding(.horizontal)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .padding(.horizontal)
    }
    
    // MARK: - Currency Input View
    
    @ViewBuilder
    private var currencyInputView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let currency = currencyManager.selectedCurrency {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: currency.icon)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(currency.iconColor)
                    
                    Text(currency.displayCode)
                        .font(DesignSystem.Typography.title2(weight: .semibold))
                }
            } else {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "dollarsign.circle")
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("USD")
                        .font(DesignSystem.Typography.title2(weight: .semibold))
                }
            }
            
            TextField("0", text: $currencyAmount)
                .font(DesignSystem.Typography.largeTitle(weight: .bold))
                .keyboardType(.decimalPad)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: currencyAmount) { _, newValue in
                    updateSatsFromCurrency(newValue)
                }
        }
    }
    
    // MARK: - Sats Input View
    
    @ViewBuilder
    private var satsInputView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: DesignSystem.Icons.bitcoin)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(.orange)
                
                Text("SATS")
                    .font(DesignSystem.Typography.title2(weight: .semibold))
            }
            
            TextField("0", text: $satsAmount)
                .font(DesignSystem.Typography.largeTitle(weight: .bold))
                .keyboardType(.numberPad)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: satsAmount) { _, newValue in
                    updateCurrencyFromSats(newValue)
                }
        }
    }
    
    // MARK: - Secondary Amount View
    
    @ViewBuilder
    private var secondaryAmountView: some View {
        if isEditingCurrency {
            // Show sats equivalent
            if let satsValue = convertToSats() {
                Text("\(satsValue) sats")
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                Text("0 sats")
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } else {
            // Show currency equivalent
            if let currencyValue = convertToCurrency() {
                Text(currencyManager.formatFiatAmount(currencyValue))
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                Text(currencyManager.formatFiatAmount(0))
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Create Invoice Button
    
    @ViewBuilder
    private var createInvoiceButton: some View {
        StandardButton(
            title: "Create Invoice",
            action: createInvoice
        )
        .style(.primary)
        .size(.large)
        .loading(isLoading)
        .disabled(currentAmountIsEmpty || isLoading)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Receive Info Card
    
    @ViewBuilder
    private func receiveInfoCard(_ preparedReceive: PrepareReceiveResponse) -> some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // You receive amount
            HStack {
                Text("You receive")
                    .font(DesignSystem.Typography.body(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                AmountDisplayCard.transaction(
                    getReceiveAmount(preparedReceive),
                    title: nil
                )
                .size(.compact)
            }
            
            // Service fee
            if preparedReceive.feesSat > 0 {
                HStack {
                    Text("Service fee")
                        .font(DesignSystem.Typography.body(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    AmountDisplayCard.fee(preparedReceive.feesSat)
                        .size(.compact)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Helper Methods

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
            errorHandler.handle(
                PaymentServiceError.invalidAmount("Invalid amount"),
                context: "Create invoice"
            )
            return
        }

        isLoading = true
        errorHandler.clearError()

        Task {
            do {
                // Use the payment service to create the invoice
                let response = try await paymentService.createInvoice(
                    amountSat: amountSats,
                    description: description.isEmpty ? "Lumen payment" : description
                )

                // Get the prepared receive for fee information
                let prepared = try await paymentService.prepareReceive(
                    amountSat: amountSats,
                    description: description.isEmpty ? "Lumen payment" : description
                )

                await MainActor.run {
                    preparedReceive = prepared
                    invoice = response.destination
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorHandler.handle(error, context: "Create invoice")
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Helper Functions

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

// MARK: - Preview

#Preview {
    ModernReceivePaymentView()
}
