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
                    LoadingView(text: "Loading refundable swaps...")
                } else if refundableSwaps.isEmpty {
                    EmptyStateView(
                        icon: AppTheme.Icons.success,
                        title: "No Refunds Needed",
                        message: "All your Bitcoin payments have been processed successfully. Failed payments that can be refunded will appear here."
                    )
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
            .standardToolbar(
                title: "Refunds",
                displayMode: .large,
                showsDoneButton: true,
                onDone: { dismiss() }
            )
            .refreshable {
                await loadRefundableSwaps()
            }
            .onAppear {
                Task {
                    await loadRefundableSwaps()
                }
            }
            .standardSheet(isPresented: $showingRefundSheet) {
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
                Text("Failed Bitcoin Payments")
            } footer: {
                Text("These are Bitcoin payments that failed and can be refunded to a Bitcoin address of your choice.")
            }
        }
    }
}

struct RefundRowView: View {
    let swap: RefundableSwap
    let onRefundTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Failed Payment")
                        .font(.headline)
                    
                    Text("Amount: \(swap.amountSat) sats")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refund") {
                    onRefundTapped()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Swap Address:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(swap.swapAddress)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
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
    @State private var customFeeRate = ""
    @State private var isExecuting = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @State private var refundTxId: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Refund Payment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Refund \(swap.amountSat) sats to a Bitcoin address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Refund address input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bitcoin Address")
                        .font(.headline)
                    
                    TextField("Enter Bitcoin address...", text: $refundAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !refundAddress.isEmpty && !walletManager.validateBitcoinAddress(refundAddress) {
                        Text("Invalid Bitcoin address")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                // Fee selection
                if let fees = recommendedFees {
                    FeeSelectionView(
                        recommendedFees: fees,
                        selectedFeeRate: $selectedFeeRate,
                        customFeeRate: $customFeeRate,
                        swapAmount: swap.amountSat
                    )
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Execute button
                Button(action: executeRefund) {
                    if isExecuting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Execute Refund")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canExecuteRefund ? Color.orange : Color.gray)
                .cornerRadius(12)
                .disabled(!canExecuteRefund || isExecuting)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Refund Successful", isPresented: $showingSuccess) {
                Button("OK") {
                    onRefundCompleted()
                    dismiss()
                }
            } message: {
                if let txId = refundTxId {
                    Text("Refund transaction: \(txId)")
                }
            }
        }
        .onAppear {
            if let fees = recommendedFees {
                selectedFeeRate = UInt32(fees.halfHourFee)
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
                    errorMessage = error.localizedDescription
                    isExecuting = false
                }
            }
        }
    }
}

// MARK: - Fee Selection

struct FeeSelectionView: View {
    let recommendedFees: RecommendedFees
    @Binding var selectedFeeRate: UInt32
    @Binding var customFeeRate: String
    let swapAmount: UInt64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Fee")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                FeeOptionView(
                    title: "Fast (~10 min)",
                    feeRate: UInt32(recommendedFees.fastestFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.fastestFee)
                ) {
                    selectedFeeRate = UInt32(recommendedFees.fastestFee)
                }
                
                FeeOptionView(
                    title: "Normal (~30 min)",
                    feeRate: UInt32(recommendedFees.halfHourFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.halfHourFee)
                ) {
                    selectedFeeRate = UInt32(recommendedFees.halfHourFee)
                }
                
                FeeOptionView(
                    title: "Slow (~1 hour)",
                    feeRate: UInt32(recommendedFees.hourFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.hourFee)
                ) {
                    selectedFeeRate = UInt32(recommendedFees.hourFee)
                }
                
                FeeOptionView(
                    title: "Economy (~24 hours)",
                    feeRate: UInt32(recommendedFees.economyFee),
                    isSelected: selectedFeeRate == UInt32(recommendedFees.economyFee)
                ) {
                    selectedFeeRate = UInt32(recommendedFees.economyFee)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FeeOptionView: View {
    let title: String
    let feeRate: UInt32
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(feeRate) sat/vB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty and Loading States

struct EmptyRefundsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("No Refunds Needed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("All your Bitcoin payments have been processed successfully. Failed payments that need refunds will appear here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RefundLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading refunds...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RefundView()
}
