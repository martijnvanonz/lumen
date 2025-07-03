# Fee Acceptance Flow

## Status: ❌ Missing (Important Priority)

## Overview
**Purpose**: Handle fee acceptance for amountless Bitcoin payments when onchain fees increase.

**Documentation**: [Amountless Bitcoin Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#amountless-bitcoin-payments)

**User Impact**: When users receive Bitcoin payments without specifying an amount, and onchain fees increase between preparation and payment time, the payment is put on hold until the user explicitly accepts the new fees. Without this flow, payments remain stuck indefinitely.

## Implementation Details

### Files to Create/Modify
- **Modify**: `Lumen/Wallet/PaymentEventHandler.swift` (handle fee acceptance events)
- **Create**: `Lumen/Views/FeeAcceptanceView.swift` (new file)
- **Modify**: `Lumen/Wallet/WalletManager.swift` (add fee acceptance methods)
- **Create**: `Lumen/Wallet/FeeAcceptanceManager.swift` (new file)

### Dependencies
- None (can be implemented independently)

## Fee Acceptance Process

### When Fee Acceptance is Required
1. User generates Bitcoin receive address without amount
2. Sender initiates Bitcoin payment
3. Onchain fees increase between address generation and payment
4. SDK puts payment in `WaitingFeeAcceptance` state
5. User must review and accept new fees

### Fee Acceptance Flow
1. **Detection**: SDK emits `PaymentWaitingFeeAcceptance` event
2. **Notification**: User receives notification about fee review
3. **Review**: User sees current fees vs original estimate
4. **Decision**: User accepts fees or waits for lower fees
5. **Execution**: Payment proceeds or remains on hold

## Core Implementation

### Step 1: Create FeeAcceptanceManager
Create `Lumen/Wallet/FeeAcceptanceManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class FeeAcceptanceManager: ObservableObject {
    @Published var pendingFeeAcceptances: [FeeAcceptanceItem] = []
    @Published var isLoading = false
    
    private let walletManager = WalletManager.shared
    private let errorHandler = ErrorHandler.shared
    
    static let shared = FeeAcceptanceManager()
    private init() {}
    
    /// Load payments waiting for fee acceptance
    func loadPendingFeeAcceptances() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            guard let sdk = walletManager.sdk else {
                throw FeeAcceptanceError.sdkNotConnected
            }
            
            // Get payments in WaitingFeeAcceptance state
            let payments = try await sdk.listPayments(req: ListPaymentsRequest(
                states: [.waitingFeeAcceptance]
            ))
            
            var feeAcceptanceItems: [FeeAcceptanceItem] = []
            
            for payment in payments {
                if case .bitcoin(let swapId, _, _, _, _, _, _, _, _) = payment.details {
                    do {
                        let feeResponse = try await sdk.fetchPaymentProposedFees(
                            req: FetchPaymentProposedFeesRequest(swapId: swapId)
                        )
                        
                        let item = FeeAcceptanceItem(
                            payment: payment,
                            swapId: swapId,
                            proposedFees: feeResponse
                        )
                        
                        feeAcceptanceItems.append(item)
                    } catch {
                        logError("Failed to fetch fees for swap \(swapId): \(error)")
                    }
                }
            }
            
            await MainActor.run {
                self.pendingFeeAcceptances = feeAcceptanceItems
                self.isLoading = false
            }
            
            logInfo("Found \(feeAcceptanceItems.count) payments waiting for fee acceptance")
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            
            errorHandler.logError(.sdk(.feeAcceptanceFailed), context: "Loading pending fee acceptances")
        }
    }
    
    /// Accept proposed fees for a payment
    func acceptFees(for item: FeeAcceptanceItem) async throws {
        guard let sdk = walletManager.sdk else {
            throw FeeAcceptanceError.sdkNotConnected
        }
        
        let acceptRequest = AcceptPaymentProposedFeesRequest(
            response: item.proposedFees
        )
        
        try await sdk.acceptPaymentProposedFees(req: acceptRequest)
        
        logInfo("Accepted fees for payment: \(item.payment.txId ?? "unknown")")
        
        // Refresh pending list
        await loadPendingFeeAcceptances()
        
        // Notify user of acceptance
        let eventHandler = PaymentEventHandler.shared
        eventHandler.addNotification(
            title: "Fees Accepted",
            message: "Payment will proceed with accepted fees",
            type: .success
        )
    }
    
    /// Decline fees and keep payment on hold
    func declineFees(for item: FeeAcceptanceItem) {
        // Remove from pending list (payment remains on hold)
        pendingFeeAcceptances.removeAll { $0.id == item.id }
        
        let eventHandler = PaymentEventHandler.shared
        eventHandler.addNotification(
            title: "Fees Declined",
            message: "Payment will remain on hold until fees decrease",
            type: .info
        )
    }
    
    /// Check if there are any pending fee acceptances
    var hasPendingFeeAcceptances: Bool {
        !pendingFeeAcceptances.isEmpty
    }
}

struct FeeAcceptanceItem: Identifiable {
    let id = UUID()
    let payment: Payment
    let swapId: String
    let proposedFees: FetchPaymentProposedFeesResponse
    
    var payerAmountSat: UInt64 {
        proposedFees.payerAmountSat
    }
    
    var feesSat: UInt64 {
        proposedFees.feesSat
    }
    
    var receivedAmountSat: UInt64 {
        payerAmountSat - feesSat
    }
    
    var feePercentage: Double {
        guard payerAmountSat > 0 else { return 0 }
        return Double(feesSat) / Double(payerAmountSat) * 100
    }
}

enum FeeAcceptanceError: LocalizedError {
    case sdkNotConnected
    case feeAcceptanceFailed
    
    var errorDescription: String? {
        switch self {
        case .sdkNotConnected:
            return "Wallet not connected"
        case .feeAcceptanceFailed:
            return "Failed to accept fees"
        }
    }
}
```

### Step 2: Create FeeAcceptanceView
Create `Lumen/Views/FeeAcceptanceView.swift`:

```swift
import SwiftUI

struct FeeAcceptanceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feeManager = FeeAcceptanceManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if feeManager.isLoading {
                    LoadingView(message: "Loading fee reviews...")
                } else if feeManager.pendingFeeAcceptances.isEmpty {
                    EmptyFeeAcceptanceView()
                } else {
                    FeeAcceptanceListView()
                }
            }
            .navigationTitle("Fee Review")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task { await feeManager.loadPendingFeeAcceptances() }
                    }
                }
            }
            .task {
                await feeManager.loadPendingFeeAcceptances()
            }
        }
    }
    
    @ViewBuilder
    private func FeeAcceptanceListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(feeManager.pendingFeeAcceptances) { item in
                    FeeAcceptanceCard(item: item)
                }
            }
            .padding()
        }
    }
}

struct FeeAcceptanceCard: View {
    let item: FeeAcceptanceItem
    @StateObject private var feeManager = FeeAcceptanceManager.shared
    @State private var isProcessing = false
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bitcoin Payment")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Fees require approval")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button("Details") {
                    showingDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Amount Information
            VStack(spacing: 8) {
                AmountRow(
                    label: "Sender Amount",
                    amount: item.payerAmountSat,
                    color: .primary
                )
                
                AmountRow(
                    label: "Network Fees",
                    amount: item.feesSat,
                    color: .orange,
                    percentage: item.feePercentage
                )
                
                Divider()
                
                AmountRow(
                    label: "You Receive",
                    amount: item.receivedAmountSat,
                    color: .green,
                    isBold: true
                )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Decline") {
                    feeManager.declineFees(for: item)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                
                Button("Accept Fees") {
                    acceptFees()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
            }
            
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingDetails) {
            FeeAcceptanceDetailsView(item: item)
        }
    }
    
    private func acceptFees() {
        isProcessing = true
        
        Task {
            do {
                try await feeManager.acceptFees(for: item)
                
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Show error to user
                }
            }
        }
    }
}

struct AmountRow: View {
    let label: String
    let amount: UInt64
    let color: Color
    var percentage: Double? = nil
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isBold ? .subheadline.bold() : .subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(amount) sats")
                    .font(isBold ? .subheadline.bold() : .subheadline)
                    .foregroundColor(color)
                
                if let percentage = percentage {
                    Text("(\(percentage, specifier: "%.1f")%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct FeeAcceptanceDetailsView: View {
    let item: FeeAcceptanceItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Payment Information
                    PaymentInfoSection(item: item)
                    
                    // Fee Breakdown
                    FeeBreakdownSection(item: item)
                    
                    // Explanation
                    FeeExplanationSection()
                }
                .padding()
            }
            .navigationTitle("Fee Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PaymentInfoSection: View {
    let item: FeeAcceptanceItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "Payment ID", value: item.payment.txId ?? "Unknown")
                InfoRow(label: "Status", value: "Waiting Fee Acceptance")
                InfoRow(label: "Type", value: "Bitcoin Payment")
            }
        }
    }
}

struct FeeBreakdownSection: View {
    let item: FeeAcceptanceItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fee Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(
                    label: "Sender Amount",
                    value: "\(item.payerAmountSat) sats"
                )
                
                InfoRow(
                    label: "Network Fees",
                    value: "\(item.feesSat) sats (\(item.feePercentage, specifier: "%.1f")%)"
                )
                
                Divider()
                
                InfoRow(
                    label: "You Receive",
                    value: "\(item.receivedAmountSat) sats",
                    valueColor: .green
                )
            }
        }
    }
}

struct FeeExplanationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why Fee Approval is Needed")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ExplanationPoint(
                    icon: "clock.fill",
                    text: "Bitcoin network fees increased after your address was generated"
                )
                
                ExplanationPoint(
                    icon: "shield.fill",
                    text: "We require your approval for higher fees to protect your funds"
                )
                
                ExplanationPoint(
                    icon: "hand.raised.fill",
                    text: "You can decline and wait for fees to decrease"
                )
            }
        }
    }
}

struct ExplanationPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct EmptyFeeAcceptanceView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("No Fee Reviews")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("All payments are processing normally")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Step 3: Add Fee Acceptance Methods to WalletManager
Add to `Lumen/Wallet/WalletManager.swift`:

```swift
// MARK: - Fee Acceptance

/// Fetch proposed fees for a payment waiting fee acceptance
func fetchPaymentProposedFees(swapId: String) async throws -> FetchPaymentProposedFeesResponse {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    let request = FetchPaymentProposedFeesRequest(swapId: swapId)
    return try await sdk.fetchPaymentProposedFees(req: request)
}

/// Accept proposed fees for a payment
func acceptPaymentProposedFees(response: FetchPaymentProposedFeesResponse) async throws {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    let request = AcceptPaymentProposedFeesRequest(response: response)
    try await sdk.acceptPaymentProposedFees(req: request)
    
    // Refresh payment history
    await loadPaymentHistory()
}

/// Get payments waiting for fee acceptance
func getPaymentsWaitingFeeAcceptance() async throws -> [Payment] {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    return try await sdk.listPayments(req: ListPaymentsRequest(
        states: [.waitingFeeAcceptance]
    ))
}
```

### Step 4: Update PaymentEventHandler
Update `Lumen/Wallet/PaymentEventHandler.swift`:

```swift
private func handlePaymentWaitingFeeAcceptance(_ details: Payment) {
    let paymentInfo = createPaymentInfo(from: details, status: .pending)
    addOrUpdatePayment(paymentInfo)

    addNotification(
        title: "Fee Approval Required",
        message: "Bitcoin payment needs fee approval. Tap to review.",
        type: .warning
    )
    
    // Trigger fee acceptance manager to refresh
    Task {
        await FeeAcceptanceManager.shared.loadPendingFeeAcceptances()
    }
}
```

### Step 5: Add Fee Acceptance Button to Main UI
Update `Lumen/Views/WalletView.swift`:

```swift
struct WalletView: View {
    // ... existing properties ...
    @StateObject private var feeManager = FeeAcceptanceManager.shared
    @State private var showingFeeAcceptance = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        // ... existing content ...
                        
                        // Fee Acceptance Alert
                        if feeManager.hasPendingFeeAcceptances {
                            FeeAcceptanceAlert {
                                showingFeeAcceptance = true
                            }
                        }
                        
                        // ... rest of content ...
                    }
                }
                // ... rest of view ...
            }
        }
        .sheet(isPresented: $showingFeeAcceptance) {
            FeeAcceptanceView()
        }
        .task {
            await feeManager.loadPendingFeeAcceptances()
        }
    }
}

