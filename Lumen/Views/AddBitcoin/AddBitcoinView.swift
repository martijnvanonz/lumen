import SwiftUI

struct AddBitcoinView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingReceiveOnchain = false
    @State private var showingReceiveLiquid = false
    @State private var showingBuyBitcoin = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add Bitcoin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Transfer from your exchange or buy instantly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Options
                VStack(spacing: 16) {
                    // Receive Bitcoin (Onchain)
                    AddBitcoinOptionCard(
                        title: "Receive Bitcoin",
                        subtitle: "From exchange or wallet (onchain)",
                        icon: "bitcoinsign.circle.fill",
                        iconColor: .orange,
                        action: {
                            showingReceiveOnchain = true
                        }
                    )
                    
                    // Receive Liquid Bitcoin
                    AddBitcoinOptionCard(
                        title: "Receive Liquid Bitcoin",
                        subtitle: "From exchange or wallet (liquid)",
                        icon: "drop.circle.fill",
                        iconColor: .blue,
                        action: {
                            showingReceiveLiquid = true
                        }
                    )
                    
                    // Buy Bitcoin
                    AddBitcoinOptionCard(
                        title: "Buy Bitcoin",
                        subtitle: "Purchase directly with fiat via Moonpay",
                        icon: "creditcard.circle.fill",
                        iconColor: .green,
                        action: {
                            showingBuyBitcoin = true
                        }
                    )
                }
                .padding(.horizontal)
                
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
            }
        }
        .sheet(isPresented: $showingReceiveOnchain) {
            ReceiveOnchainView()
        }
        .sheet(isPresented: $showingReceiveLiquid) {
            ReceiveLiquidView()
        }
        .sheet(isPresented: $showingBuyBitcoin) {
            BuyBitcoinView()
        }
    }
}

// MARK: - Add Bitcoin Option Card

struct AddBitcoinOptionCard: View {
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
                    .font(.title)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                
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
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(iconColor.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    AddBitcoinView()
}
