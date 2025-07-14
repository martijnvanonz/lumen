import SwiftUI
import BreezSDKLiquid

/// Modern send payment view using new service architecture
/// Replaces the old monolithic SendPaymentView with clean, component-based implementation
struct ModernSendPaymentView: View {
    
    // MARK: - View Models & Services
    
    @StateObject private var walletViewModel = WalletViewModel.create()
    @StateObject private var errorHandler = ErrorHandler.shared
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - UI State
    
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var paymentInfo: PaymentInputInfo?
    @State private var preparedPayment: PrepareSendResponse?
    @State private var showingQRScanner = true
    @State private var scannedCode: String?
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                Text("Send Payment")
                    .font(DesignSystem.Typography.title(weight: .bold))
                    .padding(.top)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                
                // Main content
                if preparedPayment == nil {
                    // QR Scanner and input section
                    qrScannerSection
                } else {
                    // Payment details and confirmation
                    paymentDetailsSection
                }
                
                // Error display
                if errorHandler.currentError != nil {
                    InlineErrorView(error: errorHandler.currentError)
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Loading indicator
                if isLoading {
                    LoadingStateView.inline("Processing payment...")
                        .padding()
                }
                
                Spacer()
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
    }
    
    // MARK: - QR Scanner Section
    
    @ViewBuilder
    private var qrScannerSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // QR Scanner
            QRScannerView(scannedCode: $scannedCode) { scannedCode in
                inputText = scannedCode
                parseAndPreparePayment()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .padding(.horizontal)
            
            // Paste button
            StandardButton(
                title: "Paste Invoice",
                action: pasteFromClipboard
            )
            .style(.secondary)
            .size(.large)
            .icon("doc.on.clipboard")
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    // MARK: - Payment Details Section
    
    @ViewBuilder
    private var paymentDetailsSection: some View {
        if let preparedPayment = preparedPayment {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Payment info card
                PaymentDetailsCard(
                    preparedPayment: preparedPayment,
                    paymentInfo: paymentInfo
                )
                .padding(.horizontal)
                
                // Swipe to send
                SwipeToSendView(
                    totalAmount: extractTotalAmount(from: preparedPayment)
                ) {
                    sendPayment()
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            inputText = clipboardString
            parseAndPreparePayment()
        }
    }
    
    private func parseAndPreparePayment() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        errorHandler.clearError()
        paymentInfo = nil
        preparedPayment = nil
        
        Task {
            do {
                // Parse input using wallet service
                let inputType = try await walletViewModel.parsePaymentInput(inputText)
                
                await MainActor.run {
                    paymentInfo = walletViewModel.getPaymentInfo(from: inputType)
                }
                
                // Prepare payment using payment service
                let prepared = try await walletViewModel.preparePayment(from: inputType)
                
                await MainActor.run {
                    preparedPayment = prepared
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorHandler.handle(error, context: "Prepare payment")
                    isLoading = false
                }
            }
        }
    }
    
    private func sendPayment() {
        guard let preparedPayment = preparedPayment else { return }
        
        isLoading = true
        errorHandler.clearError()
        
        Task {
            do {
                let _ = try await walletViewModel.sendPayment(preparedPayment: preparedPayment)
                
                // Add haptic feedback for success
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Add haptic feedback for error
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                await MainActor.run {
                    errorHandler.handle(error, context: "Send payment")
                    isLoading = false
                }
            }
        }
    }
    
    private func extractTotalAmount(from preparedPayment: PrepareSendResponse) -> UInt64 {
        let amount = extractPaymentAmount(from: preparedPayment, paymentInfo: paymentInfo)
        let fees = preparedPayment.feesSat ?? 0
        return amount + fees
    }
    
    private func extractPaymentAmount(from preparedPayment: PrepareSendResponse, paymentInfo: PaymentInputInfo?) -> UInt64 {
        // Extract amount from payment info or use a default
        if let amount = paymentInfo?.amount {
            return amount
        }

        // Fallback: try to extract from prepared payment
        // This is a simplified implementation - the actual amount extraction
        // would depend on the specific PreparedSendResponse structure
        return 1000 // Placeholder - needs proper implementation
    }
}

// MARK: - Payment Details Card

struct PaymentDetailsCard: View {
    let preparedPayment: PrepareSendResponse
    let paymentInfo: PaymentInputInfo?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: getPaymentTypeIcon())
                    .foregroundColor(DesignSystem.Colors.primary)
                Text(getPaymentTypeTitle())
                    .font(DesignSystem.Typography.headline(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(.bottom, DesignSystem.Spacing.sm)

            // Amount row
            HStack {
                Text("Amount:")
                    .font(DesignSystem.Typography.body(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                AmountDisplayCard.transaction(
                    extractPaymentAmount(),
                    title: nil
                )
                .size(.compact)
            }

            // Fee row
            HStack {
                Text("Fee:")
                    .font(DesignSystem.Typography.body(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                AmountDisplayCard.fee(preparedPayment.feesSat ?? 0)
                    .size(.compact)
            }

            Divider()

            // Total row
            HStack {
                Text("Total:")
                    .font(DesignSystem.Typography.headline(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                AmountDisplayCard.balance(
                    extractPaymentAmount() + (preparedPayment.feesSat ?? 0)
                )
                .size(.compact)
            }

            // Description if available
            if let description = paymentInfo?.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Description:")
                        .font(DesignSystem.Typography.body(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(description)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }

    private func getPaymentTypeTitle() -> String {
        guard let paymentInfo = paymentInfo else { return "Lightning Payment" }

        switch paymentInfo.type {
        case .bolt11: return "Lightning Invoice"
        case .lnUrlPay: return "Lightning Address"
        case .bolt12Offer: return "BOLT12 Offer"
        case .bitcoinAddress: return "Bitcoin Address"
        case .liquidAddress: return "Liquid Address"
        case .nodeId: return "Node ID"
        case .url: return "URL"
        case .lnUrlWithdraw: return "LNURL Withdraw"
        case .lnUrlAuth: return "LNURL Auth"
        case .unsupported: return "Unsupported"
        }
    }

    private func getPaymentTypeIcon() -> String {
        guard let paymentInfo = paymentInfo else { return DesignSystem.Icons.lightning }

        switch paymentInfo.type {
        case .bolt11: return DesignSystem.Icons.lightning
        case .lnUrlPay: return "at.circle.fill"
        case .bolt12Offer: return "gift.circle.fill"
        case .bitcoinAddress: return DesignSystem.Icons.bitcoin
        case .liquidAddress: return "drop.fill"
        case .nodeId: return "network"
        case .url: return "link"
        case .lnUrlWithdraw: return "arrow.down.circle.fill"
        case .lnUrlAuth: return "key.fill"
        case .unsupported: return "questionmark.circle.fill"
        }
    }

    private func extractPaymentAmount() -> UInt64 {
        // This should extract the actual payment amount
        // For now, using a placeholder implementation
        return paymentInfo?.amount ?? 1000
    }
}

// MARK: - Supporting Types
// PaymentInputInfo and PaymentInputType are defined in WalletManager.swift

// MARK: - Preview

#Preview {
    ModernSendPaymentView()
}
