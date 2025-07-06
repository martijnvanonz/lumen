import SwiftUI
import BreezSDKLiquid

struct ReceiveLiquidView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @State private var liquidAddress: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preparedReceive: PrepareReceiveResponse?

    
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
                                

                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Generate address button
                    VStack(spacing: 16) {
                        Button("Generate Liquid Address") {
                            generateAddress()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Text("Generate a Liquid address to receive L-BTC from exchanges or other wallets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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
    }
    
    // MARK: - Helper Functions

    private func generateAddress() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Prepare the liquid receive (no amount specified)
                let prepared = try await walletManager.prepareReceiveLiquid(payerAmountSat: nil)

                // Execute the liquid receive to get the address
                let response = try await walletManager.receiveLiquid(
                    prepareResponse: prepared,
                    description: "Lumen liquid receive"
                )

                await MainActor.run {
                    preparedReceive = prepared
                    // Extract plain address without liquid: prefix
                    let plainAddress = extractPlainAddress(from: response.destination)
                    liquidAddress = plainAddress
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

    private func extractPlainAddress(from destination: String) -> String {
        // Remove liquid: prefix if present
        if destination.lowercased().hasPrefix("liquid:") {
            let startIndex = destination.index(destination.startIndex, offsetBy: 7)
            return String(destination[startIndex...])
        }
        return destination
    }

    private func resetView() {
        liquidAddress = nil
        preparedReceive = nil
        errorMessage = nil
    }
}

// MARK: - Preview

#Preview {
    ReceiveLiquidView()
}
