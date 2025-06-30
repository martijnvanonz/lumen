# Payment Limits Validation

## Status: ❌ Missing (Important Priority)

## Overview
**Purpose**: Validate payment amounts against Lightning and onchain limits to prevent failed transactions.

**Documentation**: [Receiving Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html)

**User Impact**: Without limit validation, users can attempt payments that will fail due to amount restrictions, leading to poor user experience and potential fund loss. Proper validation prevents failed transactions and guides users to valid amounts.

## Implementation Details

### Files to Create/Modify
- **Modify**: `Lumen/Wallet/WalletManager.swift` (add limit checking methods)
- **Modify**: `Lumen/Views/SendPaymentView.swift` (add validation UI)
- **Modify**: `Lumen/Views/ReceivePaymentView.swift` (add limit display)
- **Create**: `Lumen/Wallet/PaymentLimitsManager.swift` (new file)

### Dependencies
- None (can be implemented independently)

## Payment Limits Overview

### Lightning Limits
- **Receive**: Minimum and maximum amounts for Lightning payments
- **Send**: Limits for outgoing Lightning payments
- **Dynamic**: Limits can change based on network conditions

### Onchain Limits  
- **Receive**: Minimum and maximum for Bitcoin payments
- **Send**: Limits for Bitcoin transactions
- **Fee-dependent**: Affected by current Bitcoin network fees

## Core Implementation

### Step 1: Create PaymentLimitsManager
Create `Lumen/Wallet/PaymentLimitsManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class PaymentLimitsManager: ObservableObject {
    @Published var lightningLimits: LightningPaymentLimitsResponse?
    @Published var onchainLimits: OnchainPaymentLimitsResponse?
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    
    private let walletManager = WalletManager.shared
    private let errorHandler = ErrorHandler.shared
    
    static let shared = PaymentLimitsManager()
    private init() {}
    
    /// Fetch all payment limits
    func fetchAllLimits() async {
        await MainActor.run {
            isLoading = true
        }
        
        async let lightningTask = fetchLightningLimits()
        async let onchainTask = fetchOnchainLimits()
        
        await lightningTask
        await onchainTask
        
        await MainActor.run {
            isLoading = false
            lastUpdated = Date()
        }
    }
    
    /// Fetch Lightning payment limits
    func fetchLightningLimits() async {
        do {
            guard let sdk = walletManager.sdk else {
                throw PaymentLimitsError.sdkNotConnected
            }
            
            let limits = try await sdk.fetchLightningLimits()
            
            await MainActor.run {
                self.lightningLimits = limits
            }
            
            logInfo("Lightning limits updated - Receive: \(limits.receive.minSat)-\(limits.receive.maxSat) sats, Send: \(limits.send.minSat)-\(limits.send.maxSat) sats")
        } catch {
            errorHandler.logError(.sdk(.limitsUnavailable), context: "Fetching Lightning limits")
        }
    }
    
    /// Fetch onchain payment limits
    func fetchOnchainLimits() async {
        do {
            guard let sdk = walletManager.sdk else {
                throw PaymentLimitsError.sdkNotConnected
            }
            
            let limits = try await sdk.fetchOnchainLimits()
            
            await MainActor.run {
                self.onchainLimits = limits
            }
            
            logInfo("Onchain limits updated - Receive: \(limits.receive.minSat)-\(limits.receive.maxSat) sats, Send: \(limits.send.minSat)-\(limits.send.maxSat) sats")
        } catch {
            errorHandler.logError(.sdk(.limitsUnavailable), context: "Fetching onchain limits")
        }
    }
    
    /// Validate Lightning receive amount
    func validateLightningReceive(amount: UInt64) -> ValidationResult {
        guard let limits = lightningLimits else {
            return .unknown("Lightning limits not available")
        }
        
        if amount < limits.receive.minSat {
            return .invalid("Amount too small. Minimum: \(limits.receive.minSat) sats")
        }
        
        if amount > limits.receive.maxSat {
            return .invalid("Amount too large. Maximum: \(limits.receive.maxSat) sats")
        }
        
        return .valid
    }
    
    /// Validate Lightning send amount
    func validateLightningSend(amount: UInt64) -> ValidationResult {
        guard let limits = lightningLimits else {
            return .unknown("Lightning limits not available")
        }
        
        if amount < limits.send.minSat {
            return .invalid("Amount too small. Minimum: \(limits.send.minSat) sats")
        }
        
        if amount > limits.send.maxSat {
            return .invalid("Amount too large. Maximum: \(limits.send.maxSat) sats")
        }
        
        return .valid
    }
    
    /// Validate onchain receive amount
    func validateOnchainReceive(amount: UInt64) -> ValidationResult {
        guard let limits = onchainLimits else {
            return .unknown("Onchain limits not available")
        }
        
        if amount < limits.receive.minSat {
            return .invalid("Amount too small. Minimum: \(limits.receive.minSat) sats")
        }
        
        if amount > limits.receive.maxSat {
            return .invalid("Amount too large. Maximum: \(limits.receive.maxSat) sats")
        }
        
        return .valid
    }
    
    /// Validate onchain send amount
    func validateOnchainSend(amount: UInt64) -> ValidationResult {
        guard let limits = onchainLimits else {
            return .unknown("Onchain limits not available")
        }
        
        if amount < limits.send.minSat {
            return .invalid("Amount too small. Minimum: \(limits.send.minSat) sats")
        }
        
        if amount > limits.send.maxSat {
            return .invalid("Amount too large. Maximum: \(limits.send.maxSat) sats")
        }
        
        return .valid
    }
    
    /// Get formatted limits string for UI display
    func getLimitsDisplayString(for paymentType: PaymentType, direction: PaymentDirection) -> String {
        switch (paymentType, direction) {
        case (.lightning, .receive):
            guard let limits = lightningLimits else { return "Limits unavailable" }
            return "\(limits.receive.minSat) - \(limits.receive.maxSat) sats"
            
        case (.lightning, .send):
            guard let limits = lightningLimits else { return "Limits unavailable" }
            return "\(limits.send.minSat) - \(limits.send.maxSat) sats"
            
        case (.onchain, .receive):
            guard let limits = onchainLimits else { return "Limits unavailable" }
            return "\(limits.receive.minSat) - \(limits.receive.maxSat) sats"
            
        case (.onchain, .send):
            guard let limits = onchainLimits else { return "Limits unavailable" }
            return "\(limits.send.minSat) - \(limits.send.maxSat) sats"
        }
    }
    
    /// Check if limits need refresh (older than 5 minutes)
    var needsRefresh: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 300 // 5 minutes
    }
}

enum ValidationResult {
    case valid
    case invalid(String)
    case unknown(String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message), .unknown(let message):
            return message
        }
    }
}

enum PaymentType {
    case lightning
    case onchain
}

enum PaymentDirection {
    case send
    case receive
}

enum PaymentLimitsError: LocalizedError {
    case sdkNotConnected
    case limitsUnavailable
    
    var errorDescription: String? {
        switch self {
        case .sdkNotConnected:
            return "Wallet not connected"
        case .limitsUnavailable:
            return "Payment limits unavailable"
        }
    }
}
```