struct FeeAcceptanceAlert: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fee Approval Required")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Bitcoin payment needs your approval")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

## Testing Strategy

### Unit Tests
```swift
func testFeeAcceptanceLoading() async {
    let feeManager = FeeAcceptanceManager.shared
    await feeManager.loadPendingFeeAcceptances()
    
    XCTAssertFalse(feeManager.isLoading)
}

func testFeeAcceptance() async {
    let mockItem = FeeAcceptanceItem(
        payment: mockPayment,
        swapId: "test_swap",
        proposedFees: mockFeeResponse
    )
    
    let feeManager = FeeAcceptanceManager.shared
    
    do {
        try await feeManager.acceptFees(for: mockItem)
        // Verify acceptance was processed
    } catch {
        XCTFail("Fee acceptance failed: \(error)")
    }
}
```

### Integration Tests
1. **Create Amountless Payment**: Generate Bitcoin address without amount
2. **Simulate Fee Increase**: Mock fee increase scenario
3. **Detect Fee Acceptance**: Verify payment enters waiting state
4. **Accept Fees**: Complete fee acceptance flow
5. **Verify Completion**: Check payment proceeds normally

### Manual Testing Checklist
- [ ] Fee acceptance notifications appear when needed
- [ ] Fee details are displayed accurately
- [ ] Accept fees button works correctly
- [ ] Decline fees keeps payment on hold
- [ ] UI updates properly after fee acceptance
- [ ] Error handling works for failed acceptance

