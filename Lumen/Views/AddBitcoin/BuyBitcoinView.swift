import SwiftUI
import BreezSDKLiquid

struct BuyBitcoinView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var onchainLimits: OnchainPaymentLimitsResponse?
    @State private var selectedAmountSats: UInt64 = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preparedBuy: PrepareBuyBitcoinResponse?
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Buy Bitcoin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Purchase Bitcoin directly with fiat via Moonpay")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if let limits = onchainLimits {
                    // Amount selection
                    VStack(spacing: 20) {
                        // Limits info
                        VStack(spacing: 12) {
                            Text("Purchase Limits")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Minimum")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    SatsAmountView(
                                        amount: limits.receive.minSat,
                                        displayMode: .both,
                                        size: .compact,
                                        style: .primary
                                    )
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Maximum")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    SatsAmountView(
                                        amount: limits.receive.maxSat,
                                        displayMode: .both,
                                        size: .compact,
                                        style: .primary
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Amount input
                        VStack(spacing: 16) {
                            Text("Amount to Purchase")
                                .font(.headline)
                            
                            VStack(spacing: 12) {
                                // Sats input
                                HStack {
                                    Image(systemName: "bitcoinsign.circle")
                                        .foregroundColor(.orange)
                                    
                                    TextField("Amount in sats", value: $selectedAmountSats, format: .number)
                                        .font(.title2)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .onChange(of: selectedAmountSats) { _, newValue in
                                            // Clamp to limits
                                            selectedAmountSats = max(limits.receive.minSat, min(limits.receive.maxSat, newValue))
                                        }
                                }
                                
                                // Currency equivalent
                                if selectedAmountSats > 0 {
                                    HStack {
                                        Text("≈")
                                            .foregroundColor(.secondary)
                                        
                                        if let rate = currencyManager.getCurrentRate() {
                                            let btcAmount = Double(selectedAmountSats) / 100_000_000.0
                                            let fiatAmount = btcAmount * rate
                                            Text(currencyManager.formatFiatAmount(fiatAmount))
                                                .font(.title3)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Rate unavailable")
                                                .font(.title3)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick amount buttons
                        VStack(spacing: 12) {
                            Text("Quick Select")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                QuickAmountButton(
                                    amount: limits.receive.minSat,
                                    label: "Minimum",
                                    isSelected: selectedAmountSats == limits.receive.minSat
                                ) {
                                    selectedAmountSats = limits.receive.minSat
                                }
                                
                                QuickAmountButton(
                                    amount: limits.receive.minSat * 5,
                                    label: "5x Min",
                                    isSelected: selectedAmountSats == limits.receive.minSat * 5
                                ) {
                                    selectedAmountSats = min(limits.receive.maxSat, limits.receive.minSat * 5)
                                }
                                
                                QuickAmountButton(
                                    amount: limits.receive.minSat * 10,
                                    label: "10x Min",
                                    isSelected: selectedAmountSats == limits.receive.minSat * 10
                                ) {
                                    selectedAmountSats = min(limits.receive.maxSat, limits.receive.minSat * 10)
                                }
                                
                                QuickAmountButton(
                                    amount: limits.receive.maxSat,
                                    label: "Maximum",
                                    isSelected: selectedAmountSats == limits.receive.maxSat
                                ) {
                                    selectedAmountSats = limits.receive.maxSat
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Fee information
                    if let preparedBuy = preparedBuy {
                        VStack(spacing: 12) {
                            Text("Purchase Summary")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Bitcoin amount")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    SatsAmountView(
                                        amount: selectedAmountSats,
                                        displayMode: .both,
                                        size: .compact,
                                        style: .primary
                                    )
                                }
                                
                                HStack {
                                    Text("Service fee")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    SatsAmountView.fee(preparedBuy.feesSat)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total cost")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    SatsAmountView(
                                        amount: selectedAmountSats + preparedBuy.feesSat,
                                        displayMode: .both,
                                        size: .regular,
                                        style: .primary
                                    )
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Loading limits
                    VStack(spacing: 16) {
                        ProgressView("Loading purchase limits...")
                        Text("Fetching current limits from Moonpay")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action buttons
                if onchainLimits != nil {
                    VStack(spacing: 12) {
                        if preparedBuy == nil {
                            Button("Check Fees") {
                                preparePurchase()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedAmountSats > 0 ? Color.blue : Color.gray)
                            .cornerRadius(12)
                            .disabled(selectedAmountSats == 0 || isLoading)
                        } else {
                            Button("Buy Bitcoin") {
                                showingConfirmation = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                            .disabled(isLoading)
                        }
                        
                        if isLoading {
                            ProgressView("Processing...")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadOnchainLimits()
        }
        .alert("Confirm Purchase", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Buy Bitcoin", role: .destructive) {
                executePurchase()
            }
        } message: {
            if let preparedBuy = preparedBuy {
                Text("You will be redirected to Moonpay to complete the purchase of \(selectedAmountSats) sats for approximately \(currencyManager.formatFiatAmount(Double(selectedAmountSats + preparedBuy.feesSat) / 100_000_000.0 * (currencyManager.getCurrentRate() ?? 0))).")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadOnchainLimits() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let limits = try await walletManager.fetchOnchainLimits()
                await MainActor.run {
                    onchainLimits = limits
                    selectedAmountSats = limits.receive.minSat
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
    
    private func preparePurchase() {
        guard selectedAmountSats > 0 else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let prepared = try await walletManager.prepareBuyBitcoin(
                    provider: .moonpay,
                    amountSat: selectedAmountSats
                )
                
                await MainActor.run {
                    preparedBuy = prepared
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
    
    private func executePurchase() {
        guard let preparedBuy = preparedBuy else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let url = try await walletManager.buyBitcoin(prepareResponse: preparedBuy)
                
                await MainActor.run {
                    // Open the Moonpay URL in Safari
                    if let moonpayURL = URL(string: url) {
                        UIApplication.shared.open(moonpayURL)
                    }
                    
                    // Dismiss this view
                    dismiss()
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

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    let amount: UInt64
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(amount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("sats")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    BuyBitcoinView()
}
