import SwiftUI
import BreezSDKLiquid

struct RefundView: View {
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var refundableSwaps: [RefundableSwap] = []
    @State private var recommendedFees: RecommendedFees?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSwap: RefundableSwap?
    @State private var showingRefundSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    RefundLoadingView()
                } else if refundableSwaps.isEmpty {
                    EmptyRefundsView()
                } else {
                    RefundListView(
                        refundableSwaps: refundableSwaps,
                        onRefundTapped: { swap in
                            selectedSwap = swap
                            showingRefundSheet = true
                        }
                    )
                }
            }
            .navigationTitle(L("get_money_back"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await loadRefundableSwaps()
            }
            .onAppear {
                Task {
                    await loadRefundableSwaps()
                }
            }
            .onChange(of: refundableSwaps) { swaps in
                // Auto-dismiss if no refunds are available
                if swaps.isEmpty && !isLoading {
                    dismiss()
                }
            }
            .sheet(isPresented: $showingRefundSheet) {
                if let selectedSwap = selectedSwap {
                    RefundExecutionView(
                        swap: selectedSwap,
                        recommendedFees: recommendedFees
                    ) {
                        // Refresh after refund
                        Task {
                            await loadRefundableSwaps()
                        }
                    }
                }
            }
        }
    }
    
    private func loadRefundableSwaps() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let swaps = walletManager.listRefundableSwaps()
            async let fees = walletManager.getRecommendedFees()
            
            let (loadedSwaps, loadedFees) = try await (swaps, fees)
            
            await MainActor.run {
                refundableSwaps = loadedSwaps
                recommendedFees = loadedFees
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

// MARK: - Refund List

struct RefundListView: View {
    let refundableSwaps: [RefundableSwap]
    let onRefundTapped: (RefundableSwap) -> Void

    var body: some View {
        List {
            Section {
                ForEach(refundableSwaps, id: \.swapAddress) { swap in
                    RefundRowView(swap: swap) {
                        onRefundTapped(swap)
                    }
                }
            } header: {
                Text(L("money_to_get_back"))
            } footer: {
                Text(L("refund_explanation"))
            }
        }
    }
}

struct RefundRowView: View {
    let swap: RefundableSwap
    let onRefundTapped: () -> Void

    private var formattedAmount: String {
        let btcAmount = Double(swap.amountSat) / 100_000_000
        return String(format: "%.6f BTC", btcAmount)
    }

    private var estimatedUSDValue: String {
        // Rough estimate - in production you'd want real exchange rates
        let btcAmount = Double(swap.amountSat) / 100_000_000
        let usdValue = btcAmount * 45000 // Approximate BTC price
        return String(format: "$%.2f", usdValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("payment_failed"))
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(formattedAmount) (\(estimatedUSDValue))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    SatsAmountView(
                        amount: swap.amountSat,
                        displayMode: .satsOnly,
                        size: .compact,
                        style: .secondary
                    )
                }

                Spacer()

                Button(L("get_money_back")) {
                    onRefundTapped()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Refund Execution

struct RefundExecutionView: View {
    let swap: RefundableSwap
    let recommendedFees: RecommendedFees?
    let onRefundCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared

    @State private var refundAddress = ""
    @State private var selectedFeeRate: UInt32 = 0
    @State private var isExecuting = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var refundTxId: String?

    private var formattedAmount: String {
        let btcAmount = Double(swap.amountSat) / 100_000_000
        return String(format: "%.6f BTC", btcAmount)
    }

    private var estimatedUSDValue: String {
        let btcAmount = Double(swap.amountSat) / 100_000_000
        let usdValue = btcAmount * 45000
        return String(format: "$%.2f", usdValue)
    }

    private var estimatedFeeCost: String {
        guard selectedFeeRate > 0 else { return "$0.00" }
        let estimatedVbytes: UInt32 = 225 // Typical refund transaction size
        let feeSats = estimatedVbytes * selectedFeeRate
        let feeBTC = Double(feeSats) / 100_000_000
        let feeUSD = feeBTC * 45000
        return String(format: "$%.2f", feeUSD)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text(L("get_your_money_back"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Return \(formattedAmount) (\(estimatedUSDValue)) to your Bitcoin wallet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Simple explanation
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("What happened?")
                                .font(.headline)
                        }

                        Text("Your payment didn't go through, but your money is safe. We can send it back to any Bitcoin address you choose.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Bitcoin address input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Where should we send your money?")
                            .font(.headline)

                        Text("Enter your Bitcoin wallet address:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Paste Bitcoin address here...", text: $refundAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))

                        if !refundAddress.isEmpty && !walletManager.validateBitcoinAddress(refundAddress) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Please enter a valid Bitcoin address")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Simple fee selection
                    if let fees = recommendedFees {
                        SimpleFeeSelectionView(
                            recommendedFees: fees,
                            selectedFeeRate: $selectedFeeRate,
                            estimatedCost: estimatedFeeCost
                        )
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Big action button
                    Button(action: executeRefund) {
                        HStack(spacing: 12) {
                            if isExecuting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Sending Your Money...")
                            } else {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Get My Money Back")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canExecuteRefund ? Color.orange : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canExecuteRefund || isExecuting)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(L("money_sent_successfully"), isPresented: $showingSuccess) {
                Button(L("great")) {
                    onRefundCompleted()
                    dismiss()
                }
            } message: {
                Text(L("refund_success_message"))
            }
        }
        .onAppear {
            if let fees = recommendedFees {
                selectedFeeRate = UInt32(fees.halfHourFee) // Default to normal speed
            }
        }
    }
    
    private var canExecuteRefund: Bool {
        return !refundAddress.isEmpty &&
               walletManager.validateBitcoinAddress(refundAddress) &&
               selectedFeeRate > 0
    }

    private func executeRefund() {
        isExecuting = true
        errorMessage = nil

        Task {
            do {
                let response = try await walletManager.executeRefund(
                    swapAddress: swap.swapAddress,
                    refundAddress: refundAddress,
                    feeRateSatPerVbyte: selectedFeeRate
                )

                await MainActor.run {
                    refundTxId = response.refundTxId
                    showingSuccess = true
                    isExecuting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Something went wrong. Please try again or contact support if the problem continues."
                    isExecuting = false
                }
            }
        }
    }
}

// MARK: - Simple Fee Selection

struct SimpleFeeSelectionView: View {
    let recommendedFees: RecommendedFees
    @Binding var selectedFeeRate: UInt32
    let estimatedCost: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How fast do you want your money back?")
                    .font(.headline)

                Text("Faster delivery costs a bit more, just like express shipping.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                SimpleFeeOptionView(
                    title: "Fast",
                    subtitle: "~10 minutes",
                    feeRate: UInt32(recommendedFees.fastestFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.fastestFee),
                    icon: "hare.fill",
                    color: .red
                ) {
                    selectedFeeRate = UInt32(recommendedFees.fastestFee)
                }

                SimpleFeeOptionView(
                    title: "Normal",
                    subtitle: "~30 minutes",
                    feeRate: UInt32(recommendedFees.halfHourFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.halfHourFee),
                    icon: "figure.walk",
                    color: .blue,
                    isRecommended: true
                ) {
                    selectedFeeRate = UInt32(recommendedFees.halfHourFee)
                }

                SimpleFeeOptionView(
                    title: "Slow",
                    subtitle: "~1 hour",
                    feeRate: UInt32(recommendedFees.hourFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.hourFee),
                    icon: "tortoise.fill",
                    color: .green
                ) {
                    selectedFeeRate = UInt32(recommendedFees.hourFee)
                }
            }

            if selectedFeeRate > 0 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Transaction cost: \(estimatedCost)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }
}

struct SimpleFeeOptionView: View {
    let title: String
    let subtitle: String
    let feeRate: UInt32
    let isSelected: Bool
    let icon: String
    let color: Color
    var isRecommended: Bool = false
    let onTap: () -> Void

    private var estimatedCost: String {
        let estimatedVbytes: UInt32 = 225
        let feeSats = estimatedVbytes * feeRate
        let feeBTC = Double(feeSats) / 100_000_000
        let feeUSD = feeBTC * 45000
        return String(format: "$%.2f", feeUSD)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Cost: \(estimatedCost)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State

struct EmptyRefundsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("All Good! 🎉")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("You don't have any failed payments to refund.")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("This means all your payments went through successfully!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct RefundLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Checking for money to get back...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}



#Preview {
    RefundView()
}
