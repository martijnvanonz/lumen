# Refundable Swap Management

## Status: ❌ Missing (Critical Priority)

## Overview
**Purpose**: Allow users to recover funds from failed Bitcoin payments. Critical for user trust and fund safety.

**Documentation**: [Refunding Payments](https://sdk-doc-liquid.breez.technology/guide/refund_payment.html)

**User Impact**: When Bitcoin payments fail (due to network issues, fee problems, or swap failures), users need a way to recover their funds. Without this feature, funds could be permanently lost, making the wallet unsuitable for production use.

## Implementation Details

### Files to Create/Modify
- **Enhance**: `Lumen/Views/RefundView.swift` (existing file needs major enhancement)
- **Modify**: `Lumen/Wallet/WalletManager.swift` (add refund methods)
- **Create**: `Lumen/Wallet/RefundManager.swift` (new file)
- **Modify**: `Lumen/Wallet/PaymentEventHandler.swift` (handle refundable events)

### Dependencies
- None (can be implemented independently)

## Core Refund Functionality

### Step 1: Create RefundManager
Create `Lumen/Wallet/RefundManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class RefundManager: ObservableObject {
    @Published var refundableSwaps: [RefundableSwap] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let walletManager = WalletManager.shared
    private let errorHandler = ErrorHandler.shared
    
    static let shared = RefundManager()
    private init() {}
    
    /// Load all refundable swaps
    func loadRefundableSwaps() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            guard let sdk = walletManager.sdk else {
                throw RefundError.sdkNotConnected
            }
            
            let refundables = try await sdk.listRefundables()
            
            await MainActor.run {
                self.refundableSwaps = refundables
                self.isLoading = false
            }
            
            logInfo("Found \(refundables.count) refundable swaps")
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            
            errorHandler.logError(.sdk(.refundFailed), context: "Loading refundable swaps")
        }
    }
    
    /// Execute refund for a specific swap
    func executeRefund(
        swap: RefundableSwap,
        destinationAddress: String,
        feeRate: UInt32
    ) async throws -> String {
        guard let sdk = walletManager.sdk else {
            throw RefundError.sdkNotConnected
        }
        
        let refundRequest = RefundRequest(
            swapAddress: swap.swapAddress,
            refundAddress: destinationAddress,
            feeRateSatPerVbyte: feeRate
        )
        
        do {
            let response = try await sdk.refund(req: refundRequest)
            logInfo("Refund executed successfully: \(response.refundTxId)")
            
            // Refresh refundable swaps list
            await loadRefundableSwaps()
            
            return response.refundTxId
        } catch {
            errorHandler.logError(.sdk(.refundFailed), context: "Executing refund")
            throw error
        }
    }
    
    /// Get recommended fees for refund transaction
    func getRecommendedFees() async throws -> RecommendedFees {
        guard let sdk = walletManager.sdk else {
            throw RefundError.sdkNotConnected
        }
        
        return try await sdk.recommendedFees()
    }
    
    /// Check if address is valid for refund
    func validateRefundAddress(_ address: String) -> Bool {
        // Basic Bitcoin address validation
        // You might want to use a more robust validation
        return address.count >= 26 && address.count <= 62 && 
               (address.hasPrefix("1") || address.hasPrefix("3") || address.hasPrefix("bc1"))
    }
}

enum RefundError: LocalizedError {
    case sdkNotConnected
    case invalidAddress
    case insufficientFees
    
    var errorDescription: String? {
        switch self {
        case .sdkNotConnected:
            return "Wallet not connected"
        case .invalidAddress:
            return "Invalid Bitcoin address"
        case .insufficientFees:
            return "Fee rate too low"
        }
    }
}
```

### Step 2: Enhance RefundView
Replace the existing `Lumen/Views/RefundView.swift`:

```swift
import SwiftUI
import BreezSDKLiquid

struct RefundView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var refundManager = RefundManager.shared
    @State private var selectedSwap: RefundableSwap?
    @State private var destinationAddress = ""
    @State private var selectedFeeRate: UInt32 = 1
    @State private var recommendedFees: RecommendedFees?
    @State private var showingRefundConfirmation = false
    @State private var isExecutingRefund = false
    @State private var refundTxId: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if refundManager.isLoading {
                    LoadingView(message: "Loading refundable payments...")
                } else if refundManager.refundableSwaps.isEmpty {
                    EmptyRefundView()
                } else {
                    RefundListView()
                }
            }
            .navigationTitle("Refund Payments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await refundManager.loadRefundableSwaps() }
                    }
                }
            }
            .task {
                await refundManager.loadRefundableSwaps()
                await loadRecommendedFees()
            }
            .sheet(item: $selectedSwap) { swap in
                RefundExecutionView(
                    swap: swap,
                    recommendedFees: recommendedFees
                )
            }
        }
    }
    
    @ViewBuilder
    private func RefundListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(refundManager.refundableSwaps, id: \.swapAddress) { swap in
                    RefundableSwapCard(swap: swap) {
                        selectedSwap = swap
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadRecommendedFees() async {
        do {
            recommendedFees = try await refundManager.getRecommendedFees()
        } catch {
            print("Failed to load recommended fees: \(error)")
        }
    }
}

struct RefundableSwapCard: View {
    let swap: RefundableSwap
    let onRefund: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Failed Bitcoin Payment")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Amount: \(swap.amountSat) sats")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Refund") {
                    onRefund()
                }
                .buttonStyle(.borderedProminent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Swap Address")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(swap.swapAddress)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct RefundExecutionView: View {
    let swap: RefundableSwap
    let recommendedFees: RecommendedFees?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var refundManager = RefundManager.shared
    @State private var destinationAddress = ""
    @State private var selectedFeeRate: UInt32 = 1
    @State private var isExecutingRefund = false
    @State private var refundTxId: String?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Swap Information
                SwapInfoSection(swap: swap)
                
                // Destination Address Input
                DestinationAddressSection(
                    address: $destinationAddress,
                    isValid: refundManager.validateRefundAddress(destinationAddress)
                )
                
                // Fee Selection
                if let fees = recommendedFees {
                    FeeSelectionSection(
                        fees: fees,
                        selectedFeeRate: $selectedFeeRate
                    )
                }
                
                Spacer()
                
                // Execute Refund Button
                Button(action: executeRefund) {
                    if isExecutingRefund {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Processing Refund...")
                        }
                    } else {
                        Text("Execute Refund")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    destinationAddress.isEmpty || 
                    !refundManager.validateRefundAddress(destinationAddress) ||
                    isExecutingRefund
                )
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("Refund Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            if let fees = recommendedFees {
                selectedFeeRate = fees.fastestFee
            }
        }
        .alert("Refund Successful", isPresented: .constant(refundTxId != nil)) {
            Button("OK") {
                refundTxId = nil
                dismiss()
            }
        } message: {
            if let txId = refundTxId {
                Text("Refund transaction: \(txId)")
            }
        }
    }
    
    private func executeRefund() {
        isExecutingRefund = true
        errorMessage = nil
        
        Task {
            do {
                let txId = try await refundManager.executeRefund(
                    swap: swap,
                    destinationAddress: destinationAddress,
                    feeRate: selectedFeeRate
                )
                
                await MainActor.run {
                    refundTxId = txId
                    isExecutingRefund = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExecutingRefund = false
                }
            }
        }
    }
}

// Additional supporting views...
struct SwapInfoSection: View {
    let swap: RefundableSwap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Details")
                .font(.headline)
            
            InfoRow(label: "Amount", value: "\(swap.amountSat) sats")
            InfoRow(label: "Swap Address", value: swap.swapAddress)
        }
    }
}

struct DestinationAddressSection: View {
    @Binding var address: String
    let isValid: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bitcoin Address")
                .font(.headline)
            
            TextField("Enter Bitcoin address for refund", text: $address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !address.isEmpty {
                HStack {
                    Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isValid ? .green : .red)
                    
                    Text(isValid ? "Valid Bitcoin address" : "Invalid Bitcoin address")
                        .font(.caption)
                        .foregroundColor(isValid ? .green : .red)
                }
            }
        }
    }
}

struct FeeSelectionSection: View {
    let fees: RecommendedFees
    @Binding var selectedFeeRate: UInt32
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Fee")
                .font(.headline)
            
            VStack(spacing: 8) {
                FeeOption(
                    title: "Economy",
                    subtitle: "~30+ minutes",
                    feeRate: fees.economyFee,
                    isSelected: selectedFeeRate == fees.economyFee
                ) {
                    selectedFeeRate = fees.economyFee
                }
                
                FeeOption(
                    title: "Standard",
                    subtitle: "~10 minutes",
                    feeRate: fees.hourFee,
                    isSelected: selectedFeeRate == fees.hourFee
                ) {
                    selectedFeeRate = fees.hourFee
                }
                
                FeeOption(
                    title: "Fast",
                    subtitle: "~1 minute",
                    feeRate: fees.fastestFee,
                    isSelected: selectedFeeRate == fees.fastestFee
                ) {
                    selectedFeeRate = fees.fastestFee
                }
            }
        }
    }
}

struct FeeOption: View {
    let title: String
    let subtitle: String
    let feeRate: UInt32
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(feeRate) sat/vB")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct EmptyRefundView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Refunds Needed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("All your payments completed successfully")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
```

### Step 3: Add Refund Methods to WalletManager
Add to `Lumen/Wallet/WalletManager.swift`:

```swift
// MARK: - Refund Management

/// Get list of refundable swaps
func getRefundableSwaps() async throws -> [RefundableSwap] {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    return try await sdk.listRefundables()
}

/// Execute refund for failed swap
func executeRefund(
    swapAddress: String,
    refundAddress: String,
    feeRate: UInt32
) async throws -> String {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    let refundRequest = RefundRequest(
        swapAddress: swapAddress,
        refundAddress: refundAddress,
        feeRateSatPerVbyte: feeRate
    )
    
    let response = try await sdk.refund(req: refundRequest)
    
    // Refresh payment history after refund
    await loadPaymentHistory()
    
    return response.refundTxId
}

/// Get recommended fees for Bitcoin transactions
func getRecommendedFees() async throws -> RecommendedFees {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    return try await sdk.recommendedFees()
}
```

### Step 4: Handle Refundable Events
Update `Lumen/Wallet/PaymentEventHandler.swift`:

```swift
private func handlePaymentRefundable(_ details: Payment) {
    let paymentInfo = createPaymentInfo(from: details, status: .failed)
    addOrUpdatePayment(paymentInfo)

    addNotification(
        title: "Payment Refundable",
        message: "Payment failed and can be refunded. Tap to refund.",
        type: .warning
    )
    
    // Trigger refund manager to refresh
    Task {
        await RefundManager.shared.loadRefundableSwaps()
    }
}
```

## Testing Strategy

### Unit Tests
```swift
func testRefundableSwapLoading() async {
    let refundManager = RefundManager.shared
    await refundManager.loadRefundableSwaps()
    
    // Verify refundable swaps are loaded
    XCTAssertFalse(refundManager.isLoading)
    XCTAssertNil(refundManager.errorMessage)
}

func testRefundExecution() async {
    let mockSwap = RefundableSwap(
        swapAddress: "test_address",
        amountSat: 1000
    )
    
    let refundManager = RefundManager.shared
    
    do {
        let txId = try await refundManager.executeRefund(
            swap: mockSwap,
            destinationAddress: "bc1qtest",
            feeRate: 1
        )
        
        XCTAssertFalse(txId.isEmpty)
    } catch {
        XCTFail("Refund execution failed: \(error)")
    }
}
```

### Integration Tests
1. **Create Failed Payment**: Simulate a failed Bitcoin payment
2. **Detect Refundable**: Verify swap appears in refundable list
3. **Execute Refund**: Complete refund process
4. **Verify Completion**: Check refund transaction and balance update

### Manual Testing Checklist
- [ ] Refundable swaps appear in list when payments fail
- [ ] Refund UI shows correct swap information
- [ ] Bitcoin address validation works correctly
- [ ] Fee selection updates properly
- [ ] Refund execution completes successfully
- [ ] Refund transaction ID is displayed
- [ ] Balance updates after refund

## Common Issues and Solutions

### Issue: No refundable swaps found
**Cause**: All payments completed successfully or swaps haven't failed yet
**Solution**: This is actually good - means no failed payments

### Issue: Refund execution fails
**Cause**: Invalid address, insufficient fees, or network issues
**Solution**: 
- Validate Bitcoin address format
- Use recommended fee rates
- Check network connectivity

### Issue: High refund fees
**Cause**: Bitcoin network congestion
**Solution**: 
- Offer multiple fee options
- Allow users to wait for lower fees
- Explain fee situation to users

## Estimated Development Time
**2-3 days** for experienced iOS developer

### Breakdown:
- Day 1: RefundManager implementation
- Day 2: Enhanced RefundView UI
- Day 3: Integration and testing

## Success Criteria
- [ ] Failed Bitcoin payments appear in refundable list
- [ ] Users can execute refunds with custom Bitcoin addresses
- [ ] Fee selection works with recommended rates
- [ ] Refund transactions complete successfully
- [ ] UI provides clear feedback throughout process
- [ ] Error handling covers all failure scenarios

## References
- [Breez SDK Refunding Payments](https://sdk-doc-liquid.breez.technology/guide/refund_payment.html)
- [Bitcoin Address Validation](https://en.bitcoin.it/wiki/Address)
- [Bitcoin Fee Estimation](https://bitcoiner.guide/fee/)
