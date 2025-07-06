import SwiftUI
import BreezSDKLiquid

struct ReceiveLiquidView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @State private var liquidAddress: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preparedReceive: PrepareReceiveResponse?
    @State private var showingAmountInput = false
    @State private var specifiedAmount: UInt64?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Receive Liquid Bitcoin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Get L-BTC sent to your Liquid address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if let liquidAddress = liquidAddress {
                    // Show generated address with QR code
                    VStack(spacing: 24) {
                        // QR Code
                        QRCodeView(data: liquidAddress, size: 250)
                            .padding(.horizontal)
                        
                        // Address display
                        VStack(spacing: 12) {
                            Text("Liquid Address")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(liquidAddress)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .onTapGesture {
                                    UIPasteboard.general.string = liquidAddress
                                }
                        }
                        .padding(.horizontal)
                        
                        // Copy Button
                        Button("Copy Address") {
                            UIPasteboard.general.string = liquidAddress
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Fee Information
                        if let preparedReceive = preparedReceive {
                            VStack(spacing: 12) {
                                if preparedReceive.feesSat > 0 {
                                    HStack {
                                        Text("Service fee")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        SatsAmountView.fee(preparedReceive.feesSat)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        
                                        Text("No service fees")
                                            .font(.body)
                                            .foregroundColor(.green)
                                        
                                        Spacer()
                                    }
                                }
                                
                                if let amount = specifiedAmount {
                                    HStack {
                                        Text("Expected amount")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        SatsAmountView(
                                            amount: amount,
                                            displayMode: .both,
                                            size: .regular,
                                            style: .success
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Address generation options
                    VStack(spacing: 16) {
                        // Generate address for any amount
                        LiquidAddressGenerationCard(
                            title: "Generate Address",
                            subtitle: "Create address for any amount",
                            icon: "drop.circle.fill",
                            iconColor: .blue,
                            action: {
                                generateAddress(amount: nil)
                            }
                        )
                        
                        // Generate address for specific amount
                        LiquidAddressGenerationCard(
                            title: "Generate with Amount",
                            subtitle: "Create address with specific amount",
                            icon: "number.circle.fill",
                            iconColor: .green,
                            action: {
                                showingAmountInput = true
                            }
                        )
                    }
                    .padding(.horizontal)
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
                
                // Loading indicator
                if isLoading {
                    ProgressView("Generating address...")
                        .padding()
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if liquidAddress != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("New Address") {
                            resetView()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAmountInput) {
            LiquidAmountInputView { amount in
                generateAddress(amount: amount)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateAddress(amount: UInt64?) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Prepare the liquid receive
                let prepared = try await walletManager.prepareReceiveLiquid(payerAmountSat: amount)
                
                // Execute the liquid receive to get the address
                let response = try await walletManager.receiveLiquid(
                    prepareResponse: prepared,
                    description: "Lumen liquid receive"
                )
                
                await MainActor.run {
                    preparedReceive = prepared
                    liquidAddress = response.destination
                    specifiedAmount = amount
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
    
    private func resetView() {
        liquidAddress = nil
        preparedReceive = nil
        specifiedAmount = nil
        errorMessage = nil
    }
}

// MARK: - Liquid Address Generation Card

struct LiquidAddressGenerationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(iconColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Liquid Amount Input View

struct LiquidAmountInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    let onAmountSelected: (UInt64) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Specify Amount")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    TextField("Amount in sats", text: $amountText)
                        .font(.title)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                    
                    Text("Enter the amount you expect to receive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Generate Address") {
                    if let amount = UInt64(amountText), amount > 0 {
                        onAmountSelected(amount)
                        dismiss()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(amountText.isEmpty || UInt64(amountText) == nil ? Color.gray : Color.blue)
                .cornerRadius(12)
                .disabled(amountText.isEmpty || UInt64(amountText) == nil)
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
        }
    }
}

// MARK: - Preview

#Preview {
    ReceiveLiquidView()
}
