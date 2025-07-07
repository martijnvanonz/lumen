import SwiftUI
import BreezSDKLiquid

struct ReceiveOnchainView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var walletManager = WalletManager.shared
    @State private var bitcoinAddress: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var preparedReceive: PrepareReceiveResponse?

    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Receive Bitcoin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Get Bitcoin sent to your onchain address")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                if let bitcoinAddress = bitcoinAddress {
                    // Show generated address with QR code
                    VStack(spacing: 24) {
                        // QR Code
                        QRCodeView(data: bitcoinAddress, size: 250)
                            .padding(.horizontal)

                        // Address display
                        VStack(spacing: 12) {
                            Text("Bitcoin Address")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text(bitcoinAddress)
                                .font(.system(.body, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .onTapGesture {
                                    UIPasteboard.general.string = bitcoinAddress
                                }
                        }
                        .padding(.horizontal)

                        // Copy Button
                        Button("Copy Address") {
                            UIPasteboard.general.string = bitcoinAddress
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
                        Button("Generate Bitcoin Address") {
                            generateAddress()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Text("Generate a Bitcoin address to receive payments from exchanges or other wallets")
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
                
                if bitcoinAddress != nil {
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
                // Prepare the onchain receive (no amount specified)
                let prepared = try await walletManager.prepareReceiveOnchain(payerAmountSat: nil)

                // Execute the onchain receive to get the address
                let response = try await walletManager.receiveOnchain(prepareResponse: prepared)

                await MainActor.run {
                    preparedReceive = prepared
                    // Extract plain address without bitcoin: prefix
                    let plainAddress = extractPlainAddress(from: response.destination)
                    bitcoinAddress = plainAddress
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
        // Remove bitcoin: prefix if present
        if destination.lowercased().hasPrefix("bitcoin:") {
            let startIndex = destination.index(destination.startIndex, offsetBy: 8)
            return String(destination[startIndex...])
        }
        return destination
    }

    private func resetView() {
        bitcoinAddress = nil
        preparedReceive = nil
        errorMessage = nil
    }
}

// MARK: - Preview

#Preview {
    ReceiveOnchainView()
}
