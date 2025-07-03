# BOLT12 Offer Support

## Status: ❌ Missing (Important Priority)

## Overview
**Purpose**: Generate reusable payment codes for multiple payments, improving user experience.

**Documentation**: [Receiving Payments - BOLT12](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#bolt12-offer)

**User Impact**: BOLT12 offers allow users to create reusable payment codes that can be paid multiple times, similar to a Lightning address. This is essential for merchants, content creators, and anyone who needs to receive recurring payments without generating new invoices each time.

## Implementation Details

### Files to Create/Modify
- **Modify**: `Lumen/Views/ReceivePaymentView.swift` (add BOLT12 option)
- **Modify**: `Lumen/Wallet/WalletManager.swift` (add BOLT12 methods)
- **Create**: `Lumen/Views/OfferManagementView.swift` (new file)
- **Create**: `Lumen/Wallet/OfferManager.swift` (new file)

### Dependencies
- Webhook integration for offline BOLT12 requests

## BOLT12 Offer Concepts

### What is a BOLT12 Offer?
- **Reusable**: Single offer can be paid multiple times
- **Flexible**: Can specify amount or allow payer to choose
- **Secure**: Each payment uses unique invoice
- **Offline**: Works even when wallet is offline (with webhooks)

### Offer Types
1. **Fixed Amount**: Offer specifies exact amount
2. **Flexible Amount**: Payer chooses amount within limits
3. **Donation**: Any amount accepted

## Core Implementation

### Step 1: Create OfferManager
Create `Lumen/Wallet/OfferManager.swift`:

```swift
import Foundation
import BreezSDKLiquid

class OfferManager: ObservableObject {
    @Published var activeOffers: [OfferInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let walletManager = WalletManager.shared
    private let errorHandler = ErrorHandler.shared
    
    static let shared = OfferManager()
    private init() {}
    
    /// Create a new BOLT12 offer
    func createOffer(
        amount: UInt64?,
        description: String,
        issuer: String? = nil
    ) async throws -> String {
        guard let sdk = walletManager.sdk else {
            throw OfferError.sdkNotConnected
        }
        
        let offerRequest = ReceivePaymentRequest(
            amountSat: amount,
            description: description,
            useDescriptionHash: false
        )
        
        let response = try await sdk.receivePayment(req: offerRequest)
        
        guard case .bolt12(let offer) = response.destination else {
            throw OfferError.invalidOfferResponse
        }
        
        // Store offer information
        let offerInfo = OfferInfo(
            offer: offer,
            amount: amount,
            description: description,
            issuer: issuer,
            createdAt: Date(),
            isActive: true
        )
        
        await MainActor.run {
            activeOffers.append(offerInfo)
        }
        
        logInfo("Created BOLT12 offer: \(offer)")
        return offer
    }
    
    /// Disable an active offer
    func disableOffer(_ offerInfo: OfferInfo) async {
        // Note: Breez SDK doesn't have explicit offer disabling
        // We handle this locally by marking as inactive
        await MainActor.run {
            if let index = activeOffers.firstIndex(where: { $0.id == offerInfo.id }) {
                activeOffers[index].isActive = false
            }
        }
        
        logInfo("Disabled offer: \(offerInfo.offer)")
    }
    
    /// Remove an offer from local list
    func removeOffer(_ offerInfo: OfferInfo) async {
        await MainActor.run {
            activeOffers.removeAll { $0.id == offerInfo.id }
        }
        
        logInfo("Removed offer: \(offerInfo.offer)")
    }
    
    /// Load offer payment history
    func getOfferPayments(for offer: String) async throws -> [Payment] {
        guard let sdk = walletManager.sdk else {
            throw OfferError.sdkNotConnected
        }
        
        // Get all payments and filter by offer
        let allPayments = try await sdk.listPayments(req: ListPaymentsRequest())
        
        return allPayments.filter { payment in
            // Check if payment is related to this offer
            // This would need to be implemented based on how Breez SDK tracks offer payments
            return false // Placeholder - implement based on SDK capabilities
        }
    }
    
    /// Validate offer string
    func validateOffer(_ offerString: String) -> Bool {
        return offerString.lowercased().hasPrefix("lno1") && offerString.count > 20
    }
    
    /// Parse offer details from string
    func parseOffer(_ offerString: String) throws -> ParsedOffer {
        guard let sdk = walletManager.sdk else {
            throw OfferError.sdkNotConnected
        }
        
        // Use SDK to parse offer
        // This would need to be implemented based on SDK parsing capabilities
        throw OfferError.notImplemented
    }
}

struct OfferInfo: Identifiable, Codable {
    let id = UUID()
    let offer: String
    let amount: UInt64?
    let description: String
    let issuer: String?
    let createdAt: Date
    var isActive: Bool
    
    var displayAmount: String {
        if let amount = amount {
            return "\(amount) sats"
        } else {
            return "Any amount"
        }
    }
    
    var shortOffer: String {
        let prefix = String(offer.prefix(20))
        let suffix = String(offer.suffix(10))
        return "\(prefix)...\(suffix)"
    }
}

struct ParsedOffer {
    let amount: UInt64?
    let description: String?
    let issuer: String?
    let isValid: Bool
}

enum OfferError: LocalizedError {
    case sdkNotConnected
    case invalidOfferResponse
    case notImplemented
    case invalidOffer
    
    var errorDescription: String? {
        switch self {
        case .sdkNotConnected:
            return "Wallet not connected"
        case .invalidOfferResponse:
            return "Invalid offer response from SDK"
        case .notImplemented:
            return "Feature not yet implemented"
        case .invalidOffer:
            return "Invalid BOLT12 offer"
        }
    }
}
```

### Step 2: Enhance ReceivePaymentView with BOLT12 Support
Update `Lumen/Views/ReceivePaymentView.swift`:

```swift
struct ReceivePaymentView: View {
    // ... existing properties ...
    @State private var selectedPaymentType: PaymentType = .lightning
    @State private var offerDescription = ""
    @State private var offerIssuer = ""
    @State private var showingOfferManagement = false
    @StateObject private var offerManager = OfferManager.shared
    
    enum PaymentType: String, CaseIterable {
        case lightning = "Lightning Invoice"
        case bolt12 = "BOLT12 Offer"
        case bitcoin = "Bitcoin Address"
        
        var icon: String {
            switch self {
            case .lightning: return "bolt.fill"
            case .bolt12: return "repeat.circle.fill"
            case .bitcoin: return "bitcoinsign.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Payment Type Selector
                PaymentTypeSelector(selectedType: $selectedPaymentType)
                
                // Content based on selected type
                switch selectedPaymentType {
                case .lightning:
                    LightningInvoiceSection()
                case .bolt12:
                    BOLT12OfferSection()
                case .bitcoin:
                    BitcoinAddressSection()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Receive Payment")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedPaymentType == .bolt12 {
                        Button("Manage") {
                            showingOfferManagement = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingOfferManagement) {
                OfferManagementView()
            }
        }
    }
    
    @ViewBuilder
    private func BOLT12OfferSection() -> some View {
        VStack(spacing: 20) {
            // Amount Input (Optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (optional)")
                    .font(.headline)
                
                TextField("Leave empty for any amount", text: $amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Text("If empty, payer can choose any amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Description Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                TextField("What is this payment for?", text: $offerDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Issuer Input (Optional)
            VStack(alignment: .leading, spacing: 8) {
                Text("Issuer (optional)")
                    .font(.headline)
                
                TextField("Your name or business", text: $offerIssuer)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Create Offer Button
            Button(action: createBOLT12Offer) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating Offer...")
                    }
                } else {
                    Text("Create BOLT12 Offer")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(offerDescription.isEmpty || isLoading)
            
            // Generated Offer Display
            if let generatedOffer = generatedOffer {
                BOLT12OfferDisplay(offer: generatedOffer)
            }
        }
    }
    
    private func createBOLT12Offer() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let amountSats = amount.isEmpty ? nil : UInt64(amount)
                let issuerName = offerIssuer.isEmpty ? nil : offerIssuer
                
                let offer = try await offerManager.createOffer(
                    amount: amountSats,
                    description: offerDescription,
                    issuer: issuerName
                )
                
                await MainActor.run {
                    generatedOffer = offer
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

struct PaymentTypeSelector: View {
    @Binding var selectedType: ReceivePaymentView.PaymentType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(ReceivePaymentView.PaymentType.allCases, id: \.self) { type in
                    PaymentTypeButton(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
}

struct PaymentTypeButton: View {
    let type: ReceivePaymentView.PaymentType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BOLT12OfferDisplay: View {
    let offer: String
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your BOLT12 Offer")
                .font(.headline)
            
            // QR Code
            QRCodeView(data: offer)
                .frame(width: 200, height: 200)
                .background(Color.white)
                .cornerRadius(8)
            
            // Offer String
            VStack(alignment: .leading, spacing: 8) {
                Text("Offer Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(offer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        UIPasteboard.general.string = offer
                        // Show copied feedback
                    }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Copy") {
                    UIPasteboard.general.string = offer
                    // Show copied feedback
                }
                .buttonStyle(.bordered)
                
                Button("Share") {
                    showingShareSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [offer])
        }
    }
}
```

### Step 3: Create OfferManagementView
Create `Lumen/Views/OfferManagementView.swift`:

```swift
import SwiftUI

struct OfferManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var offerManager = OfferManager.shared
    @State private var showingCreateOffer = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if offerManager.isLoading {
                    LoadingView(message: "Loading offers...")
                } else if offerManager.activeOffers.isEmpty {
                    EmptyOffersView {
                        showingCreateOffer = true
                    }
                } else {
                    OfferListView()
                }
            }
            .navigationTitle("BOLT12 Offers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showingCreateOffer = true
                    }
                }
            }
            .sheet(isPresented: $showingCreateOffer) {
                CreateOfferView()
            }
        }
    }
    
    @ViewBuilder
    private func OfferListView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(offerManager.activeOffers) { offer in
                    OfferCard(offer: offer)
                }
            }
            .padding()
        }
    }
}

struct OfferCard: View {
    let offer: OfferInfo
    @StateObject private var offerManager = OfferManager.shared
    @State private var showingDetails = false
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.description)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(offer.displayAmount)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    StatusBadge(isActive: offer.isActive)
                    
                    Menu {
                        Button("View Details") {
                            showingDetails = true
                        }
                        
                        Button("Share") {
                            showingShareSheet = true
                        }
                        
                        if offer.isActive {
                            Button("Disable") {
                                Task {
                                    await offerManager.disableOffer(offer)
                                }
                            }
                        }
                        
                        Button("Remove", role: .destructive) {
                            Task {
                                await offerManager.removeOffer(offer)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Offer Preview
            Text(offer.shortOffer)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(4)
            
            // Creation Date
            Text("Created \(offer.createdAt, style: .relative) ago")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingDetails) {
            OfferDetailsView(offer: offer)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [offer.offer])
        }
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Active" : "Disabled")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(isActive ? .green : .orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                (isActive ? Color.green : Color.orange).opacity(0.2)
            )
            .cornerRadius(4)
    }
}

struct OfferDetailsView: View {
    let offer: OfferInfo
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // QR Code
                    VStack(spacing: 16) {
                        QRCodeView(data: offer.offer)
                            .frame(width: 250, height: 250)
                            .background(Color.white)
                            .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Button("Copy") {
                                UIPasteboard.general.string = offer.offer
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Share") {
                                showingShareSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    // Offer Details
                    OfferDetailsSection(offer: offer)
                    
                    // Payment History
                    // PaymentHistorySection(offer: offer)
                }
                .padding()
            }
            .navigationTitle("Offer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [offer.offer])
            }
        }
    }
}

struct OfferDetailsSection: View {
    let offer: OfferInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offer Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(label: "Description", value: offer.description)
                DetailRow(label: "Amount", value: offer.displayAmount)
                
                if let issuer = offer.issuer {
                    DetailRow(label: "Issuer", value: issuer)
                }
                
                DetailRow(label: "Status", value: offer.isActive ? "Active" : "Disabled")
                DetailRow(label: "Created", value: DateFormatter.localizedString(from: offer.createdAt, dateStyle: .medium, timeStyle: .short))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Offer Code")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(offer.offer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        UIPasteboard.general.string = offer.offer
                    }
            }
        }
    }
}

struct DetailRow: View {
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
        }
    }
}

struct CreateOfferView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var offerManager = OfferManager.shared
    
    @State private var amount = ""
    @State private var description = ""
    @State private var issuer = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (optional)")
                        .font(.headline)
                    
                    TextField("Leave empty for any amount", text: $amount)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("If empty, payer can choose any amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextField("What is this payment for?", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Issuer (optional)")
                        .font(.headline)
                    
                    TextField("Your name or business", text: $issuer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: createOffer) {
                    if isCreating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Creating...")
                        }
                    } else {
                        Text("Create Offer")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty || isCreating)
            }
            .padding()
            .navigationTitle("Create BOLT12 Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createOffer() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                let amountSats = amount.isEmpty ? nil : UInt64(amount)
                let issuerName = issuer.isEmpty ? nil : issuer
                
                _ = try await offerManager.createOffer(
                    amount: amountSats,
                    description: description,
                    issuer: issuerName
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isCreating = false
                }
            }
        }
    }
}

struct EmptyOffersView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No BOLT12 Offers")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create reusable payment codes that can be paid multiple times")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create First Offer") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### Step 4: Add BOLT12 Methods to WalletManager
Add to `Lumen/Wallet/WalletManager.swift`:

```swift
// MARK: - BOLT12 Offers

/// Create a BOLT12 offer
func createBOLT12Offer(
    amount: UInt64?,
    description: String
) async throws -> String {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    let request = ReceivePaymentRequest(
        amountSat: amount,
        description: description,
        useDescriptionHash: false
    )
    
    let response = try await sdk.receivePayment(req: request)
    
    guard case .bolt12(let offer) = response.destination else {
        throw WalletError.invalidResponse("Expected BOLT12 offer")
    }
    
    return offer
}

/// Pay a BOLT12 offer
func payBOLT12Offer(
    offer: String,
    amount: UInt64?
) async throws -> SendPaymentResponse {
    guard let sdk = sdk else {
        throw WalletError.notConnected
    }
    
    let prepareRequest = PreparePayOfferRequest(
        offer: offer,
        amountSat: amount
    )
    
    let prepareResponse = try await sdk.preparePayOffer(req: prepareRequest)
    
    let payRequest = PayOfferRequest(
        prepareResponse: prepareResponse
    )
    
    return try await sdk.payOffer(req: payRequest)
}
```

## Testing Strategy

### Unit Tests
```swift
func testBOLT12OfferCreation() async {
    let offerManager = OfferManager.shared
    
    do {
        let offer = try await offerManager.createOffer(
            amount: 1000,
            description: "Test offer",
            issuer: "Test issuer"
        )
        
        XCTAssertTrue(offer.hasPrefix("lno1"))
        XCTAssertEqual(offerManager.activeOffers.count, 1)
    } catch {
        XCTFail("Offer creation failed: \(error)")
    }
}

func testOfferValidation() {
    let offerManager = OfferManager.shared
    
    XCTAssertTrue(offerManager.validateOffer("lno1qcp4256ypqpq86q564hz..."))
    XCTAssertFalse(offerManager.validateOffer("invalid_offer"))
    XCTAssertFalse(offerManager.validateOffer(""))
}
```

### Integration Tests
1. **Create BOLT12 Offer**: Generate offer with various parameters
2. **Pay BOLT12 Offer**: Test payment flow with created offer
3. **Offline Payment**: Test webhook handling for offline offers
4. **Offer Management**: Test enable/disable/remove functionality

### Manual Testing Checklist
- [ ] BOLT12 offers can be created with and without amounts
- [ ] QR codes display correctly for offers
- [ ] Offers can be shared and copied
- [ ] Offer management view shows all offers
- [ ] Offers can be disabled and removed
- [ ] Payments to offers work correctly
- [ ] Webhook integration works for offline offers

## Common Issues and Solutions

### Issue: BOLT12 not supported
**Cause**: Older Breez SDK version or network doesn't support BOLT12
**Solution**: Check SDK version and network compatibility

### Issue: Offer payments not received
**Cause**: Webhook not configured for offline payments
**Solution**: Ensure webhook integration is properly set up

### Issue: Invalid offer format
**Cause**: Offer string corrupted or incomplete
**Solution**: Validate offer format and regenerate if needed

## Estimated Development Time
**3-4 days** for experienced iOS developer

### Breakdown:
- Day 1: OfferManager and core BOLT12 logic
- Day 2: Enhanced ReceivePaymentView with BOLT12 support
- Day 3: OfferManagementView implementation
- Day 4: Testing and webhook integration

## Success Criteria
- [ ] Users can create BOLT12 offers with flexible amounts
- [ ] Offers display as QR codes and can be shared
- [ ] Offer management interface works correctly
- [ ] Payments to offers are received and processed
- [ ] Offline offer payments work with webhooks
- [ ] Error handling covers all failure scenarios

## References
- [Breez SDK BOLT12 Offers](https://sdk-doc-liquid.breez.technology/guide/receive_payment.html#bolt12-offer)
- [BOLT12 Specification](https://github.com/lightning/bolts/blob/master/12-offer-encoding.md)
- [Lightning Offers Explained](https://bitcoinops.org/en/topics/offers/)