### Step 2: Add Limits Methods to WalletManager
Add to `Lumen/Wallet/WalletManager.swift`:

```swift
// MARK: - Payment Limits

/// Fetch Lightning payment limits
func fetchLightningLimits() async throws -> LightningPaymentLimitsResponse {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    return try await sdk.fetchLightningLimits()
}

/// Fetch onchain payment limits
func fetchOnchainLimits() async throws -> OnchainPaymentLimitsResponse {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    return try await sdk.fetchOnchainLimits()
}

/// Validate payment amount against limits
func validatePaymentAmount(
    amount: UInt64,
    paymentType: PaymentType,
    direction: PaymentDirection
) async -> ValidationResult {
    let limitsManager = PaymentLimitsManager.shared
    
    // Refresh limits if needed
    if limitsManager.needsRefresh {
        await limitsManager.fetchAllLimits()
    }
    
    switch (paymentType, direction) {
    case (.lightning, .receive):
        return limitsManager.validateLightningReceive(amount: amount)
    case (.lightning, .send):
        return limitsManager.validateLightningSend(amount: amount)
    case (.onchain, .receive):
        return limitsManager.validateOnchainReceive(amount: amount)
    case (.onchain, .send):
        return limitsManager.validateOnchainSend(amount: amount)
    }
}
```

### Step 3: Enhance SendPaymentView with Validation
Update `Lumen/Views/SendPaymentView.swift`:

```swift
struct SendPaymentView: View {
    // ... existing properties ...
    @StateObject private var limitsManager = PaymentLimitsManager.shared
    @State private var amountValidation: ValidationResult = .valid
    @State private var showingLimitsInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ... existing content ...
                
                // Amount validation display
                if let paymentInfo = paymentInfo {
                    AmountValidationView(
                        paymentInfo: paymentInfo,
                        validation: amountValidation,
                        onShowLimits: { showingLimitsInfo = true }
                    )
                }
                
                // ... rest of content ...
            }
            .task {
                await limitsManager.fetchAllLimits()
            }
            .sheet(isPresented: $showingLimitsInfo) {
                PaymentLimitsInfoView()
            }
        }
    }
    
    private func validatePaymentAmount() {
        guard let paymentInfo = paymentInfo,
              let amount = paymentInfo.amount else {
            amountValidation = .valid
            return
        }
        
        Task {
            let paymentType: PaymentType = paymentInfo.type == .lightningInvoice ? .lightning : .onchain
            let validation = await WalletManager.shared.validatePaymentAmount(
                amount: amount,
                paymentType: paymentType,
                direction: .send
            )
            
            await MainActor.run {
                amountValidation = validation
            }
        }
    }
}

struct AmountValidationView: View {
    let paymentInfo: PaymentInputInfo
    let validation: ValidationResult
    let onShowLimits: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Amount Validation")
                    .font(.headline)
                
                Spacer()
                
                Button("Limits") {
                    onShowLimits()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(validation.isValid ? .green : .orange)
                
                if validation.isValid {
                    Text("Amount is valid")
                        .foregroundColor(.green)
                } else if let errorMessage = validation.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.orange)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

### Step 4: Enhance ReceivePaymentView with Limits Display
Update `Lumen/Views/ReceivePaymentView.swift`:

```swift
struct ReceivePaymentView: View {
    // ... existing properties ...
    @StateObject private var limitsManager = PaymentLimitsManager.shared
    @State private var amountValidation: ValidationResult = .valid
    @State private var showingLimitsInfo = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ... existing content ...
                
                // Payment limits display
                PaymentLimitsDisplayView(
                    limitsManager: limitsManager,
                    onShowDetails: { showingLimitsInfo = true }
                )
                
                // Amount input with validation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (sats)")
                        .font(.headline)
                    
                    TextField("Enter amount", text: $amount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: amount) { _, newValue in
                            validateAmount()
                        }
                    
                    if !amountValidation.isValid,
                       let errorMessage = amountValidation.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // ... rest of content ...
            }
            .task {
                await limitsManager.fetchAllLimits()
            }
            .sheet(isPresented: $showingLimitsInfo) {
                PaymentLimitsInfoView()
            }
        }
    }
    
    private func validateAmount() {
        guard let amountSats = UInt64(amount) else {
            amountValidation = .valid
            return
        }
        
        Task {
            // Assume Lightning for now - could be made dynamic based on payment method selection
            let validation = await WalletManager.shared.validatePaymentAmount(
                amount: amountSats,
                paymentType: .lightning,
                direction: .receive
            )
            
            await MainActor.run {
                amountValidation = validation
            }
        }
    }
}

struct PaymentLimitsDisplayView: View {
    @ObservedObject var limitsManager: PaymentLimitsManager
    let onShowDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment Limits")
                    .font(.headline)
                
                Spacer()
                
                Button("Details") {
                    onShowDetails()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if limitsManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading limits...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    LimitRow(
                        title: "Lightning Receive",
                        range: limitsManager.getLimitsDisplayString(for: .lightning, direction: .receive)
                    )
                    
                    LimitRow(
                        title: "Bitcoin Receive",
                        range: limitsManager.getLimitsDisplayString(for: .onchain, direction: .receive)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LimitRow: View {
    let title: String
    let range: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(range)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
```

### Step 5: Create Limits Info View
Create `Lumen/Views/PaymentLimitsInfoView.swift`:

```swift
import SwiftUI

struct PaymentLimitsInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var limitsManager = PaymentLimitsManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Lightning Limits Section
                    LimitsSection(
                        title: "Lightning Network",
                        icon: "bolt.fill",
                        color: .orange,
                        limits: limitsManager.lightningLimits
                    )
                    
                    // Bitcoin Limits Section
                    LimitsSection(
                        title: "Bitcoin Network",
                        icon: "bitcoinsign.circle.fill",
                        color: .blue,
                        limits: limitsManager.onchainLimits
                    )
                    
                    // Information Section
                    InfoSection()
                }
                .padding()
            }
            .navigationTitle("Payment Limits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        Task { await limitsManager.fetchAllLimits() }
                    }
                }
            }
        }
    }
}

