# Enhanced Payment Input Parsing

## Status: ❌ Missing (Important Priority)

## Overview
**Purpose**: Support BIP353 addresses, LNURL, and comprehensive payment format validation.

**Documentation**: [Parsing Inputs](https://sdk-doc-liquid.breez.technology/guide/parse.html)

**User Impact**: Users expect to paste any Lightning-related string and have the wallet intelligently parse it. Without comprehensive parsing, users get frustrated when valid payment codes don't work, leading to poor user experience and failed payments.

## Implementation Details

### Files to Create/Modify
- **Modify**: `Lumen/Wallet/WalletManager.swift` (enhance `parseInput()` method)
- **Modify**: `Lumen/Views/SendPaymentView.swift` (improve input validation UI)
- **Create**: `Lumen/Wallet/PaymentInputParser.swift` (new file)

### Dependencies
- None (can be implemented independently)

## Supported Input Formats

### Current Support (Basic)
- ✅ Lightning invoices (BOLT11)
- ✅ Bitcoin addresses
- ✅ Lightning node URIs

### Missing Support (To Implement)
- ❌ BOLT12 offers
- ❌ Lightning addresses (user@domain.com)
- ❌ BIP353 DNS payment instructions
- ❌ LNURL-pay links
- ❌ LNURL-withdraw links
- ❌ Bitcoin URIs with parameters
- ❌ Liquid addresses
- ❌ Unified QR codes

## Core Implementation

### Step 1: Create PaymentInputParser
Create `Lumen/Wallet/PaymentInputParser.swift`:

```swift
import Foundation
import BreezSDKLiquid

class PaymentInputParser {
    private let walletManager = WalletManager.shared
    
    static let shared = PaymentInputParser()
    private init() {}
    
    /// Parse any payment input string
    func parseInput(_ input: String) async throws -> ParsedPaymentInput {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanInput.isEmpty else {
            throw PaymentInputError.emptyInput
        }
        
        // Try SDK parsing first
        if let sdkResult = try? await parseWithSDK(cleanInput) {
            return sdkResult
        }
        
        // Fallback to manual parsing for unsupported formats
        return try await parseManually(cleanInput)
    }
    
    /// Parse using Breez SDK
    private func parseWithSDK(_ input: String) async throws -> ParsedPaymentInput {
        guard let sdk = walletManager.sdk else {
            throw PaymentInputError.sdkNotConnected
        }
        
        let parseRequest = ParseRequest(input: input)
        let parseResponse = try await sdk.parse(req: parseRequest)
        
        return try convertSDKResponse(parseResponse)
    }
    
    /// Manual parsing for formats not supported by SDK
    private func parseManually(_ input: String) async throws -> ParsedPaymentInput {
        let lowercased = input.lowercased()
        
        // Lightning Address (user@domain.com)
        if isLightningAddress(input) {
            return try await parseLightningAddress(input)
        }
        
        // LNURL
        if lowercased.hasPrefix("lnurl") {
            return try await parseLNURL(input)
        }
        
        // BIP353 DNS Payment Instructions
        if lowercased.hasPrefix("bitcoin:") && input.contains("?") {
            return try parseBitcoinURI(input)
        }
        
        // Liquid addresses
        if isLiquidAddress(input) {
            return ParsedPaymentInput(
                type: .liquidAddress,
                address: input,
                amount: nil,
                description: nil,
                isValid: true
            )
        }
        
        throw PaymentInputError.unsupportedFormat
    }
    
    /// Convert SDK parse response to our format
    private func convertSDKResponse(_ response: ParseResponse) throws -> ParsedPaymentInput {
        switch response {
        case .invoice(let invoice):
            return ParsedPaymentInput(
                type: .lightningInvoice,
                invoice: invoice.bolt11,
                amount: invoice.amountMsat.map { $0 / 1000 },
                description: invoice.description,
                isValid: true
            )
            
        case .offer(let offer):
            return ParsedPaymentInput(
                type: .bolt12Offer,
                offer: offer.offer,
                amount: offer.amountMsat.map { $0 / 1000 },
                description: offer.description,
                isValid: true
            )
            
        case .nodeId(let nodeId):
            return ParsedPaymentInput(
                type: .nodeId,
                nodeId: nodeId.nodeId,
                amount: nil,
                description: nil,
                isValid: true
            )
            
        case .url(let url):
            return ParsedPaymentInput(
                type: .url,
                url: url.url,
                amount: nil,
                description: nil,
                isValid: true
            )
        }
    }
    
    /// Parse Lightning Address (user@domain.com)
    private func parseLightningAddress(_ address: String) async throws -> ParsedPaymentInput {
        guard isLightningAddress(address) else {
            throw PaymentInputError.invalidLightningAddress
        }
        
        // Extract domain and user
        let components = address.split(separator: "@")
        guard components.count == 2 else {
            throw PaymentInputError.invalidLightningAddress
        }
        
        let user = String(components[0])
        let domain = String(components[1])
        
        // Fetch LNURL-pay endpoint
        let wellKnownURL = "https://\(domain)/.well-known/lnurlp/\(user)"
        
        do {
            let lnurlPayData = try await fetchLNURLPayData(from: wellKnownURL)
            
            return ParsedPaymentInput(
                type: .lightningAddress,
                lightningAddress: address,
                amount: nil,
                description: lnurlPayData.metadata,
                minAmount: lnurlPayData.minSendable / 1000,
                maxAmount: lnurlPayData.maxSendable / 1000,
                isValid: true
            )
        } catch {
            throw PaymentInputError.lightningAddressResolutionFailed
        }
    }
    
    /// Parse LNURL
    private func parseLNURL(_ lnurl: String) async throws -> ParsedPaymentInput {
        // Decode LNURL
        guard let decodedURL = decodeLNURL(lnurl) else {
            throw PaymentInputError.invalidLNURL
        }
        
        // Fetch LNURL data
        do {
            let lnurlData = try await fetchLNURLData(from: decodedURL)
            
            switch lnurlData.tag {
            case "payRequest":
                return ParsedPaymentInput(
                    type: .lnurlPay,
                    lnurl: lnurl,
                    amount: nil,
                    description: lnurlData.metadata,
                    minAmount: lnurlData.minSendable / 1000,
                    maxAmount: lnurlData.maxSendable / 1000,
                    isValid: true
                )
                
            case "withdrawRequest":
                return ParsedPaymentInput(
                    type: .lnurlWithdraw,
                    lnurl: lnurl,
                    amount: lnurlData.maxWithdrawable / 1000,
                    description: lnurlData.defaultDescription,
                    isValid: true
                )
                
            default:
                throw PaymentInputError.unsupportedLNURLType
            }
        } catch {
            throw PaymentInputError.lnurlResolutionFailed
        }
    }
    
    /// Parse Bitcoin URI with parameters
    private func parseBitcoinURI(_ uri: String) throws -> ParsedPaymentInput {
        guard let url = URL(string: uri),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PaymentInputError.invalidBitcoinURI
        }
        
        let address = url.path
        var amount: UInt64?
        var description: String?
        
        // Parse query parameters
        if let queryItems = components.queryItems {
            for item in queryItems {
                switch item.name.lowercased() {
                case "amount":
                    if let btcAmount = Double(item.value ?? "0") {
                        amount = UInt64(btcAmount * 100_000_000) // Convert BTC to sats
                    }
                case "label", "message":
                    description = item.value
                default:
                    break
                }
            }
        }
        
        return ParsedPaymentInput(
            type: .bitcoinAddress,
            address: address,
            amount: amount,
            description: description,
            isValid: isValidBitcoinAddress(address)
        )
    }
    
    // MARK: - Validation Helpers
    
    private func isLightningAddress(_ input: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return input.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func isLiquidAddress(_ input: String) -> Bool {
        // Liquid addresses start with specific prefixes
        return input.hasPrefix("lq1") || input.hasPrefix("VJL") || input.hasPrefix("VT") || input.hasPrefix("VG")
    }
    
    private func isValidBitcoinAddress(_ address: String) -> Bool {
        // Basic Bitcoin address validation
        let validPrefixes = ["1", "3", "bc1", "tb1"]
        return validPrefixes.contains { address.hasPrefix($0) } && address.count >= 26 && address.count <= 62
    }
    
    // MARK: - Network Helpers
    
    private func fetchLNURLPayData(from url: String) async throws -> LNURLPayData {
        guard let url = URL(string: url) else {
            throw PaymentInputError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LNURLPayData.self, from: data)
    }
    
    private func fetchLNURLData(from url: String) async throws -> LNURLData {
        guard let url = URL(string: url) else {
            throw PaymentInputError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(LNURLData.self, from: data)
    }
    
    private func decodeLNURL(_ lnurl: String) -> String? {
        // LNURL decoding implementation
        // This is a simplified version - full implementation would use bech32 decoding
        return nil // Placeholder
    }
}

// MARK: - Data Models

struct ParsedPaymentInput {
    let type: PaymentInputType
    var invoice: String?
    var offer: String?
    var address: String?
    var nodeId: String?
    var url: String?
    var lnurl: String?
    var lightningAddress: String?
    var amount: UInt64?
    var description: String?
    var minAmount: UInt64?
    var maxAmount: UInt64?
    let isValid: Bool
    
    var displayString: String {
        switch type {
        case .lightningInvoice:
            return invoice ?? ""
        case .bolt12Offer:
            return offer ?? ""
        case .bitcoinAddress:
            return address ?? ""
        case .liquidAddress:
            return address ?? ""
        case .lightningAddress:
            return lightningAddress ?? ""
        case .lnurlPay, .lnurlWithdraw:
            return lnurl ?? ""
        case .nodeId:
            return nodeId ?? ""
        case .url:
            return url ?? ""
        }
    }
}

enum PaymentInputType {
    case lightningInvoice
    case bolt12Offer
    case bitcoinAddress
    case liquidAddress
    case lightningAddress
    case lnurlPay
    case lnurlWithdraw
    case nodeId
    case url
    
    var displayName: String {
        switch self {
        case .lightningInvoice:
            return "Lightning Invoice"
        case .bolt12Offer:
            return "BOLT12 Offer"
        case .bitcoinAddress:
            return "Bitcoin Address"
        case .liquidAddress:
            return "Liquid Address"
        case .lightningAddress:
            return "Lightning Address"
        case .lnurlPay:
            return "LNURL Pay"
        case .lnurlWithdraw:
            return "LNURL Withdraw"
        case .nodeId:
            return "Lightning Node"
        case .url:
            return "URL"
        }
    }
    
    var icon: String {
        switch self {
        case .lightningInvoice:
            return "bolt.fill"
        case .bolt12Offer:
            return "repeat.circle.fill"
        case .bitcoinAddress:
            return "bitcoinsign.circle.fill"
        case .liquidAddress:
            return "drop.circle.fill"
        case .lightningAddress:
            return "at.circle.fill"
        case .lnurlPay, .lnurlWithdraw:
            return "link.circle.fill"
        case .nodeId:
            return "network"
        case .url:
            return "globe.circle.fill"
        }
    }
}

struct LNURLPayData: Codable {
    let callback: String
    let maxSendable: UInt64
    let minSendable: UInt64
    let metadata: String
    let tag: String
}

struct LNURLData: Codable {
    let tag: String
    let callback: String?
    let maxSendable: UInt64?
    let minSendable: UInt64?
    let maxWithdrawable: UInt64?
    let defaultDescription: String?
    let metadata: String?
}

enum PaymentInputError: LocalizedError {
    case emptyInput
    case sdkNotConnected
    case unsupportedFormat
    case invalidLightningAddress
    case lightningAddressResolutionFailed
    case invalidLNURL
    case lnurlResolutionFailed
    case unsupportedLNURLType
    case invalidBitcoinURI
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a payment code"
        case .sdkNotConnected:
            return "Wallet not connected"
        case .unsupportedFormat:
            return "Unsupported payment format"
        case .invalidLightningAddress:
            return "Invalid Lightning address format"
        case .lightningAddressResolutionFailed:
            return "Failed to resolve Lightning address"
        case .invalidLNURL:
            return "Invalid LNURL format"
        case .lnurlResolutionFailed:
            return "Failed to resolve LNURL"
        case .unsupportedLNURLType:
            return "Unsupported LNURL type"
        case .invalidBitcoinURI:
            return "Invalid Bitcoin URI format"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}
```

### Step 2: Enhance WalletManager parseInput Method
Update `Lumen/Wallet/WalletManager.swift`:

```swift
// MARK: - Enhanced Payment Input Parsing

/// Parse payment input with comprehensive format support
func parsePaymentInput(_ input: String) async throws -> ParsedPaymentInput {
    return try await PaymentInputParser.shared.parseInput(input)
}

/// Validate parsed payment input
func validatePaymentInput(_ parsedInput: ParsedPaymentInput) async -> ValidationResult {
    guard parsedInput.isValid else {
        return .invalid("Invalid payment format")
    }
    
    switch parsedInput.type {
    case .lightningInvoice:
        // Validate Lightning invoice
        if let amount = parsedInput.amount {
            return await validatePaymentAmount(
                amount: amount,
                paymentType: .lightning,
                direction: .send
            )
        }
        return .valid
        
    case .bitcoinAddress, .liquidAddress:
        // Validate address format
        return .valid
        
    case .lightningAddress, .lnurlPay:
        // Validate amount against LNURL limits
        if let amount = parsedInput.amount,
           let minAmount = parsedInput.minAmount,
           let maxAmount = parsedInput.maxAmount {
            
            if amount < minAmount {
                return .invalid("Amount too small. Minimum: \(minAmount) sats")
            }
            
            if amount > maxAmount {
                return .invalid("Amount too large. Maximum: \(maxAmount) sats")
            }
        }
        return .valid
        
    default:
        return .valid
    }
}
```

### Step 3: Enhance SendPaymentView with Better Input Handling
Update `Lumen/Views/SendPaymentView.swift`:

```swift
struct SendPaymentView: View {
    // ... existing properties ...
    @State private var parsedInput: ParsedPaymentInput?
    @State private var inputValidation: ValidationResult = .valid
    @State private var isParsingInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Enhanced Input Section
                EnhancedInputSection(
                    input: $input,
                    parsedInput: $parsedInput,
                    validation: $inputValidation,
                    isParsingInput: $isParsingInput,
                    onInputChanged: parseInput
                )
                
                // Parsed Input Display
                if let parsedInput = parsedInput {
                    ParsedInputDisplayView(parsedInput: parsedInput)
                }
                
                // Amount Input (if needed)
                if shouldShowAmountInput {
                    AmountInputSection(
                        amount: $amount,
                        parsedInput: parsedInput
                    )
                }
                
                // ... rest of existing content ...
            }
            .padding()
            .navigationTitle("Send Payment")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var shouldShowAmountInput: Bool {
        guard let parsedInput = parsedInput else { return false }
        
        switch parsedInput.type {
        case .lightningInvoice:
            return parsedInput.amount == nil // Amountless invoice
        case .bitcoinAddress, .liquidAddress:
            return true // Always need amount for addresses
        case .lightningAddress, .lnurlPay:
            return true // User chooses amount within limits
        case .bolt12Offer:
            return parsedInput.amount == nil // Flexible amount offer
        default:
            return false
        }
    }
    
    private func parseInput() {
        guard !input.isEmpty else {
            parsedInput = nil
            inputValidation = .valid
            return
        }
        
        isParsingInput = true
        
        Task {
            do {
                let parsed = try await walletManager.parsePaymentInput(input)
                let validation = await walletManager.validatePaymentInput(parsed)
                
                await MainActor.run {
                    parsedInput = parsed
                    inputValidation = validation
                    isParsingInput = false
                }
            } catch {
                await MainActor.run {
                    parsedInput = nil
                    inputValidation = .invalid(error.localizedDescription)
                    isParsingInput = false
                }
            }
        }
    }
}

struct EnhancedInputSection: View {
    @Binding var input: String
    @Binding var parsedInput: ParsedPaymentInput?
    @Binding var validation: ValidationResult
    @Binding var isParsingInput: Bool
    let onInputChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Destination")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    TextField("Invoice, address, or Lightning address", text: $input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: input) { _, _ in
                            onInputChanged()
                        }
                    
                    Button("Scan") {
                        // QR code scanning
                    }
                    .buttonStyle(.bordered)
                }
                
                // Parsing Status
                HStack {
                    if isParsingInput {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Parsing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if !input.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(validation.isValid ? .green : .orange)
                            
                            if validation.isValid, let parsedInput = parsedInput {
                                Text("Detected: \(parsedInput.type.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else if let errorMessage = validation.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct ParsedInputDisplayView: View {
    let parsedInput: ParsedPaymentInput
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: parsedInput.type.icon)
                    .foregroundColor(.blue)
                
                Text(parsedInput.type.displayName)
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                if let description = parsedInput.description {
                    InfoRow(label: "Description", value: description)
                }
                
                if let amount = parsedInput.amount {
                    InfoRow(label: "Amount", value: "\(amount) sats")
                }
                
                if let minAmount = parsedInput.minAmount,
                   let maxAmount = parsedInput.maxAmount {
                    InfoRow(label: "Amount Range", value: "\(minAmount) - \(maxAmount) sats")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AmountInputSection: View {
    @Binding var amount: String
    let parsedInput: ParsedPaymentInput?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount (sats)")
                .font(.headline)
            
            TextField("Enter amount", text: $amount)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            // Show limits if available
            if let parsedInput = parsedInput,
               let minAmount = parsedInput.minAmount,
               let maxAmount = parsedInput.maxAmount {
                Text("Range: \(minAmount) - \(maxAmount) sats")
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
func testLightningInvoiceParsing() async {
    let parser = PaymentInputParser.shared
    let invoice = "lnbc1000n1..."
    
    do {
        let parsed = try await parser.parseInput(invoice)
        XCTAssertEqual(parsed.type, .lightningInvoice)
        XCTAssertTrue(parsed.isValid)
    } catch {
        XCTFail("Invoice parsing failed: \(error)")
    }
}

func testLightningAddressParsing() async {
    let parser = PaymentInputParser.shared
    let address = "user@domain.com"
    
    do {
        let parsed = try await parser.parseInput(address)
        XCTAssertEqual(parsed.type, .lightningAddress)
        XCTAssertEqual(parsed.lightningAddress, address)
    } catch {
        XCTFail("Lightning address parsing failed: \(error)")
    }
}

func testBitcoinURIParsing() async {
    let parser = PaymentInputParser.shared
    let uri = "bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.001&label=Test"
    
    do {
        let parsed = try await parser.parseInput(uri)
        XCTAssertEqual(parsed.type, .bitcoinAddress)
        XCTAssertEqual(parsed.amount, 100000) // 0.001 BTC in sats
    } catch {
        XCTFail("Bitcoin URI parsing failed: \(error)")
    }
}
```

### Integration Tests
1. **Parse All Formats**: Test parsing of all supported input formats
2. **Validation Logic**: Verify validation works for each format
3. **UI Updates**: Test UI updates correctly based on parsed input
4. **Error Handling**: Test error handling for invalid inputs

### Manual Testing Checklist
- [ ] Lightning invoices parse correctly
- [ ] Bitcoin addresses are recognized
- [ ] Lightning addresses resolve properly
- [ ] LNURL links work correctly
- [ ] Bitcoin URIs with parameters parse
- [ ] Invalid inputs show appropriate errors
- [ ] UI updates in real-time as user types

## Common Issues and Solutions

### Issue: Lightning address resolution fails
**Cause**: Domain doesn't support Lightning addresses or network issues
**Solution**: Provide clear error messages and fallback options

### Issue: LNURL decoding fails
**Cause**: Invalid LNURL format or encoding issues
**Solution**: Implement robust bech32 decoding and validation

### Issue: Parsing is too slow
**Cause**: Network requests for each input change
**Solution**: Implement debouncing and caching for network requests

## Estimated Development Time
**2-3 days** for experienced iOS developer

### Breakdown:
- Day 1: PaymentInputParser implementation
- Day 2: Enhanced UI integration
- Day 3: Testing and edge case handling

## Success Criteria
- [ ] All major payment formats are recognized and parsed
- [ ] Real-time validation provides immediate feedback
- [ ] Error messages are clear and actionable
- [ ] UI adapts based on parsed input type
- [ ] Performance is smooth with no lag during typing
- [ ] Network requests are optimized and cached

## References
- [Breez SDK Parsing Inputs](https://sdk-doc-liquid.breez.technology/guide/parse.html)
- [Lightning Address Specification](https://github.com/andrerfneves/lightning-address/blob/master/README.md)
- [LNURL Specification](https://github.com/lnurl/luds)
- [BIP21 Bitcoin URI Scheme](https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki)