## Common Issues and Solutions

### Issue: Fee acceptance not triggered
**Cause**: Payment amount was specified, so no fee acceptance needed
**Solution**: Only amountless Bitcoin payments require fee acceptance

### Issue: Fees seem too high
**Cause**: Bitcoin network congestion
**Solution**: 
- Explain fee situation to users
- Allow declining and waiting for lower fees
- Show fee as percentage of payment amount

### Issue: Fee acceptance fails
**Cause**: Network issues or payment expired
**Solution**: 
- Retry with exponential backoff
- Check payment is still valid
- Provide clear error messages

## Estimated Development Time
**2-3 days** for experienced iOS developer

### Breakdown:
- Day 1: FeeAcceptanceManager and core logic
- Day 2: FeeAcceptanceView UI implementation
- Day 3: Integration and testing

## Success Criteria
- [ ] Payments waiting fee acceptance are detected automatically
- [ ] Users receive clear notifications about fee approval needs
- [ ] Fee details are displayed accurately with breakdown
- [ ] Accept/decline actions work correctly
- [ ] UI provides clear feedback throughout process
- [ ] Error handling covers all failure scenarios

## References
- [Breez SDK Amountless Bitcoin Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#amountless-bitcoin-payments)
- [Bitcoin Fee Estimation](https://bitcoiner.guide/fee/)
- [Lightning Network Fee Management](https://docs.lightning.engineering/lightning-network-tools/lnd/optimal-fee-estimation)