struct LimitsSection<T>: View {
    let title: String
    let icon: String
    let color: Color
    let limits: T?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            if let lightningLimits = limits as? LightningPaymentLimitsResponse {
                LightningLimitsContent(limits: lightningLimits)
            } else if let onchainLimits = limits as? OnchainPaymentLimitsResponse {
                OnchainLimitsContent(limits: onchainLimits)
            } else {
                Text("Limits unavailable")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct LightningLimitsContent: View {
    let limits: LightningPaymentLimitsResponse
    
    var body: some View {
        VStack(spacing: 12) {
            LimitDetailRow(
                direction: "Send",
                min: limits.send.minSat,
                max: limits.send.maxSat
            )
            
            LimitDetailRow(
                direction: "Receive",
                min: limits.receive.minSat,
                max: limits.receive.maxSat
            )
        }
    }
}

struct OnchainLimitsContent: View {
    let limits: OnchainPaymentLimitsResponse
    
    var body: some View {
        VStack(spacing: 12) {
            LimitDetailRow(
                direction: "Send",
                min: limits.send.minSat,
                max: limits.send.maxSat
            )
            
            LimitDetailRow(
                direction: "Receive",
                min: limits.receive.minSat,
                max: limits.receive.maxSat
            )
        }
    }
}

struct LimitDetailRow: View {
    let direction: String
    let min: UInt64
    let max: UInt64
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(direction)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("\(min) - \(max) sats")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Payment Limits")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoItem(
                    icon: "info.circle.fill",
                    title: "Dynamic Limits",
                    description: "Limits change based on network conditions and liquidity"
                )
                
                InfoItem(
                    icon: "clock.fill",
                    title: "Regular Updates",
                    description: "Limits are refreshed automatically every 5 minutes"
                )
                
                InfoItem(
                    icon: "shield.fill",
                    title: "Safety First",
                    description: "Limits prevent failed transactions and protect your funds"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## Testing Strategy

### Unit Tests
```swift
func testLightningLimitsValidation() {
    let limitsManager = PaymentLimitsManager.shared
    
    // Mock limits
    limitsManager.lightningLimits = LightningPaymentLimitsResponse(
        send: PaymentLimits(minSat: 1, maxSat: 1000000),
        receive: PaymentLimits(minSat: 100, maxSat: 500000)
    )
    
    // Test valid amount
    let validResult = limitsManager.validateLightningReceive(amount: 1000)
    XCTAssertTrue(validResult.isValid)
    
    // Test too small
    let tooSmallResult = limitsManager.validateLightningReceive(amount: 50)
    XCTAssertFalse(tooSmallResult.isValid)
    
    // Test too large
    let tooLargeResult = limitsManager.validateLightningReceive(amount: 600000)
    XCTAssertFalse(tooLargeResult.isValid)
}
```

### Integration Tests
1. **Fetch Limits**: Verify limits are fetched from SDK
2. **Validation Logic**: Test all validation scenarios
3. **UI Updates**: Verify UI shows correct validation states
4. **Refresh Logic**: Test automatic limit refresh

### Manual Testing Checklist
- [ ] Limits display correctly in receive view
- [ ] Amount validation works in real-time
- [ ] Error messages are clear and helpful
- [ ] Limits refresh automatically
- [ ] Manual refresh works
- [ ] Limits info view shows complete information

## Common Issues and Solutions

### Issue: Limits not loading
**Cause**: SDK not connected or network issues
**Solution**: Check SDK connection and retry with exponential backoff

### Issue: Validation too strict
**Cause**: Limits are very restrictive
**Solution**: Display clear explanations and suggest alternatives

### Issue: Stale limits
**Cause**: Limits not refreshing properly
**Solution**: Implement proper refresh logic with timestamps

## Estimated Development Time
**1-2 days** for experienced iOS developer

### Breakdown:
- Day 1: PaymentLimitsManager and validation logic
- Day 2: UI integration and testing

## Success Criteria
- [ ] Payment limits are fetched and displayed correctly
- [ ] Amount validation prevents invalid payments
- [ ] Users receive clear feedback about limits
- [ ] Limits refresh automatically when needed
- [ ] Manual refresh works reliably
- [ ] Error handling covers all scenarios

## References
- [Breez SDK Receiving Payments](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html)
- [Lightning Payment Limits](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#lightning)
- [Onchain Payment Limits](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#bitcoin)
