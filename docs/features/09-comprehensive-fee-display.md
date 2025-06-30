# Comprehensive Fee Display

## Status: ⚠️ Partial (Needs Completion)

## Overview
**Purpose**: Show detailed fee breakdown for different payment types (submarine swap vs direct Liquid).

**Documentation**: [End-User Fees](https://sdk-doc-liquid.breez.technology/guide/end-user_fees.html)

**User Impact**: Users need to understand the costs of different payment methods to make informed decisions. Without clear fee information, users may choose expensive options or be surprised by unexpected fees.

## Current Implementation Status

### ✅ What's Already Implemented
- Basic fee display in `FeeComparisonView.swift`
- Simple fee calculation for Lightning payments
- Basic fee information in payment preparation

### ⚠️ What Needs Enhancement
- Detailed fee breakdown by payment type
- Real-time fee comparison between Lightning and Bitcoin
- Fee explanation and education
- Dynamic fee updates based on network conditions

## Implementation Details

### Files to Modify/Enhance
- **Enhance**: `Lumen/Views/FeeComparisonView.swift` (existing file needs major enhancement)
- **Modify**: `Lumen/Views/SendPaymentView.swift` (improve fee display)
- **Modify**: `Lumen/Views/ReceivePaymentView.swift` (add fee information)
- **Create**: `Lumen/Wallet/FeeCalculator.swift` (new file)

### Dependencies
- None (can be implemented independently)

## Fee Types in Breez SDK Liquid

### Lightning Payments
- **Service Fee**: Breez service fee (usually 0.4%)
- **Routing Fee**: Lightning network routing fees
- **No Onchain Fees**: Direct Liquid payments

### Bitcoin Payments (Submarine Swaps)
- **Service Fee**: Breez service fee
- **Onchain Fee**: Bitcoin network transaction fee
- **Swap Fee**: Submarine swap operation fee

### Liquid Payments
- **Minimal Fees**: Direct Liquid network fees
- **Fast Settlement**: Near-instant confirmation

## Enhanced Implementation

### Step 1: Create FeeCalculator
Create `Lumen/Wallet/FeeCalculator.swift`:

```swift
import Foundation
import BreezSDKLiquid

class FeeCalculator: ObservableObject {
    @Published var lightningFees: LightningFeeBreakdown?
    @Published var bitcoinFees: BitcoinFeeBreakdown?
    @Published var liquidFees: LiquidFeeBreakdown?
    @Published var isCalculating = false
    
    private let walletManager = WalletManager.shared
    
    static let shared = FeeCalculator()
    private init() {}
    
    /// Calculate fees for all payment methods
    func calculateAllFees(for amount: UInt64) async {
        await MainActor.run {
            isCalculating = true
        }
        
        async let lightningTask = calculateLightningFees(amount: amount)
        async let bitcoinTask = calculateBitcoinFees(amount: amount)
        async let liquidTask = calculateLiquidFees(amount: amount)
        
        await lightningTask
        await bitcoinTask
        await liquidTask
        
        await MainActor.run {
            isCalculating = false
        }
    }
    
    /// Calculate Lightning payment fees
    func calculateLightningFees(amount: UInt64) async {
        do {
            guard let sdk = walletManager.sdk else { return }
            
            // Get service fee rate
            let serviceFeeRate = 0.004 // 0.4% - this should come from SDK config
            let serviceFee = UInt64(Double(amount) * serviceFeeRate)
            
            // Estimate routing fees (typically very small for Lightning)
            let routingFee: UInt64 = max(1, amount / 1000) // Rough estimate
            
            let breakdown = LightningFeeBreakdown(
                amount: amount,
                serviceFee: serviceFee,
                routingFee: routingFee,
                totalFee: serviceFee + routingFee,
                feePercentage: Double(serviceFee + routingFee) / Double(amount) * 100
            )
            
            await MainActor.run {
                lightningFees = breakdown
            }
        } catch {
            logError("Failed to calculate Lightning fees: \(error)")
        }
    }
    
    /// Calculate Bitcoin payment fees
    func calculateBitcoinFees(amount: UInt64) async {
        do {
            guard let sdk = walletManager.sdk else { return }
            
            // Get recommended fees for Bitcoin network
            let recommendedFees = try await sdk.recommendedFees()
            
            // Estimate submarine swap fees
            let serviceFeeRate = 0.004 // 0.4%
            let serviceFee = UInt64(Double(amount) * serviceFeeRate)
            
            // Estimate onchain fee (depends on current network conditions)
            let onchainFee = UInt64(recommendedFees.hourFee) * 250 // Rough estimate for swap transaction
            
            // Swap operation fee
            let swapFee: UInt64 = 1000 // Fixed swap fee in sats
            
            let totalFee = serviceFee + onchainFee + swapFee
            
            let breakdown = BitcoinFeeBreakdown(
                amount: amount,
                serviceFee: serviceFee,
                onchainFee: onchainFee,
                swapFee: swapFee,
                totalFee: totalFee,
                feePercentage: Double(totalFee) / Double(amount) * 100,
                estimatedConfirmationTime: "~10 minutes"
            )
            
            await MainActor.run {
                bitcoinFees = breakdown
            }
        } catch {
            logError("Failed to calculate Bitcoin fees: \(error)")
        }
    }
    
    /// Calculate Liquid payment fees
    func calculateLiquidFees(amount: UInt64) async {
        // Liquid fees are minimal
        let liquidFee: UInt64 = 100 // Very small fixed fee
        
        let breakdown = LiquidFeeBreakdown(
            amount: amount,
            networkFee: liquidFee,
            totalFee: liquidFee,
            feePercentage: Double(liquidFee) / Double(amount) * 100,
            estimatedConfirmationTime: "~2 minutes"
        )
        
        await MainActor.run {
            liquidFees = breakdown
        }
    }
    
    /// Get the most cost-effective payment method
    func getBestPaymentMethod() -> PaymentMethodRecommendation? {
        guard let lightning = lightningFees,
              let bitcoin = bitcoinFees,
              let liquid = liquidFees else {
            return nil
        }
        
        let methods = [
            (method: PaymentMethod.lightning, fee: lightning.totalFee, time: "Instant"),
            (method: PaymentMethod.bitcoin, fee: bitcoin.totalFee, time: bitcoin.estimatedConfirmationTime),
            (method: PaymentMethod.liquid, fee: liquid.totalFee, time: liquid.estimatedConfirmationTime)
        ]
        
        let cheapest = methods.min { $0.fee < $1.fee }!
        let fastest = methods.min { $0.time == "Instant" ? 0 : 1 }!
        
        return PaymentMethodRecommendation(
            cheapest: cheapest.method,
            fastest: fastest.method,
            recommended: cheapest.fee < fastest.fee * 2 ? cheapest.method : fastest.method
        )
    }
}

// MARK: - Data Models

struct LightningFeeBreakdown {
    let amount: UInt64
    let serviceFee: UInt64
    let routingFee: UInt64
    let totalFee: UInt64
    let feePercentage: Double
    
    var displayItems: [FeeDisplayItem] {
        [
            FeeDisplayItem(label: "Service Fee", amount: serviceFee, description: "Breez service fee"),
            FeeDisplayItem(label: "Routing Fee", amount: routingFee, description: "Lightning network routing"),
            FeeDisplayItem(label: "Total Fee", amount: totalFee, description: "Total cost", isTotal: true)
        ]
    }
}

struct BitcoinFeeBreakdown {
    let amount: UInt64
    let serviceFee: UInt64
    let onchainFee: UInt64
    let swapFee: UInt64
    let totalFee: UInt64
    let feePercentage: Double
    let estimatedConfirmationTime: String
    
    var displayItems: [FeeDisplayItem] {
        [
            FeeDisplayItem(label: "Service Fee", amount: serviceFee, description: "Breez service fee"),
            FeeDisplayItem(label: "Network Fee", amount: onchainFee, description: "Bitcoin network fee"),
            FeeDisplayItem(label: "Swap Fee", amount: swapFee, description: "Submarine swap operation"),
            FeeDisplayItem(label: "Total Fee", amount: totalFee, description: "Total cost", isTotal: true)
        ]
    }
}

struct LiquidFeeBreakdown {
    let amount: UInt64
    let networkFee: UInt64
    let totalFee: UInt64
    let feePercentage: Double
    let estimatedConfirmationTime: String
    
    var displayItems: [FeeDisplayItem] {
        [
            FeeDisplayItem(label: "Network Fee", amount: networkFee, description: "Liquid network fee"),
            FeeDisplayItem(label: "Total Fee", amount: totalFee, description: "Total cost", isTotal: true)
        ]
    }
}

struct FeeDisplayItem {
    let label: String
    let amount: UInt64
    let description: String
    var isTotal: Bool = false
}

struct PaymentMethodRecommendation {
    let cheapest: PaymentMethod
    let fastest: PaymentMethod
    let recommended: PaymentMethod
}

enum PaymentMethod {
    case lightning
    case bitcoin
    case liquid
    
    var displayName: String {
        switch self {
        case .lightning: return "Lightning"
        case .bitcoin: return "Bitcoin"
        case .liquid: return "Liquid"
        }
    }
    
    var icon: String {
        switch self {
        case .lightning: return "bolt.fill"
        case .bitcoin: return "bitcoinsign.circle.fill"
        case .liquid: return "drop.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lightning: return .orange
        case .bitcoin: return .blue
        case .liquid: return .green
        }
    }
}
```

### Step 2: Enhance FeeComparisonView
Replace the existing `Lumen/Views/FeeComparisonView.swift`:

```swift
import SwiftUI

struct FeeComparisonView: View {
    let amount: UInt64
    @Environment(\.dismiss) private var dismiss
    @StateObject private var feeCalculator = FeeCalculator.shared
    @State private var selectedMethod: PaymentMethod = .lightning
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Display
                    AmountDisplaySection(amount: amount)
                    
                    // Fee Calculation Status
                    if feeCalculator.isCalculating {
                        CalculatingFeesView()
                    } else {
                        // Payment Method Comparison
                        PaymentMethodComparisonSection(
                            selectedMethod: $selectedMethod,
                            feeCalculator: feeCalculator
                        )
                        
                        // Detailed Fee Breakdown
                        DetailedFeeBreakdownSection(
                            selectedMethod: selectedMethod,
                            feeCalculator: feeCalculator
                        )
                        
                        // Recommendation
                        if let recommendation = feeCalculator.getBestPaymentMethod() {
                            RecommendationSection(recommendation: recommendation)
                        }
                        
                        // Educational Information
                        FeeEducationSection()
                    }
                }
                .padding()
            }
            .navigationTitle("Fee Comparison")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await feeCalculator.calculateAllFees(for: amount)
            }
        }
    }
}

struct AmountDisplaySection: View {
    let amount: UInt64
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Payment Amount")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(amount) sats")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PaymentMethodComparisonSection: View {
    @Binding var selectedMethod: PaymentMethod
    @ObservedObject var feeCalculator: FeeCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Methods")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let lightning = feeCalculator.lightningFees {
                    PaymentMethodCard(
                        method: .lightning,
                        totalFee: lightning.totalFee,
                        feePercentage: lightning.feePercentage,
                        estimatedTime: "Instant",
                        isSelected: selectedMethod == .lightning
                    ) {
                        selectedMethod = .lightning
                    }
                }
                
                if let bitcoin = feeCalculator.bitcoinFees {
                    PaymentMethodCard(
                        method: .bitcoin,
                        totalFee: bitcoin.totalFee,
                        feePercentage: bitcoin.feePercentage,
                        estimatedTime: bitcoin.estimatedConfirmationTime,
                        isSelected: selectedMethod == .bitcoin
                    ) {
                        selectedMethod = .bitcoin
                    }
                }
                
                if let liquid = feeCalculator.liquidFees {
                    PaymentMethodCard(
                        method: .liquid,
                        totalFee: liquid.totalFee,
                        feePercentage: liquid.feePercentage,
                        estimatedTime: liquid.estimatedConfirmationTime,
                        isSelected: selectedMethod == .liquid
                    ) {
                        selectedMethod = .liquid
                    }
                }
            }
        }
    }
}

struct PaymentMethodCard: View {
    let method: PaymentMethod
    let totalFee: UInt64
    let feePercentage: Double
    let estimatedTime: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Method Icon
                Image(systemName: method.icon)
                    .font(.title2)
                    .foregroundColor(method.color)
                    .frame(width: 30)
                
                // Method Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(estimatedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Fee Info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalFee) sats")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("(\(feePercentage, specifier: "%.2f")%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailedFeeBreakdownSection: View {
    let selectedMethod: PaymentMethod
    @ObservedObject var feeCalculator: FeeCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fee Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                switch selectedMethod {
                case .lightning:
                    if let lightning = feeCalculator.lightningFees {
                        ForEach(lightning.displayItems.indices, id: \.self) { index in
                            FeeBreakdownRow(item: lightning.displayItems[index])
                        }
                    }
                    
                case .bitcoin:
                    if let bitcoin = feeCalculator.bitcoinFees {
                        ForEach(bitcoin.displayItems.indices, id: \.self) { index in
                            FeeBreakdownRow(item: bitcoin.displayItems[index])
                        }
                    }
                    
                case .liquid:
                    if let liquid = feeCalculator.liquidFees {
                        ForEach(liquid.displayItems.indices, id: \.self) { index in
                            FeeBreakdownRow(item: liquid.displayItems[index])
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeeBreakdownRow: View {
    let item: FeeDisplayItem
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(item.label)
                    .font(item.isTotal ? .headline : .subheadline)
                    .fontWeight(item.isTotal ? .semibold : .regular)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(item.amount) sats")
                    .font(item.isTotal ? .headline : .subheadline)
                    .fontWeight(item.isTotal ? .semibold : .regular)
                    .foregroundColor(item.isTotal ? .primary : .secondary)
            }
            
            if !item.description.isEmpty {
                HStack {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            if item.isTotal {
                Divider()
            }
        }
    }
}

struct RecommendationSection: View {
    let recommendation: PaymentMethodRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            VStack(spacing: 8) {
                RecommendationRow(
                    icon: "dollarsign.circle.fill",
                    title: "Cheapest",
                    method: recommendation.cheapest,
                    color: .green
                )
                
                RecommendationRow(
                    icon: "clock.fill",
                    title: "Fastest",
                    method: recommendation.fastest,
                    color: .blue
                )
                
                RecommendationRow(
                    icon: "star.fill",
                    title: "Recommended",
                    method: recommendation.recommended,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let method: PaymentMethod
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: method.icon)
                    .foregroundColor(method.color)
                
                Text(method.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct FeeEducationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Understanding Fees")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                EducationItem(
                    icon: "bolt.fill",
                    title: "Lightning Payments",
                    description: "Fast and cheap for smaller amounts. Uses Liquid network directly when possible.",
                    color: .orange
                )
                
                EducationItem(
                    icon: "bitcoinsign.circle.fill",
                    title: "Bitcoin Payments",
                    description: "Higher fees but works with any Bitcoin wallet. Includes network and swap fees.",
                    color: .blue
                )
                
                EducationItem(
                    icon: "drop.circle.fill",
                    title: "Liquid Payments",
                    description: "Minimal fees with fast settlement. Best for Liquid-compatible wallets.",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EducationItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CalculatingFeesView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Calculating fees...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Comparing Lightning, Bitcoin, and Liquid options")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

### Step 3: Integrate Enhanced Fee Display in SendPaymentView
Update `Lumen/Views/SendPaymentView.swift`:

```swift
// Add to existing SendPaymentView
@State private var showingFeeComparison = false

// Add button to show fee comparison
Button("Compare Fees") {
    showingFeeComparison = true
}
.buttonStyle(.bordered)
.sheet(isPresented: $showingFeeComparison) {
    if let amount = UInt64(amount) {
        FeeComparisonView(amount: amount)
    }
}
```

## Testing Strategy

### Unit Tests
```swift
func testFeeCalculation() async {
    let calculator = FeeCalculator.shared
    await calculator.calculateAllFees(for: 100000)
    
    XCTAssertNotNil(calculator.lightningFees)
    XCTAssertNotNil(calculator.bitcoinFees)
    XCTAssertNotNil(calculator.liquidFees)
}

func testPaymentMethodRecommendation() {
    let calculator = FeeCalculator.shared
    // Set up mock fee data
    let recommendation = calculator.getBestPaymentMethod()
    XCTAssertNotNil(recommendation)
}
```

### Integration Tests
1. **Fee Calculation**: Test fee calculation for different amounts
2. **UI Updates**: Verify UI updates correctly with calculated fees
3. **Method Comparison**: Test payment method comparison logic
4. **Real-time Updates**: Test fee updates with network conditions

### Manual Testing Checklist
- [ ] Fee breakdown displays correctly for all payment methods
- [ ] Recommendations are accurate and helpful
- [ ] Educational information is clear and informative
- [ ] Fee calculations update with amount changes
- [ ] UI is responsive and intuitive

## Common Issues and Solutions

### Issue: Fee calculation takes too long
**Cause**: Network requests for fee estimation
**Solution**: Implement caching and background updates

### Issue: Fee estimates are inaccurate
**Cause**: Network conditions change rapidly
**Solution**: Add disclaimers and refresh mechanisms

### Issue: Users don't understand fee differences
**Cause**: Complex fee structures
**Solution**: Provide clear explanations and visual comparisons

## Estimated Development Time
**1-2 days** for experienced iOS developer

### Breakdown:
- Day 1: FeeCalculator implementation and enhanced FeeComparisonView
- Day 2: Integration and testing

## Success Criteria
- [ ] Detailed fee breakdown for all payment methods
- [ ] Clear comparison between Lightning, Bitcoin, and Liquid
- [ ] Educational information helps users understand fees
- [ ] Recommendations guide users to optimal choices
- [ ] Real-time fee updates work correctly
- [ ] UI is intuitive and informative

## References
- [Breez SDK End-User Fees](https://sdk-doc-liquid.breez.technology/guide/end-user_fees.html)
- [Lightning Network Fee Structure](https://docs.lightning.engineering/lightning-network-tools/lnd/optimal-fee-estimation)
- [Bitcoin Fee Estimation](https://bitcoiner.guide/fee/)
